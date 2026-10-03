import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';
import 'package:habit_tracker/features/home/domain/models/activity_summary.dart';
import 'package:habit_tracker/features/home/presentation/providers/activity_summary_provider.dart';
import 'package:habit_tracker/features/home/presentation/widgets/activity_summary_card.dart';
import '../../../test_utils.dart';
import '../activity_summary_fixture.dart';

void main() {
  Widget buildCard(
    Future<ActivitySummary> Function() load, {
    List<EventModel> events = const [],
  }) {
    return ProviderScope(
      overrides: [
        ...commonTestOverrides,
        activitySummaryProvider.overrideWith((ref) => load()),
        eventsProvider.overrideWith(() => _FakeEvents(events)),
      ],
      child: const ShadApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ActivitySummaryCard()),
        ),
      ),
    );
  }

  Finder bars() =>
      find.byWidgetPredicate((w) => w.runtimeType.toString() == '_Bar');

  testWidgets('shows the totals as tiles', (tester) async {
    await tester.pumpWidget(
      buildCard(() async => ActivitySummary.fromJson(serverResponse())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Last 14 days'), findsOneWidget);
    expect(find.text('3 of 4'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('1h 35m'), findsOneWidget, reason: 'total focus time');
    expect(find.text('1h 15m'), findsOneWidget, reason: 'best single day');
  });

  testWidgets('draws one bar per day', (tester) async {
    await tester.pumpWidget(
      buildCard(() async => ActivitySummary.fromJson(serverResponse())),
    );
    await tester.pumpAndSettle();

    expect(bars(), findsNWidgets(3));
  });

  testWidgets('starts on today, and tapping a bar shows that day', (tester) async {
    await tester.pumpWidget(
      buildCard(() async => ActivitySummary.fromJson(serverResponse())),
    );
    await tester.pumpAndSettle();

    // Today (the last day) is selected first, so the readout is never blank.
    expect(find.textContaining('Thu 10 Sep'), findsOneWidget);
    expect(find.textContaining('20 min focus · 1 of 1 done'), findsOneWidget);

    await tester.tap(bars().at(1));
    await tester.pumpAndSettle();

    expect(find.textContaining('Wed 9 Sep'), findsOneWidget);
    expect(find.textContaining('1h 15m focus · 2 of 3 done'), findsOneWidget);
    expect(find.textContaining('Thu 10 Sep'), findsNothing);
  });

  testWidgets('can select a day with no focus time', (tester) async {
    // Its bar is only a 2px sliver, but the whole column is the tap target.
    await tester.pumpWidget(
      buildCard(() async => ActivitySummary.fromJson(serverResponse())),
    );
    await tester.pumpAndSettle();

    await tester.tap(bars().first);
    await tester.pumpAndSettle();

    expect(find.textContaining('0 min focus · 0 of 0 done'), findsOneWidget);
  });

  testWidgets('says "none booked" instead of 0% when nothing was scheduled', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildCard(
        () async => ActivitySummary.fromJson({
          'days': [
            {
              'date': '2026-09-10T00:00:00Z',
              'oneOffScheduled': 0,
              'oneOffCompleted': 0,
              'focusMinutes': 25,
            },
          ],
          'totalOneOffScheduled': 0,
          'totalOneOffCompleted': 0,
          'totalFocusMinutes': 25,
          'bestFocusMinutes': 25,
        }),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('None booked'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('shows an empty state for a new user', (tester) async {
    await tester.pumpWidget(
      buildCard(
        () async => ActivitySummary.fromJson({
          'days': <dynamic>[],
          'totalOneOffScheduled': 0,
          'totalOneOffCompleted': 0,
          'totalFocusMinutes': 0,
          'bestFocusMinutes': 0,
        }),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Nothing here yet'), findsOneWidget);
    expect(bars(), findsNothing);
  });

  testWidgets('counts the days of a repeating event, not just one-off events', (
    tester,
  ) async {
    // Review round 1, finding 4: the server counts stored rows, so a daily event counted
    // once on its first day and otherwise only on days somebody had split off.
    final serverSaysNothingBooked = ActivitySummary.fromJson({
      'days': [
        for (final d in ['2026-09-08', '2026-09-09', '2026-09-10'])
          {'date': '${d}T00:00:00Z', 'oneOffScheduled': 0, 'oneOffCompleted': 0, 'focusMinutes': 0},
      ],
      'totalFocusMinutes': 0,
      'bestFocusMinutes': 0,
    });
    final dailySeries = EventModel(
      id: 'jog',
      title: 'Jogging',
      startTime: DateTime(2026, 9, 1, 7).toUtc(),
      endTime: DateTime(2026, 9, 1, 8).toUtc(),
      habitId: '',
      recurrenceRule: 'RRULE:FREQ=DAILY',
    );
    final doneOnThe9th = EventModel(
      id: 'jog-9',
      title: 'Jogging',
      startTime: DateTime(2026, 9, 9, 7).toUtc(),
      endTime: DateTime(2026, 9, 9, 8).toUtc(),
      habitId: '',
      parentEventId: 'jog',
      exceptionDate: DateTime(2026, 9, 9, 7).toUtc(),
      isCompleted: true,
    );

    await tester.pumpWidget(
      buildCard(
        () async => serverSaysNothingBooked,
        events: [dailySeries, doneOnThe9th],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 of 3'), findsOneWidget, reason: 'three days booked, one done');
    expect(find.text('33%'), findsOneWidget);
  });

  testWidgets('offers a retry when loading fails, and retrying refetches', (
    tester,
  ) async {
    var calls = 0;

    await tester.pumpWidget(
      buildCard(() async {
        calls++;
        throw Exception('offline');
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load your activity.'), findsOneWidget);
    // Exactly one: pumpAndSettle fast-forwards through Riverpod's automatic retry
    // backoff, which made this 11 before the provider opted out of it.
    expect(calls, 1);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(calls, 2);
  });
}

class _FakeEvents extends EventsNotifier {
  _FakeEvents(this.events);

  final List<EventModel> events;

  @override
  Future<List<EventModel>> build() async => events;
}
