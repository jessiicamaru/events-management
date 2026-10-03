import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/habits/presentation/habits_provider.dart';
import 'package:habit_tracker/features/habits/presentation/providers/heatmap_provider.dart';
import 'package:habit_tracker/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:habit_tracker/features/squads/presentation/providers/squad_provider.dart';
import 'package:habit_tracker/core/network/signalr_provider.dart';

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
    final range = ref.watch(calendarViewRangeProvider);
    final apiService = ref.read(apiServiceProvider);
    
    // Lắng nghe sự kiện đồng bộ thời gian thực từ SignalR
    final connectionAsync = ref.watch(signalrConnectionProvider);
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

    if (range != null) {
      return await apiService.fetchEvents(startTime: range.startTime, endTime: range.endTime);
    }
    return await apiService.fetchEvents();
  }

  Future<void> _triggerBackgroundSync() async {
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
      
      // Sau khi backend đồng bộ xong và cập nhật DB, invalidate để kéo dữ liệu mới
      ref.invalidateSelf();
    } catch (e) {
      // Bỏ qua lỗi đồng bộ nền để không crash giao diện chính
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
