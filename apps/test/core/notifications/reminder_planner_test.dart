import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/notifications/reminder_planner.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';

void main() {
  /// A fixed "now" so the tests do not depend on the real clock.
  final now = DateTime(2026, 3, 2, 9);
  const lead = Duration(minutes: 10);

  EventModel event({
    required String id,
    required DateTime localStart,
    bool isCompleted = false,
    String? recurrenceRule,
  }) {
    return EventModel(
      id: id,
      title: 'Event $id',
      startTime: localStart.toUtc(),
      endTime: localStart.add(const Duration(hours: 1)).toUtc(),
      habitId: '',
      isCompleted: isCompleted,
      recurrenceRule: recurrenceRule,
    );
  }

  group('ReminderPlanner.plan', () {
    test('schedules a reminder the lead time before the event', () {
      final start = now.add(const Duration(hours: 2));

      final plan = ReminderPlanner.plan(
        events: [event(id: 'a', localStart: start)],
        now: now,
        leadTime: lead,
      );

      expect(plan, hasLength(1));
      expect(plan.single.fireAt, start.subtract(lead));
      expect(plan.single.eventStart, start);
      expect(plan.single.eventId, 'a');
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
        leadTime: lead,
      );

      expect(plan, isEmpty);
    });

    test('skips events whose reminder time has already passed', () {
      // Starts in 5 minutes, but the reminder was due 5 minutes ago.
      final plan = ReminderPlanner.plan(
        events: [event(id: 'soon', localStart: now.add(const Duration(minutes: 5)))],
        now: now,
        leadTime: lead,
      );

      expect(
        plan,
        isEmpty,
        reason: 'a reminder for a moment that already passed is noise',
      );
    });

    test('skips events in the past', () {
      final plan = ReminderPlanner.plan(
        events: [event(id: 'past', localStart: now.subtract(const Duration(days: 1)))],
        now: now,
        leadTime: lead,
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
        leadTime: lead,
        horizon: const Duration(days: 2),
      );

      expect(plan.map((r) => r.eventId), ['near']);
    });

    test('schedules each occurrence of a recurring event separately', () {
      final plan = ReminderPlanner.plan(
        events: [
          event(
            id: 'daily',
            localStart: now.add(const Duration(hours: 2)),
            recurrenceRule: 'FREQ=DAILY;INTERVAL=1;COUNT=5',
          ),
        ],
        now: now,
        leadTime: lead,
        horizon: const Duration(days: 7),
      );

      expect(plan, hasLength(5));

      // Distinct ids, or later occurrences would overwrite earlier ones.
      expect(plan.map((r) => r.id).toSet(), hasLength(5));
    });

    test('returns reminders in firing order', () {
      final plan = ReminderPlanner.plan(
        events: [
          event(id: 'third', localStart: now.add(const Duration(hours: 6))),
          event(id: 'first', localStart: now.add(const Duration(hours: 2))),
          event(id: 'second', localStart: now.add(const Duration(hours: 4))),
        ],
        now: now,
        leadTime: lead,
      );

      expect(plan.map((r) => r.eventId), ['first', 'second', 'third']);
    });

    test('caps the plan and keeps the soonest reminders', () {
      final events = List.generate(
        10,
        (i) => event(id: 'e$i', localStart: now.add(Duration(hours: 2 + i))),
      );

      final plan = ReminderPlanner.plan(
        events: events,
        now: now,
        leadTime: lead,
        maxReminders: 3,
      );

      expect(plan, hasLength(3));
      expect(plan.map((r) => r.eventId), ['e0', 'e1', 'e2']);
    });

    test('handles a zero lead time by firing at the start', () {
      final start = now.add(const Duration(hours: 1));

      final plan = ReminderPlanner.plan(
        events: [event(id: 'a', localStart: start)],
        now: now,
        leadTime: Duration.zero,
      );

      expect(plan.single.fireAt, start);
    });

    test('returns nothing when there are no events', () {
      expect(
        ReminderPlanner.plan(events: [], now: now, leadTime: lead),
        isEmpty,
      );
    });
  });

  group('ReminderPlanner.reminderId', () {
    test('is stable for the same occurrence, so re-planning is idempotent', () {
      final start = DateTime(2026, 3, 2, 9, 30);

      expect(
        ReminderPlanner.reminderId('event-1', start),
        ReminderPlanner.reminderId('event-1', start),
      );
    });

    test('ignores seconds, which are not meaningful for an occurrence slot', () {
      expect(
        ReminderPlanner.reminderId('event-1', DateTime(2026, 3, 2, 9, 30, 0)),
        ReminderPlanner.reminderId('event-1', DateTime(2026, 3, 2, 9, 30, 45)),
      );
    });

    test('differs per occurrence of the same event', () {
      expect(
        ReminderPlanner.reminderId('event-1', DateTime(2026, 3, 2, 9)),
        isNot(ReminderPlanner.reminderId('event-1', DateTime(2026, 3, 3, 9))),
      );
    });

    test('differs per event at the same time', () {
      final start = DateTime(2026, 3, 2, 9);

      expect(
        ReminderPlanner.reminderId('event-1', start),
        isNot(ReminderPlanner.reminderId('event-2', start)),
      );
    });

    test('always fits in a positive 32-bit int, as Android requires', () {
      for (var i = 0; i < 200; i++) {
        final id = ReminderPlanner.reminderId(
          'event-$i',
          DateTime(2026, 3, 2, 9).add(Duration(minutes: i)),
        );

        expect(id, greaterThanOrEqualTo(0));
        expect(id, lessThanOrEqualTo(0x7FFFFFFF));
      }
    });
  });
}
