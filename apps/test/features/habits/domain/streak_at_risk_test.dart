import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/habits/domain/streak_at_risk.dart';

/// Local times throughout: the rule is "the user's evening", not an instant in UTC.
void main() {
  // A Friday.
  DateTime at(int hour, {int day = 11, int minute = 0}) =>
      DateTime(2026, 9, day, hour, minute);

  HabitModel habit({
    String id = 'habit-1',
    String name = 'Read',
    int streak = 5,
  }) =>
      HabitModel(id: id, name: name, targetDays: const [1, 2, 3, 4, 5], currentStreak: streak);

  EventModel event({
    String id = 'event-1',
    String habitId = 'habit-1',
    required DateTime start,
    bool completed = false,
    String? rule,
    String? parentEventId,
    DateTime? exceptionDate,
  }) =>
      EventModel(
        id: id,
        title: 'Read',
        startTime: start,
        endTime: start.add(const Duration(minutes: 30)),
        habitId: habitId,
        isCompleted: completed,
        recurrenceRule: rule,
        parentEventId: parentEventId,
        exceptionDate: exceptionDate,
      );

  group('StreakAtRisk.evaluate', () {
    test('says nothing before the cutoff hour', () {
      final atRisk = StreakAtRisk.evaluate(
        events: [event(start: at(21))],
        habits: [habit()],
        now: at(19, minute: 59),
      );

      expect(atRisk, isEmpty);
    });

    test('flags an unfinished habit once the day is running out', () {
      final atRisk = StreakAtRisk.evaluate(
        events: [event(start: at(21))],
        habits: [habit()],
        now: at(20),
      );

      expect(atRisk, hasLength(1));
      expect(atRisk.single.habit.name, 'Read');
      expect(atRisk.single.streak, 5);
      expect(atRisk.single.occurrence.startTime, at(21));
    });

    test('ignores a habit with no streak to lose', () {
      final atRisk = StreakAtRisk.evaluate(
        events: [event(start: at(21))],
        habits: [habit(streak: 0)],
        now: at(20),
      );

      expect(atRisk, isEmpty);
    });

    test('ignores a habit that is already done today', () {
      final atRisk = StreakAtRisk.evaluate(
        events: [event(start: at(9), completed: true)],
        habits: [habit()],
        now: at(21),
      );

      expect(atRisk, isEmpty);
    });

    test('ignores a habit already ticked today, even with another slot open', () {
      // The streak needs one completion per calendar day (StreakCalculator distincts on
      // date), so a morning run done leaves the evening one a plan not followed through,
      // not a streak about to break.
      final atRisk = StreakAtRisk.evaluate(
        events: [
          event(id: 'morning', start: at(7), completed: true),
          event(id: 'evening', start: at(21)),
        ],
        habits: [habit()],
        now: at(20),
      );

      expect(atRisk, isEmpty);
    });

    test('still flags a habit whose only completed slot belongs to another habit', () {
      // Negative control for the rule above: the completion must be this habit's.
      final atRisk = StreakAtRisk.evaluate(
        events: [
          event(id: 'other-done', habitId: 'habit-2', start: at(7), completed: true),
          event(id: 'mine-open', start: at(21)),
        ],
        habits: [habit(), habit(id: 'habit-2', name: 'Run', streak: 3)],
        now: at(20),
      );

      expect(atRisk.map((a) => a.habit.id), ['habit-1']);
    });

    test('ignores a habit with nothing booked today', () {
      // Tomorrow's slot is not today's problem, and an unbooked day is the day-boundary
      // question in roadmap 5.1 — not something to nag about.
      final atRisk = StreakAtRisk.evaluate(
        events: [event(start: at(9, day: 12))],
        habits: [habit()],
        now: at(21),
      );

      expect(atRisk, isEmpty);
    });

    test('counts a repeating event as today, and its own day as done', () {
      final series = event(
        id: 'series',
        start: at(7, day: 1),
        rule: 'FREQ=DAILY',
      );

      final stillOpen = StreakAtRisk.evaluate(
        events: [series],
        habits: [habit()],
        now: at(20),
      );
      expect(stillOpen, hasLength(1), reason: "today's occurrence of the series counts");

      // The split-off day stands in for the series' occurrence, and it is completed.
      final splitOff = event(
        id: 'today-of-series',
        start: at(7),
        completed: true,
        parentEventId: 'series',
        exceptionDate: at(7),
      );

      final done = StreakAtRisk.evaluate(
        events: [series, splitOff],
        habits: [habit()],
        now: at(20),
      );
      expect(done, isEmpty, reason: 'the day that replaced it is done');
    });

    test('picks the earliest unfinished slot, and orders by what is at stake', () {
      final atRisk = StreakAtRisk.evaluate(
        events: [
          event(id: 'late', start: at(22)),
          event(id: 'early', start: at(20, minute: 30)),
          event(id: 'other', habitId: 'habit-2', start: at(21)),
        ],
        habits: [habit(), habit(id: 'habit-2', name: 'Run', streak: 30)],
        now: at(20),
      );

      expect(atRisk.map((a) => a.habit.name), ['Run', 'Read']);
      expect(atRisk.last.occurrence.id, 'early');
    });
  });

  group('StreakAtRisk.cutoffFor', () {
    test('is that hour on the same day', () {
      expect(StreakAtRisk.cutoffFor(at(9, minute: 12)), at(20));
      expect(StreakAtRisk.cutoffFor(at(23, minute: 59)), at(20));
    });
  });

  group('StreakAtRisk.nextCutoffAfter', () {
    // What a screen showing the card has to wake up for: evaluate is a function of the
    // clock and nothing re-renders at 20:00 on its own.
    test("is today's cutoff while it is still ahead", () {
      expect(StreakAtRisk.nextCutoffAfter(at(9, minute: 12)), at(20));
      expect(StreakAtRisk.nextCutoffAfter(at(19, minute: 59)), at(20));
    });

    test('rolls to tomorrow once the cutoff has passed', () {
      expect(StreakAtRisk.nextCutoffAfter(at(20)), at(20, day: 12));
      expect(StreakAtRisk.nextCutoffAfter(at(23, minute: 59)), at(20, day: 12));
    });

    test('is always strictly in the future, so a timer for it cannot fire at once', () {
      for (var hour = 0; hour < 24; hour++) {
        final now = at(hour, minute: 30);
        expect(StreakAtRisk.nextCutoffAfter(now).isAfter(now), isTrue,
            reason: 'at $hour:30');
      }
    });

    test('crosses a month end', () {
      final lastOfMonth = DateTime(2026, 9, 30, 22);
      expect(StreakAtRisk.nextCutoffAfter(lastOfMonth), DateTime(2026, 10, 1, 20));
    });
  });
}
