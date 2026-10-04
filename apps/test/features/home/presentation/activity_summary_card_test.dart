import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/home/domain/models/activity_summary.dart';
import 'package:habit_tracker/features/home/presentation/providers/activity_summary_provider.dart';
import 'package:habit_tracker/features/home/presentation/widgets/activity_summary_card.dart';
import '../../../test_utils.dart';
import '../activity_summary_fixture.dart';

void main() {
  Widget buildCard(Future<ActivitySummary> Function() load) {
    return ProviderScope(
      overrides: [
        ...commonTestOverrides,
        activitySummaryProvider.overrideWith((ref) => load()),
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
              'scheduled': 0,
              'completed': 0,
              'focusMinutes': 25,
            },
          ],
          'totalScheduled': 0,
          'totalCompleted': 0,
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
          'totalScheduled': 0,
          'totalCompleted': 0,
          'totalFocusMinutes': 0,
          'bestFocusMinutes': 0,
        }),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Nothing here yet'), findsOneWidget);
    expect(bars(), findsNothing);
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
