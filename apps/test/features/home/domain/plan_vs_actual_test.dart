import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/home/domain/models/plan_vs_actual.dart';

/// The shape measured off the running server, so a rename on either side shows up here.
Map<String, dynamic> serverResponse() => {
      'byHabit': [
        {
          'id': 'b7959df8-82fa-4a88-a042-03f4b84ee790',
          'name': 'Running',
          'sessions': 1,
          'plannedMinutes': 60,
          'actualMinutes': 65,
        },
        {
          'id': '32118aec-8323-44cd-85ce-a07a29249f6b',
          'name': 'Reading',
          'sessions': 3,
          'plannedMinutes': 90,
          'actualMinutes': 54,
        },
      ],
      'byCategory': [
        {
          'id': '73a7dea1-855c-4429-b154-f755ceaa7fcd',
          'name': 'Study',
          'sessions': 3,
          'plannedMinutes': 90,
          'actualMinutes': 54,
        },
      ],
      'totalSessions': 4,
      'totalPlannedMinutes': 150,
      'totalActualMinutes': 119,
    };

void main() {
  group('fromJson', () {
    test('reads the shape the server sends', () {
      final report = PlanVsActual.fromJson(serverResponse());

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
      final report = PlanVsActual.fromJson(serverResponse());

      expect(report.ratio, closeTo(119 / 150, 0.001));
    });
  });
}
