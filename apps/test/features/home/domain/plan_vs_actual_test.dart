import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/home/domain/models/plan_vs_actual.dart';
import '../plan_vs_actual_fixture.dart';

void main() {
  group('fromJson', () {
    test('reads the shape the server sends', () {
      final report = PlanVsActual.fromJson(planVsActualResponse());

      expect(report.byHabit.map((i) => i.name), ['Running', 'Reading']);
      expect(report.byHabit.first.sessions, 1);
      expect(report.byHabit.first.plannedMinutes, 60);
      expect(report.byHabit.first.actualMinutes, 65);
      expect(report.byCategory.single.name, 'Study');
      expect(report.totalSessions, 4);
      expect(report.totalPlannedMinutes, 150);
      expect(report.totalActualMinutes, 119);
      expect(report.isEmpty, isFalse);
    });

    test('survives missing fields rather than throwing', () {
      // A field renamed on the server must degrade to zero, not crash the home screen.
      final report = PlanVsActual.fromJson({'byHabit': null, 'totalSessions': null});

      expect(report.byHabit, isEmpty);
      expect(report.byCategory, isEmpty);
      expect(report.totalSessions, 0);
      expect(report.isEmpty, isTrue);
      expect(report.ratio, isNull);
    });
  });

  group('sessions with no habit', () {
    test('are counted in the totals and offered as their own row', () {
      // Measured on the dev database: the only account with sessions in the last 14 days
      // had 15 of them, all on plain calendar events, so the habit grouping saw none.
      final report = PlanVsActual.fromJson(sessionsWithNoHabitResponse());

      expect(report.isEmpty, isFalse, reason: '15 sessions is not "nothing here yet"');
      expect(report.totalActualMinutes, 790);
      expect(report.unlinkedSessions, 15);
      expect(report.unlinked, isNotNull);
      expect(report.unlinked!.actualMinutes, 790);
      expect(report.unlinked!.plannedMinutes, 900);
    });

    test('are whatever the habit rows do not account for', () {
      final report = PlanVsActual.fromJson({
        ...planVsActualResponse(),
        'totalSessions': 6,
        'totalPlannedMinutes': 210,
        'totalActualMinutes': 149,
      });

      expect(report.unlinkedSessions, 2);
      expect(report.unlinked!.plannedMinutes, 60);
      expect(report.unlinked!.actualMinutes, 30);
    });

    test('no row when every session belongs to a habit', () {
      expect(PlanVsActual.fromJson(planVsActualResponse()).unlinked, isNull);
    });
  });

  group('sessions with no category', () {
    test('get the same remainder row as habitless ones', () {
      // Both groupings miss a different set of sessions. Only the habit half had a row at
      // first, so the category view covered a fraction of the headline with nothing saying so.
      final report = PlanVsActual.fromJson({
        ...planVsActualResponse(),
        'byCategory': [
          {'id': 'c1', 'name': 'Study', 'sessions': 1, 'plannedMinutes': 30, 'actualMinutes': 20},
        ],
      });

      expect(report.totalSessions, 4);
      expect(report.uncategorisedSessions, 3);
      expect(report.uncategorised, isNotNull);
      expect(report.uncategorised!.sessions, 3);
      expect(report.uncategorised!.plannedMinutes, 120);
      expect(report.uncategorised!.actualMinutes, 99);
    });

    test('no row when every session has a category', () {
      final report = PlanVsActual.fromJson({
        ...planVsActualResponse(),
        'byCategory': [
          {'id': 'c1', 'name': 'Study', 'sessions': 4, 'plannedMinutes': 150, 'actualMinutes': 119},
        ],
      });

      expect(report.uncategorised, isNull);
    });

    test('no row when a grouping accounts for more than the totals', () {
      // Impossible unless the server disagrees with itself; a negative bar is worse than
      // nothing.
      final report = PlanVsActual.fromJson({
        ...planVsActualResponse(),
        'totalSessions': 1,
      });

      expect(report.unlinked, isNull);
      expect(report.uncategorised, isNull);
    });

    test('no row when the counts agree but the minutes do not', () {
      // The groupings and the totals are three separate queries with no snapshot between
      // them, so a session finished or deleted mid-load can leave the count positive and the
      // minutes negative. That rendered as "-30 min of -20 min" under "no time was booked".
      final report = PlanVsActual.fromJson({
        'byHabit': [
          {'id': 'h1', 'name': 'Reading', 'sessions': 6, 'plannedMinutes': 620, 'actualMinutes': 600},
        ],
        'byCategory': <Map<String, dynamic>>[],
        'totalSessions': 8,
        'totalPlannedMinutes': 600,
        'totalActualMinutes': 570,
      });

      expect(report.unlinkedSessions, 2, reason: 'the count alone looks fine');
      expect(report.unlinked, isNull, reason: 'but the minutes do not, so no row');
    });
  });

  group('ratio and difference', () {
    test('under, over and exactly as booked', () {
      final under = PlanVsActualItem(
          id: 'a', name: 'Reading', sessions: 3, plannedMinutes: 90, actualMinutes: 54);
      final over = PlanVsActualItem(
          id: 'b', name: 'Running', sessions: 1, plannedMinutes: 60, actualMinutes: 65);
      final exact = PlanVsActualItem(
          id: 'c', name: 'Stretch', sessions: 2, plannedMinutes: 20, actualMinutes: 20);

      expect(under.ratio, closeTo(0.6, 0.001));
      expect(under.differenceMinutes, -36);
      expect(over.ratio, closeTo(65 / 60, 0.001));
      expect(over.differenceMinutes, 5);
      expect(exact.ratio, 1.0);
      expect(exact.differenceMinutes, 0);
    });

    test('no ratio when nothing was booked, rather than zero or infinity', () {
      // An event may carry a zero TargetDuration, and "no answer" is not the same as 0%.
      final item = PlanVsActualItem(
          id: 'd', name: 'Unbooked', sessions: 2, plannedMinutes: 0, actualMinutes: 40);

      expect(item.ratio, isNull);
      expect(item.differenceMinutes, 40);
    });

    test('the overall ratio comes from the totals', () {
      final report = PlanVsActual.fromJson(planVsActualResponse());

      expect(report.ratio, closeTo(119 / 150, 0.001));
    });
  });
}
