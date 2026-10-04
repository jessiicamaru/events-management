import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';

/// Behaves like the real server: returns only the events inside the requested range,
/// and records every range it was asked for.
class RangeFilteringApi implements ApiService {
  RangeFilteringApi(this.stored);

  final List<EventModel> stored;
  final List<({DateTime? start, DateTime? end})> requests = [];

  @override
  Future<List<EventModel>> fetchEvents({DateTime? startTime, DateTime? endTime}) async {
    requests.add((start: startTime, end: endTime));

    return stored.where((e) {
      if (startTime != null && e.startTime.isBefore(startTime)) return false;
      if (endTime != null && !e.startTime.isBefore(endTime)) return false;
      return true;
    }).toList();
  }

  @override
  Future<void> syncGoogleCalendar() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime.now();

  final tomorrow = EventModel(
    id: 'tomorrow',
    title: 'Tomorrow',
    startTime: now.add(const Duration(days: 1)),
    endTime: now.add(const Duration(days: 1, hours: 1)),
    habitId: '',
  );

  late RangeFilteringApi api;
  late ProviderContainer container;

  setUp(() {
    api = RangeFilteringApi([tomorrow]);
    container = ProviderContainer(
      overrides: [apiServiceProvider.overrideWithValue(api)],
    );

    // The app keeps these alive from the root (reminderSyncProvider and
    // homeWidgetSyncProvider watch eventsProvider), so the test does too.
    container.listen(eventsProvider, (_, _) {}, fireImmediately: true);
    container.listen(calendarViewRangeProvider, (_, _) {}, fireImmediately: true);
  });

  tearDown(() => container.dispose());

  Future<List<EventModel>> browseCalendarTo(DateTime start, DateTime end) {
    container.read(calendarViewRangeProvider.notifier).updateRange(start, end);
    return container.read(eventsProvider.future);
  }

  test('a cold start asks for a bounded window, not every event ever', () async {
    await container.read(eventsProvider.future);

    final first = api.requests.first;
    expect(first.start, isNotNull, reason: 'unbounded fetch on cold start');
    expect(first.end, isNotNull, reason: 'unbounded fetch on cold start');
    expect(first.start!.isBefore(now), isTrue);
    expect(first.end!.isAfter(now.add(AppConstants.reminderHorizon)), isTrue);
  });

  test('browsing the calendar to a far month keeps the coming week loaded', () async {
    // Reminders, the Android widgets and the home screen all read eventsProvider.
    // If its data became "December only", reminders would re-plan from December,
    // find nothing in the next seven days, and cancel every pending reminder.
    final farStart = DateTime(now.year + 1, 12, 1);
    final events = await browseCalendarTo(farStart, DateTime(now.year + 1, 12, 31));

    expect(events.map((e) => e.id), contains('tomorrow'));

    final last = api.requests.last;
    expect(
      last.end!.isAfter(DateTime(now.year + 1, 12, 30)),
      isTrue,
      reason: 'the month being browsed is still fetched',
    );
  });

  test('browsing the calendar to a past month keeps the coming week loaded', () async {
    final events = await browseCalendarTo(
      DateTime(now.year - 1, 3, 1),
      DateTime(now.year - 1, 3, 31),
    );

    expect(events.map((e) => e.id), contains('tomorrow'));
  });

  group('eventsFetchRange', () {
    test('is the coming-week window when the calendar has not asked for one', () {
      final range = eventsFetchRange(null, now);

      expect(range.startTime, now.subtract(AppConstants.upcomingWindowBehind));
      expect(range.endTime, now.add(AppConstants.upcomingWindowAhead));
    });

    test('covers both the browsed range and the coming week', () {
      final browsed = CalendarViewRange(
        now.add(const Duration(days: 60)),
        now.add(const Duration(days: 90)),
      );

      final range = eventsFetchRange(browsed, now);

      expect(range.startTime, now.subtract(AppConstants.upcomingWindowBehind));
      expect(range.endTime, browsed.endTime);
    });

    test('is just the browsed range when it already covers the coming week', () {
      final browsed = CalendarViewRange(
        now.subtract(const Duration(days: 7)),
        now.add(const Duration(days: 21)),
      );

      final range = eventsFetchRange(browsed, now);

      expect(range.startTime, browsed.startTime);
      expect(range.endTime, browsed.endTime);
    });

    test('the window reaches at least as far as reminders are planned', () {
      // Otherwise the reminder planner would be missing events at the far edge
      // of its own horizon.
      expect(
        AppConstants.upcomingWindowAhead >= AppConstants.reminderHorizon,
        isTrue,
      );
    });
  });
}
