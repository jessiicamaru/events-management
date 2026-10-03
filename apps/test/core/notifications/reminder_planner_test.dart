import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/notifications/reminder_planner.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';

void main() {
  /// A fixed "now" so the tests do not depend on the real clock.
  final now = DateTime(2026, 3, 2, 9);

  EventModel event({
    required String id,
    required DateTime localStart,
    // A valid offset: 10 is deliberately NOT in the option set, and defaulting to it
    // would make every 'isEmpty' assertion below pass for the wrong reason.
    List<int> reminders = const [5],
    bool isCompleted = false,
    String? recurrenceRule,
    String? recurrenceExceptionDates,
    String? parentEventId,
    DateTime? exceptionDate,
  }) {
    return EventModel(
      id: id,
      title: 'Event $id',
      startTime: localStart.toUtc(),
      endTime: localStart.add(const Duration(hours: 1)).toUtc(),
      habitId: '',
      isCompleted: isCompleted,
      recurrenceRule: recurrenceRule,
      recurrenceExceptionDates: recurrenceExceptionDates,
      parentEventId: parentEventId,
      exceptionDate: exceptionDate,
      reminderMinutesBefore: reminders,
    );
  }

  group('ReminderPlanner.plan', () {
    test('schedules one reminder per offset on the event', () {
      // The jogging case: remind me an hour, half an hour, and five minutes before.
      final start = now.add(const Duration(hours: 3));

      final plan = ReminderPlanner.plan(
        events: [event(id: 'jog', localStart: start, reminders: [60, 30, 5])],
        now: now,
      );

      expect(plan, hasLength(3));
      expect(
        plan.map((r) => r.minutesBefore),
        [60, 30, 5],
        reason: 'earliest reminder fires first',
      );
      expect(plan.map((r) => r.fireAt), [
        start.subtract(const Duration(minutes: 60)),
        start.subtract(const Duration(minutes: 30)),
        start.subtract(const Duration(minutes: 5)),
      ]);
    });

    test('gives each offset its own id, so they do not overwrite each other', () {
      final plan = ReminderPlanner.plan(
        events: [
          event(
            id: 'jog',
            localStart: now.add(const Duration(hours: 3)),
            reminders: [60, 30, 5],
          ),
        ],
        now: now,
      );

      expect(plan.map((r) => r.id).toSet(), hasLength(3));
    });

    test('schedules nothing for an event with no reminders', () {
      // "None" is a valid choice and the default for a new event.
      final plan = ReminderPlanner.plan(
        events: [
          event(
            id: 'quiet',
            localStart: now.add(const Duration(hours: 2)),
            reminders: const [],
          ),
        ],
        now: now,
      );

      expect(plan, isEmpty);
    });

    test('treats 0 as "when it starts"', () {
      final start = now.add(const Duration(hours: 1));

      final plan = ReminderPlanner.plan(
        events: [event(id: 'a', localStart: start, reminders: [0])],
        now: now,
      );

      expect(plan.single.fireAt, start);
      expect(plan.single.minutesBefore, 0);
    });

    test('keeps the offsets that are still in the future and drops the rest', () {
      // Starts in 20 minutes: the 60-minute reminder is already overdue, the others
      // are not. Losing one offset must not lose the whole event.
      final plan = ReminderPlanner.plan(
        events: [
          event(
            id: 'soon',
            localStart: now.add(const Duration(minutes: 20)),
            reminders: [60, 30, 15, 5, 0],
          ),
        ],
        now: now,
      );

      expect(plan.map((r) => r.minutesBefore), [15, 5, 0]);
    });

    test('ignores an offset that is not an offered option', () {
      // A stale client could still send 10 or 45; the server rejects them, and the
      // planner should not schedule them either.
      final plan = ReminderPlanner.plan(
        events: [
          event(
            id: 'a',
            localStart: now.add(const Duration(hours: 3)),
            reminders: [60, 45, 10, 5],
          ),
        ],
        now: now,
      );

      expect(plan.map((r) => r.minutesBefore), [60, 5]);
    });

    test('skips completed events', () {
      final plan = ReminderPlanner.plan(
        events: [
          event(
            id: 'done',
            localStart: now.add(const Duration(hours: 2)),
            isCompleted: true,
          ),
        ],
        now: now,
      );

      expect(plan, isEmpty);
    });

    test('skips events in the past', () {
      final plan = ReminderPlanner.plan(
        events: [
          event(id: 'past', localStart: now.subtract(const Duration(days: 1))),
        ],
        now: now,
      );

      expect(plan, isEmpty);
    });

    test('ignores events beyond the horizon', () {
      final plan = ReminderPlanner.plan(
        events: [
          event(id: 'near', localStart: now.add(const Duration(days: 1))),
          event(id: 'far', localStart: now.add(const Duration(days: 5))),
        ],
        now: now,
        horizon: const Duration(days: 2),
      );

      expect(plan.map((r) => r.eventId), ['near']);
    });

    test('applies the event reminders to every occurrence of a recurring event', () {
      final plan = ReminderPlanner.plan(
        events: [
          event(
            id: 'daily',
            localStart: now.add(const Duration(hours: 3)),
            reminders: [30, 5],
            recurrenceRule: 'FREQ=DAILY;INTERVAL=1;COUNT=4',
          ),
        ],
        now: now,
        horizon: const Duration(days: 7),
      );

      // 4 occurrences x 2 reminders.
      expect(plan, hasLength(8));
      expect(plan.map((r) => r.id).toSet(), hasLength(8));
    });

    test('lets one day of a recurring series use different reminders', () {
      // This is the per-occurrence override: the user edited Wednesday only. That edit
      // creates a child event carrying its own reminder set, and the expander
      // substitutes it for the master's occurrence.
      final seriesStart = DateTime(2026, 3, 2, 18);
      final wednesday = DateTime(2026, 3, 4, 18);

      final master = event(
        id: 'jog',
        localStart: seriesStart,
        reminders: [30],
        recurrenceRule: 'FREQ=DAILY;INTERVAL=1;COUNT=4',
        recurrenceExceptionDates: wednesday.toUtc().toIso8601String(),
      );

      final overriddenDay = event(
        id: 'jog-wed',
        localStart: wednesday,
        reminders: [60, 5],
        parentEventId: 'jog',
        exceptionDate: wednesday.toUtc(),
      );

      final plan = ReminderPlanner.plan(
        events: [master, overriddenDay],
        now: now,
        horizon: const Duration(days: 7),
      );

      final wednesdayReminders =
          plan.where((r) => r.eventId == 'jog-wed').toList();
      final seriesReminders = plan.where((r) => r.eventId == 'jog').toList();

      expect(
        wednesdayReminders.map((r) => r.minutesBefore),
        [60, 5],
        reason: 'the edited day uses its own set',
      );
      expect(
        seriesReminders.every((r) => r.minutesBefore == 30),
        isTrue,
        reason: 'every other day keeps the series set',
      );
      expect(
        seriesReminders.any((r) => r.eventStart.day == wednesday.day),
        isFalse,
        reason: 'the master must not also fire on the overridden day',
      );
    });

    test('returns reminders in firing order across events', () {
      final plan = ReminderPlanner.plan(
        events: [
          event(
            id: 'later',
            localStart: now.add(const Duration(hours: 6)),
            reminders: [5],
          ),
          event(
            id: 'earlier',
            localStart: now.add(const Duration(hours: 2)),
            reminders: [5],
          ),
        ],
        now: now,
      );

      expect(plan.map((r) => r.eventId), ['earlier', 'later']);
    });

    test('caps the plan and keeps the soonest reminders', () {
      final events = List.generate(
        10,
        (i) => event(
          id: 'e$i',
          localStart: now.add(Duration(hours: 2 + i)),
          reminders: [5],
        ),
      );

      final plan = ReminderPlanner.plan(
        events: events,
        now: now,
        maxReminders: 3,
      );

      expect(plan, hasLength(3));
      expect(plan.map((r) => r.eventId), ['e0', 'e1', 'e2']);
    });

    test('returns nothing when there are no events', () {
      expect(ReminderPlanner.plan(events: [], now: now), isEmpty);
    });
  });

  group('ReminderPlanner.reminderId', () {
    final start = DateTime(2026, 3, 2, 9, 30);

    test('is stable for the same occurrence and offset', () {
      expect(
        ReminderPlanner.reminderId('event-1', start, 30),
        ReminderPlanner.reminderId('event-1', start, 30),
      );
    });

    test('differs per offset, so an event can hold several reminders', () {
      expect(
        ReminderPlanner.reminderId('event-1', start, 30),
        isNot(ReminderPlanner.reminderId('event-1', start, 5)),
      );
    });

    test('ignores seconds, which are not meaningful for an occurrence slot', () {
      expect(
        ReminderPlanner.reminderId('event-1', DateTime(2026, 3, 2, 9, 30, 0), 5),
        ReminderPlanner.reminderId('event-1', DateTime(2026, 3, 2, 9, 30, 45), 5),
      );
    });

    test('differs per occurrence of the same event', () {
      expect(
        ReminderPlanner.reminderId('event-1', DateTime(2026, 3, 2, 9), 5),
        isNot(ReminderPlanner.reminderId('event-1', DateTime(2026, 3, 3, 9), 5)),
      );
    });

    test('differs per event at the same time', () {
      expect(
        ReminderPlanner.reminderId('event-1', start, 5),
        isNot(ReminderPlanner.reminderId('event-2', start, 5)),
      );
    });

    test('always fits in a positive 32-bit int, as Android requires', () {
      for (var i = 0; i < 100; i++) {
        for (final offset in [0, 5, 15, 30, 60]) {
          final id = ReminderPlanner.reminderId(
            'event-$i',
            start.add(Duration(minutes: i)),
            offset,
          );

          expect(id, greaterThanOrEqualTo(0));
          expect(id, lessThanOrEqualTo(0x7FFFFFFF));
        }
      }
    });
  });
}
