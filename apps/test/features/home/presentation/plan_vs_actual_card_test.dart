import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/home/domain/models/plan_vs_actual.dart';
import 'package:habit_tracker/features/home/presentation/providers/plan_vs_actual_provider.dart';
import 'package:habit_tracker/features/home/presentation/widgets/plan_vs_actual_card.dart';
import '../../../test_utils.dart';
import '../plan_vs_actual_fixture.dart';

void main() {
  Widget buildCard(Future<PlanVsActual> Function() load) => ProviderScope(
        overrides: [
          ...commonTestOverrides,
          planVsActualProvider.overrideWith((ref) => load()),
        ],
        child: const ShadApp(
          home: Scaffold(body: SingleChildScrollView(child: PlanVsActualCard())),
        ),
      );

  testWidgets('states the totals, then each habit with its own comparison', (tester) async {
    await tester.pumpWidget(buildCard(() async => PlanVsActual.fromJson(planVsActualResponse())));
    await tester.pumpAndSettle();

    expect(find.text('Planned vs actual'), findsOneWidget);
    expect(find.text('Finished sessions, last 14 days'), findsOneWidget);
    expect(
      find.text('You booked 2h 30m and spent 1h 59m across 4 sessions.'),
      findsOneWidget,
    );

    // Per habit: the pair, and what it means.
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('1h 5m of 1h'), findsOneWidget);
    expect(find.text('5 min over, across 1 sessions'), findsOneWidget);

    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('54 min of 1h 30m'), findsOneWidget);
    expect(find.text('36 min under, across 3 sessions'), findsOneWidget);
  });

  testWidgets('says so when nothing has been finished yet', (tester) async {
    await tester.pumpWidget(buildCard(() async => PlanVsActual.fromJson({})));
    await tester.pumpAndSettle();

    expect(
      find.text('Finish a focus session and the comparison shows up here.'),
      findsOneWidget,
    );
    expect(find.text('Running'), findsNothing);
  });

  testWidgets('offers a retry when the request fails, and does not retry on its own',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(buildCard(() async {
      calls++;
      throw Exception('boom');
    }));
    await tester.pumpAndSettle();

    expect(find.text('Could not load the comparison.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    // Riverpod 3 retries a failed provider ten times unless told not to.
    expect(calls, 1, reason: 'one call per failure, not eleven');
  });

  testWidgets('the category view is behind a tap', (tester) async {
    final twoCategories = {
      ...planVsActualResponse(),
      'byCategory': [
        {'id': 'c1', 'name': 'Study', 'sessions': 3, 'plannedMinutes': 90, 'actualMinutes': 54},
        {'id': 'c2', 'name': 'Sport', 'sessions': 1, 'plannedMinutes': 60, 'actualMinutes': 65},
      ],
    };

    await tester.pumpWidget(buildCard(() async => PlanVsActual.fromJson(twoCategories)));
    await tester.pumpAndSettle();

    expect(find.text('Study'), findsNothing, reason: 'collapsed by default');
    await tester.tap(find.text('By category'));
    await tester.pumpAndSettle();

    expect(find.text('Study'), findsOneWidget);
    expect(find.text('Sport'), findsOneWidget);
  });

  testWidgets('one category is still offered, behind the same tap', (tester) async {
    // It was hidden below two categories, which meant the whole category view had never
    // been seen against real data — and one category still says something the habit rows
    // do not, since a category spans habits.
    await tester.pumpWidget(buildCard(() async => PlanVsActual.fromJson(planVsActualResponse())));
    await tester.pumpAndSettle();

    expect(find.text('By category'), findsOneWidget);
    await tester.tap(find.text('By category'));
    await tester.pumpAndSettle();

    expect(find.text('Study'), findsOneWidget);
  });

  testWidgets('the category view adds up to the same headline as the habit rows',
      (tester) async {
    // One category covering a quarter of the window used to render as if it were all of it.
    final partial = {
      ...planVsActualResponse(),
      'byCategory': [
        {'id': 'c1', 'name': 'Study', 'sessions': 1, 'plannedMinutes': 30, 'actualMinutes': 20},
      ],
    };

    await tester.pumpWidget(buildCard(() async => PlanVsActual.fromJson(partial)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('By category'));
    await tester.pumpAndSettle();

    expect(find.text('Study'), findsOneWidget);
    expect(find.text('No category'), findsOneWidget);
    // 3 of the 4 sessions, 1h 39m of the 1h 59m, are in that row.
    expect(find.text('1h 39m of 2h'), findsOneWidget);
  });

  testWidgets('no category remainder row when every session has one', (tester) async {
    final complete = {
      ...planVsActualResponse(),
      'byCategory': [
        {'id': 'c1', 'name': 'Study', 'sessions': 4, 'plannedMinutes': 150, 'actualMinutes': 119},
      ],
    };

    await tester.pumpWidget(buildCard(() async => PlanVsActual.fromJson(complete)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('By category'));
    await tester.pumpAndSettle();

    expect(find.text('No category'), findsNothing);
  });

  testWidgets('sessions with no habit get their own row, not an empty state', (tester) async {
    await tester.pumpWidget(
        buildCard(() async => PlanVsActual.fromJson(sessionsWithNoHabitResponse())));
    await tester.pumpAndSettle();

    expect(find.text('Finish a focus session and the comparison shows up here.'), findsNothing);
    expect(find.text('Not linked to a habit'), findsOneWidget);
    expect(find.text('13h 10m of 15h'), findsOneWidget);
    expect(
      find.text('You booked 15h and spent 13h 10m across 15 sessions.'),
      findsOneWidget,
    );
  });

  testWidgets('no extra row when every session belongs to a habit', (tester) async {
    await tester.pumpWidget(buildCard(() async => PlanVsActual.fromJson(planVsActualResponse())));
    await tester.pumpAndSettle();

    expect(find.text('Not linked to a habit'), findsNothing);
  });

  testWidgets('a habit with no booked time gets no bar and says why', (tester) async {
    final unbooked = {
      'byHabit': [
        {'id': 'h1', 'name': 'Unbooked', 'sessions': 2, 'plannedMinutes': 0, 'actualMinutes': 40},
      ],
      'byCategory': <Map<String, dynamic>>[],
      'totalSessions': 2,
      'totalPlannedMinutes': 0,
      'totalActualMinutes': 40,
    };

    await tester.pumpWidget(buildCard(() async => PlanVsActual.fromJson(unbooked)));
    await tester.pumpAndSettle();

    expect(find.text('No time was booked for these'), findsOneWidget);
    expect(find.textContaining('under'), findsNothing);
    expect(find.textContaining('over'), findsNothing);
  });
}
