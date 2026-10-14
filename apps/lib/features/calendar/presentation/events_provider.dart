import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';
import 'package:habit_tracker/features/calendar/domain/event_occurrence.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/habits/presentation/habits_provider.dart';
import 'package:habit_tracker/features/habits/presentation/providers/heatmap_provider.dart';
import 'package:habit_tracker/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:habit_tracker/features/squads/presentation/providers/squad_provider.dart';
import 'package:habit_tracker/core/network/signalr_provider.dart';
import 'package:habit_tracker/features/auth/presentation/providers/auth_provider.dart';

part 'events_provider.g.dart';

class CalendarViewRange {
  final DateTime startTime;
  final DateTime endTime;

  CalendarViewRange(this.startTime, this.endTime);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarViewRange &&
          runtimeType == other.runtimeType &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode => startTime.hashCode ^ endTime.hashCode;
}

/// The range to actually fetch: whatever the calendar is showing, widened to always
/// include the window around [now].
///
/// `eventsProvider` is read for two different reasons. The calendar reads it for
/// the range being browsed; the reminder scheduler, the Android widgets and the
/// home screen read it for what is happening *now*. Fetching only the browsed range
/// served the first and broke the others — see [AppConstants.upcomingWindowAhead].
///
/// Widening costs one larger request when the calendar is far from today, and
/// nothing when it is not: the calendar's usual three-week window already covers
/// the coming week.
CalendarViewRange eventsFetchRange(CalendarViewRange? browsed, DateTime now) {
  final upcomingStart = now.subtract(AppConstants.upcomingWindowBehind);
  final upcomingEnd = now.add(AppConstants.upcomingWindowAhead);

  if (browsed == null) return CalendarViewRange(upcomingStart, upcomingEnd);

  return CalendarViewRange(
    browsed.startTime.isBefore(upcomingStart) ? browsed.startTime : upcomingStart,
    browsed.endTime.isAfter(upcomingEnd) ? browsed.endTime : upcomingEnd,
  );
}

@riverpod
class CalendarViewRangeNotifier extends _$CalendarViewRangeNotifier {
  @override
  CalendarViewRange? build() => null;

  void updateRange(DateTime start, DateTime end) {
    final nextState = CalendarViewRange(start, end);
    if (state != nextState) {
      state = nextState;
    }
  }
}

@Riverpod(keepAlive: true)
class GoogleCalendarSyncTracker extends _$GoogleCalendarSyncTracker {
  @override
  DateTime? build() => null;

  void updateLastSync() {
    state = DateTime.now();
  }
}

@riverpod
class EventsNotifier extends _$EventsNotifier {
  @override
  Future<List<EventModel>> build() async {
    // Every watch comes before the first await. A rebuild drops this provider's old
    // subscriptions and makes them again as it runs, so anything watched only *after*
    // an await has no listener during it. calendarViewRangeProvider is auto-disposed:
    // watched after the auth await, it was disposed in that gap and came back null,
    // so the calendar's next report of its visible range looked like a change, which
    // rebuilt this, which disposed the range again — a GET /events every few hundred
    // milliseconds on the calendar tab, each for the default window.
    final range = ref.watch(calendarViewRangeProvider);
    final connectionAsync = ref.watch(signalrConnectionProvider);
    final tokenFuture = ref.watch(authProvider.future);

    // Nothing to fetch while signed out, and this provider is alive from app start:
    // main.dart watches reminderSyncProvider and homeWidgetSyncProvider, which watch
    // this. See HabitsNotifier.build for what the tokenless fetch used to cost.
    final token = await tokenFuture;
    if (token == null) return const [];

    final apiService = ref.read(apiServiceProvider);

    // Lắng nghe sự kiện đồng bộ thời gian thực từ SignalR
    final connection = connectionAsync.value;
    if (connection != null) {
      connection.off("CalendarUpdated");
      connection.on("CalendarUpdated", (arguments) {
        debugPrint("SignalR: Received CalendarUpdated event, invalidating EventsNotifier...");
        ref.invalidateSelf();
      });
      
      ref.onDispose(() {
        connection.off("CalendarUpdated");
      });
    }
    
    // Kích hoạt đồng bộ nền an toàn sau khi màn hình được render xong
    Future.microtask(() => _triggerBackgroundSync());

    // Never unbounded, and never without the coming week: see eventsFetchRange.
    final fetch = eventsFetchRange(range, DateTime.now());
    return await apiService.fetchEvents(startTime: fetch.startTime, endTime: fetch.endTime);
  }

  Future<void> _triggerBackgroundSync() async {
    // Scheduled from build() and run a microtask later, by which time this build may
    // already have been replaced — a rebuild, or the provider disposed. Touching ref
    // then throws "Cannot use the Ref of eventsProvider after it has been disposed",
    // out of a background sync nobody is waiting for.
    if (!ref.mounted) return;

    final lastSync = ref.read(googleCalendarSyncTrackerProvider);
    final now = DateTime.now();
    
    // Nếu vừa đồng bộ trong vòng 1 phút, không đồng bộ lại để tránh loop vô hạn
    if (lastSync != null && now.difference(lastSync).inMinutes < 1) {
      return;
    }

    // Đánh dấu thời điểm đồng bộ lập tức để chặn các luồng gọi đồng thời
    ref.read(googleCalendarSyncTrackerProvider.notifier).updateLastSync();

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.syncGoogleCalendar();

      // The request outlives the build just as easily as the microtask above did.
      if (!ref.mounted) return;

      // Sau khi backend đồng bộ xong và cập nhật DB, invalidate để kéo dữ liệu mới
      ref.invalidateSelf();
    } catch (e) {
      // Bỏ qua lỗi đồng bộ nền để không crash giao diện chính
    }
  }

  /// Requests in flight, keyed by series and day, so two quick taps on the same day
  /// share one request instead of racing to create the day twice.
  final Map<String, Future<String>> _splittingOff = {};

  /// The id of the event that holds [day]'s own tasks and completion.
  ///
  /// For an ordinary event, or a day already split off, that is just its id. For a day
  /// of a repeating series — which carries the *series'* id — the server first gives the
  /// day its own event, with a fresh copy of the series' tasks, and this returns that
  /// event's id. Then the events are reloaded, so every screen shows the new day in
  /// place of the series' day.
  Future<String> materializeOccurrence(EventModel day) {
    if (!day.isSeriesOccurrence) return Future.value(day.id);

    final key = '${day.id}@${day.startTime.toUtc().toIso8601String()}';
    return _splittingOff[key] ??= _splitOff(day, key);
  }

  Future<String> _splitOff(EventModel day, String key) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final dayId = await apiService.materializeOccurrence(day.id, day.startTime);
      ref.invalidateSelf();
      return dayId;
    } finally {
      _splittingOff.remove(key);
    }
  }

  Future<void> addEvent(EventModel event) async {
    final apiService = ref.read(apiServiceProvider);
    
    final previousState = state;
    if (state.hasValue) {
      state = AsyncData([...state.value!, event]);
    }

    try {
      await apiService.syncEvent(event);
      ref.invalidateSelf();
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> toggleEvent(String id, bool isCompleted) async {
    final apiService = ref.read(apiServiceProvider);
    
    // Optimistic update
    final previousState = state;
    if (state.hasValue) {
      final updatedEvents = state.value!.map((e) {
        if (e.id == id) {
          return e.copyWith(isCompleted: isCompleted);
        }
        return e;
      }).toList();
      state = AsyncData(updatedEvents);
    }

    try {
      await apiService.toggleEvent(id, isCompleted);
      ref.invalidate(habitsProvider);
      ref.invalidate(heatmapProvider);
      ref.invalidate(userProfileProvider);
      ref.invalidate(activeSquadProvider);
      ref.invalidate(squadsListProvider);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> deleteEvent(String id, {String? deleteScope, DateTime? originalOccurrenceDate}) async {
    final apiService = ref.read(apiServiceProvider);
    
    final previousState = state;
    if (state.hasValue && (deleteScope == null || deleteScope == 'AllOccurrences')) {
      final updatedEvents = state.value!.where((e) => e.id != id).toList();
      state = AsyncData(updatedEvents);
    }

    try {
      await apiService.deleteEvent(id, deleteScope: deleteScope, originalOccurrenceDate: originalOccurrenceDate);
      ref.invalidateSelf();
      ref.invalidate(habitsProvider);
      ref.invalidate(heatmapProvider);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> updateEvent(EventModel event, {String? editScope, DateTime? originalOccurrenceDate}) async {
    final apiService = ref.read(apiServiceProvider);
    
    final previousState = state;

    try {
      await apiService.updateEvent(event.id, {
        'title': event.title,
        'startTime': event.startTime.toUtc().toIso8601String(),
        'endTime': event.endTime.toUtc().toIso8601String(),
        'habitId': event.habitId,
        'categoryId': event.categoryId,
        'targetDuration': const TimeSpanConverter().toJson(event.targetDuration),
        'editScope': ?editScope,
        'originalOccurrenceDate': ?originalOccurrenceDate?.toUtc().toIso8601String(),
        'recurrenceRule': ?event.recurrenceRule,
        // Always sent, including when empty: the server reads an ABSENT field as
        // "not supplied, keep what is stored", so omitting it silently discarded the
        // user's reminder change. Sending the list - empty or not - makes the edit
        // sheet's selection authoritative, which is what the user expects.
        'reminderMinutesBefore': event.reminderMinutesBefore,
      });
      ref.invalidateSelf();
      ref.invalidate(habitsProvider);
      ref.invalidate(heatmapProvider);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }
}
