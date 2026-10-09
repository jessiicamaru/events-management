import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../test_utils.dart';
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
      overrides: [...signedInOverrides, apiServiceProvider.overrideWithValue(api)],
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

  /// Wired as the app wires it: the calendar screen only *reads* the range notifier,
  /// so eventsProvider is the range's one listener. The tests above also listen to the
  /// range directly, which kept it alive and hid what follows.
  group('the browsed range survives eventsProvider rebuilding', () {
    late RangeFilteringApi appApi;
    late ProviderContainer app;

    setUp(() {
      appApi = RangeFilteringApi([tomorrow]);
      app = ProviderContainer(
        overrides: [...signedInOverrides, apiServiceProvider.overrideWithValue(appApi)],
      );
      app.listen(eventsProvider, (_, _) {}, fireImmediately: true);
    });

    tearDown(() => app.dispose());

    final browsedStart = now.subtract(const Duration(days: 14));
    final browsedEnd = now.add(const Duration(days: 21));

    test('a range set by the calendar is the range that gets fetched', () async {
      await app.read(eventsProvider.future);

      app.read(calendarViewRangeProvider.notifier).updateRange(browsedStart, browsedEnd);
      await app.read(eventsProvider.future);

      expect(appApi.requests.last.start, browsedStart);
      expect(appApi.requests.last.end, browsedEnd);
      expect(app.read(calendarViewRangeProvider), CalendarViewRange(browsedStart, browsedEnd));
    });

  });

  // Under a real ProviderScope and real frames: a plain ProviderContainer disposes an
  // unlistened provider later than Flutter does, and did not reproduce this.
  testWidgets('a calendar reporting its range after every frame settles instead of fetching for ever',
      (tester) async {
    // The calendar reports its visible range after every frame that changes its data,
    // including the frame that shows the events just fetched. The range used to be
    // disposed while eventsProvider rebuilt, so each report looked like a change and
    // fetched again — on the emulator, a GET /events every ~300 ms on the calendar tab,
    // each for the default window. Measured here before the fix: 31 fetches in 3 s.
    final api = RangeFilteringApi([tomorrow]);
    await tester.pumpWidget(ProviderScope(
      overrides: [...signedInOverrides, apiServiceProvider.overrideWithValue(api)],
      child: const _ReportsItsRangeEveryFrame(),
    ));

    Future<void> frames(int count) async {
      for (var i = 0; i < count; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await frames(30);
    final settled = api.requests.length;
    await frames(30);

    expect(api.requests, hasLength(settled), reason: 'still fetching after 3 s of unchanged range');
    expect(settled, lessThanOrEqualTo(3), reason: 'cold start, the browsed range, one background-sync refresh');
    expect(
      api.requests.skip(1).map((r) => (r.start, r.end)),
      everyElement((_ReportsItsRangeEveryFrame.start, _ReportsItsRangeEveryFrame.end)),
      reason: 'the browsed range was lost between fetches',
    );
  });
}

/// Stands in for CalendarScreen: watches eventsProvider and, after every frame, reports
/// the same visible range — as SfCalendar's onViewChanged → updateRange does. Only
/// *reads* the range notifier, like the screen, so eventsProvider is the range's only
/// listener.
class _ReportsItsRangeEveryFrame extends ConsumerStatefulWidget {
  const _ReportsItsRangeEveryFrame();

  static final start = DateTime.now().subtract(const Duration(days: 14));
  static final end = DateTime.now().add(const Duration(days: 21));

  @override
  ConsumerState<_ReportsItsRangeEveryFrame> createState() => _ReportsItsRangeEveryFrameState();
}

class _ReportsItsRangeEveryFrameState extends ConsumerState<_ReportsItsRangeEveryFrame> {
  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(calendarViewRangeProvider.notifier)
            .updateRange(_ReportsItsRangeEveryFrame.start, _ReportsItsRangeEveryFrame.end);
      }
    });
    return Text('${events.value?.length}', textDirection: TextDirection.ltr);
  }
}
