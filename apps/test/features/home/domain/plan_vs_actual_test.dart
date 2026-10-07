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
      expect(report.unlinkedPlannedMinutes, 60);
      expect(report.unlinkedActualMinutes, 30);
    });

    test('no row when every session belongs to a habit', () {
      expect(PlanVsActual.fromJson(planVsActualResponse()).unlinked, isNull);
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
