import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/home/domain/home_agenda.dart';

void main() {
  /// A fixed "now": Monday 2 March 2026, 9am local.
  final now = DateTime(2026, 3, 2, 9);

  EventModel event({
    required String id,
    required DateTime localStart,
    Duration duration = const Duration(hours: 1),
    String habitId = '',
    bool isCompleted = false,
    String? recurrenceRule,
  }) {
    return EventModel(
      id: id,
      title: 'Event $id',
      startTime: localStart.toUtc(),
      endTime: localStart.add(duration).toUtc(),
      habitId: habitId,
      isCompleted: isCompleted,
      recurrenceRule: recurrenceRule,
    );
  }

  HabitModel habit(String id) =>
      HabitModel(id: id, name: 'Habit $id', targetDays: const []);

  group('focus event', () {
    test('is the event running right now, not the next one to start', () {
      final agenda = HomeAgenda.build(
        events: [
          event(
            id: 'running',
            localStart: now.subtract(const Duration(minutes: 20)),
          ),
          event(id: 'later', localStart: now.add(const Duration(hours: 2))),
        ],
        habits: const [],
        now: now,
      );

      expect(agenda.focusEvent?.id, 'running');
      expect(agenda.isHappeningNow, isTrue);
    });

    test('falls back to the next upcoming event when nothing is running', () {
      final agenda = HomeAgenda.build(
        events: [
          event(id: 'later', localStart: now.add(const Duration(hours: 4))),
          event(id: 'sooner', localStart: now.add(const Duration(hours: 1))),
        ],
        habits: const [],
        now: now,
      );

      expect(agenda.focusEvent?.id, 'sooner');
      expect(agenda.isHappeningNow, isFalse);
    });

    test('skips completed events', () {
      final agenda = HomeAgenda.build(
        events: [
          event(
            id: 'done',
            localStart: now.add(const Duration(hours: 1)),
            isCompleted: true,
          ),
          event(id: 'todo', localStart: now.add(const Duration(hours: 3))),
        ],
        habits: const [],
        now: now,
      );

      expect(agenda.focusEvent?.id, 'todo');
    });

    test('ignores an event that already finished', () {
      final agenda = HomeAgenda.build(
        events: [
          event(id: 'over', localStart: now.subtract(const Duration(hours: 5))),
        ],
        habits: const [],
        now: now,
      );

      expect(agenda.focusEvent, isNull);
    });

    test('ignores an event beyond the look-ahead window', () {
      // Without the window this would be offered as "up next", a month early.
      final agenda = HomeAgenda.build(
        events: [
          event(id: 'far', localStart: now.add(const Duration(days: 30))),
        ],
        habits: const [],
        now: now,
        lookAhead: const Duration(days: 7),
      );

      expect(agenda.focusEvent, isNull);
    });

    test('is null when there are no events at all', () {
      final agenda = HomeAgenda.build(
        events: const [],
        habits: const [],
        now: now,
      );

      expect(agenda.focusEvent, isNull);
      expect(agenda.isHappeningNow, isFalse);
      expect(agenda.hasAnythingToday, isFalse);
    });

    test('picks an occurrence of a recurring event, not the stored base event', () {
      // The base event started last week; today's occurrence is what matters.
      final agenda = HomeAgenda.build(
        events: [
          event(
            id: 'daily',
            localStart: DateTime(2026, 2, 23, 18),
            recurrenceRule: 'FREQ=DAILY;INTERVAL=1;COUNT=30',
          ),
        ],
        habits: const [],
        now: now,
      );

      expect(agenda.focusEvent?.id, 'daily');
      expect(
        agenda.focusEvent?.startTime.toLocal(),
        DateTime(2026, 3, 2, 18),
        reason: 'today at 18:00, not the series start back in February',
      );
    });
  });

  group('rest of today', () {
    test('lists later events today and leaves out the focus event', () {
      final agenda = HomeAgenda.build(
        events: [
          event(id: 'first', localStart: now.add(const Duration(hours: 1))),
          event(id: 'second', localStart: now.add(const Duration(hours: 3))),
          event(id: 'third', localStart: now.add(const Duration(hours: 5))),
        ],
        habits: const [],
        now: now,
      );

      expect(agenda.focusEvent?.id, 'first');
      expect(agenda.restOfToday.map((e) => e.id), ['second', 'third']);
    });

    test('stops at midnight, so tomorrow is not counted as today', () {
      final agenda = HomeAgenda.build(
        events: [
          event(id: 'today', localStart: now.add(const Duration(hours: 2))),
          event(id: 'tomorrow', localStart: DateTime(2026, 3, 3, 10)),
        ],
        habits: const [],
        now: now,
      );

      expect(agenda.restOfToday, isEmpty);
      expect(agenda.totalToday, 1);
    });

    test('leaves out an event that has already started', () {
      final agenda = HomeAgenda.build(
        events: [
          event(
            id: 'running',
            localStart: now.subtract(const Duration(minutes: 30)),
          ),
          event(id: 'earlier', localStart: now.subtract(const Duration(hours: 4))),
          event(id: 'later', localStart: now.add(const Duration(hours: 2))),
        ],
        habits: const [],
        now: now,
      );

      expect(agenda.restOfToday.map((e) => e.id), ['later']);
    });

    test('excludes only the focus occurrence, not every occurrence of its event', () {
      // A daily event: today's occurrence is the focus, tomorrow's must not be
      // dragged into "rest of today" just because it shares an id.
      final agenda = HomeAgenda.build(
        events: [
          event(
            id: 'daily',
            localStart: DateTime(2026, 3, 2, 18),
            recurrenceRule: 'FREQ=DAILY;INTERVAL=1;COUNT=5',
          ),
          event(id: 'other', localStart: now.add(const Duration(hours: 11))),
        ],
        habits: const [],
        now: now,
      );

      expect(
        agenda.focusEvent?.startTime.toLocal(),
        DateTime(2026, 3, 2, 18),
        reason: "today's occurrence of the series, at 18:00, comes first",
      );
      expect(
        agenda.restOfToday.map((e) => e.id),
        ['other'],
        reason:
            'exactly one entry: the focus occurrence is removed, and the series '
            'occurrences on the following four days are not today',
      );
      expect(agenda.totalToday, 2);
    });

    test('a recurring event cannot repeat within one day', () {
      // Recorded because it constrains the code above: HomeAgenda tells occurrences
      // apart by id *and* start time, which would only be load-bearing if one event
      // could occur twice in a day. SfCalendar supports no frequency shorter than
      // DAILY, so FREQ=HOURLY expands to nothing at all rather than to two slots.
      // Same silent-empty behaviour as a malformed rule, documented on
      // EventOccurrenceExpander.
      final agenda = HomeAgenda.build(
        events: [
          event(
            id: 'hourly',
            localStart: DateTime(2026, 3, 2, 10),
            recurrenceRule: 'FREQ=HOURLY;INTERVAL=1;COUNT=2',
          ),
        ],
        habits: const [],
        now: now,
      );

      expect(agenda.totalToday, 0);
      expect(agenda.focusEvent, isNull);
    });
  });

  group('today progress', () {
    test('counts completed against total for today only', () {
      final agenda = HomeAgenda.build(
        events: [
          event(
            id: 'a',
            localStart: now.subtract(const Duration(hours: 3)),
            isCompleted: true,
          ),
          event(
            id: 'b',
            localStart: now.subtract(const Duration(hours: 2)),
            isCompleted: true,
          ),
          event(id: 'c', localStart: now.add(const Duration(hours: 2))),
          event(
            id: 'tomorrow',
            localStart: DateTime(2026, 3, 3, 9),
            isCompleted: true,
          ),
        ],
        habits: const [],
        now: now,
      );

      expect(agenda.completedToday, 2);
      expect(agenda.totalToday, 3);
      expect(agenda.hasAnythingToday, isTrue);
    });
  });

  group('habits without a slot today', () {
    test('lists habits that have no event on the calendar today', () {
      final agenda = HomeAgenda.build(
        events: [
          event(
            id: 'e1',
            localStart: now.add(const Duration(hours: 2)),
            habitId: 'h1',
          ),
        ],
        habits: [habit('h1'), habit('h2'), habit('h3')],
        now: now,
      );

      expect(agenda.habitsWithoutASlotToday.map((h) => h.id), ['h2', 'h3']);
    });

    test('counts a habit as booked even once its event is finished', () {
      // Doing it early should not put the habit back on the "nothing booked" list.
      final agenda = HomeAgenda.build(
        events: [
          event(
            id: 'e1',
            localStart: now.subtract(const Duration(hours: 4)),
            habitId: 'h1',
            isCompleted: true,
          ),
        ],
        habits: [habit('h1')],
        now: now,
      );

      expect(agenda.habitsWithoutASlotToday, isEmpty);
    });

    test('an event booked for tomorrow does not cover today', () {
      final agenda = HomeAgenda.build(
        events: [
          event(
            id: 'e1',
            localStart: DateTime(2026, 3, 3, 9),
            habitId: 'h1',
          ),
        ],
        habits: [habit('h1')],
        now: now,
      );

      expect(agenda.habitsWithoutASlotToday.map((h) => h.id), ['h1']);
    });

    test('a recurring event covers today through its occurrence', () {
      final agenda = HomeAgenda.build(
        events: [
          event(
            id: 'daily',
            localStart: DateTime(2026, 2, 23, 18),
            habitId: 'h1',
            recurrenceRule: 'FREQ=DAILY;INTERVAL=1;COUNT=30',
          ),
        ],
        habits: [habit('h1')],
        now: now,
      );

      expect(agenda.habitsWithoutASlotToday, isEmpty);
    });

    test('lists every habit when nothing is scheduled', () {
      final agenda = HomeAgenda.build(
        events: const [],
        habits: [habit('h1'), habit('h2')],
        now: now,
      );

      expect(agenda.habitsWithoutASlotToday, hasLength(2));
    });
  });
}
