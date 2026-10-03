import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/calendar/domain/event_occurrence_expander.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';

void main() {
  /// Events are stored in UTC; the expander works in local time, so fixtures are
  /// built from a local wall-clock time and converted.
  EventModel event({
    required String id,
    required DateTime localStart,
    Duration duration = const Duration(hours: 1),
    String? recurrenceRule,
    String? recurrenceExceptionDates,
    String? parentEventId,
    DateTime? exceptionDate,
    bool isCompleted = false,
  }) {
    return EventModel(
      id: id,
      title: 'Event $id',
      startTime: localStart.toUtc(),
      endTime: localStart.add(duration).toUtc(),
      habitId: '',
      isCompleted: isCompleted,
      recurrenceRule: recurrenceRule,
      recurrenceExceptionDates: recurrenceExceptionDates,
      parentEventId: parentEventId,
      exceptionDate: exceptionDate,
    );
  }

  /// A fixed week so the tests do not drift with the real clock.
  final monday = DateTime(2026, 3, 2, 9);
  final weekEnd = DateTime(2026, 3, 8, 23, 59);

  group('EventOccurrenceExpander', () {
    test('passes a non-recurring event straight through', () {
      final single = event(id: 'a', localStart: monday);

      final result = EventOccurrenceExpander.expand(
        events: [single],
        rangeStart: monday,
        rangeEnd: weekEnd,
      );

      expect(result, hasLength(1));
      expect(result.single.id, 'a');
    });

    test('does not window non-recurring events', () {
      // The "up next" widget relies on this: an event that began before the range
      // may still be running, so filtering is the caller's decision, not ours.
      final longGone = event(id: 'old', localStart: DateTime(2020, 1, 1, 9));

      final result = EventOccurrenceExpander.expand(
        events: [longGone],
        rangeStart: monday,
        rangeEnd: weekEnd,
      );

      expect(result, hasLength(1));
    });

    test('expands a daily rule into one occurrence per day in range', () {
      final daily = event(
        id: 'daily',
        localStart: monday,
        recurrenceRule: 'FREQ=DAILY;INTERVAL=1;COUNT=7',
      );

      final result = EventOccurrenceExpander.expand(
        events: [daily],
        rangeStart: monday,
        rangeEnd: weekEnd,
      );

      expect(result, hasLength(7));

      // Each occurrence keeps the original duration and time of day.
      for (final occurrence in result) {
        final startLocal = occurrence.startTime.toLocal();
        expect(startLocal.hour, monday.hour);
        expect(
          occurrence.endTime.difference(occurrence.startTime),
          const Duration(hours: 1),
        );
      }
    });

    test('drops an occurrence the user deleted', () {
      final wednesday = DateTime(2026, 3, 4, 9);

      final daily = event(
        id: 'daily',
        localStart: monday,
        recurrenceRule: 'FREQ=DAILY;INTERVAL=1;COUNT=7',
        recurrenceExceptionDates: wednesday.toUtc().toIso8601String(),
      );

      final result = EventOccurrenceExpander.expand(
        events: [daily],
        rangeStart: monday,
        rangeEnd: weekEnd,
      );

      expect(result, hasLength(6));
      expect(
        result.any((e) => e.startTime.toLocal().day == wednesday.day),
        isFalse,
      );
    });

    test('drops an occurrence that an edited child event already represents', () {
      final wednesday = DateTime(2026, 3, 4, 9);

      final daily = event(
        id: 'daily',
        localStart: monday,
        recurrenceRule: 'FREQ=DAILY;INTERVAL=1;COUNT=7',
      );

      // The user moved Wednesday's session; it now exists as its own event.
      final movedChild = event(
        id: 'moved',
        localStart: DateTime(2026, 3, 4, 18),
        parentEventId: 'daily',
        exceptionDate: wednesday.toUtc(),
      );

      final result = EventOccurrenceExpander.expand(
        events: [daily, movedChild],
        rangeStart: monday,
        rangeEnd: weekEnd,
      );

      // 6 generated occurrences + the moved child itself.
      expect(result, hasLength(7));

      final nineAmOnWednesday = result.where((e) {
        final local = e.startTime.toLocal();

        return local.day == wednesday.day && local.hour == 9;
      });
      expect(
        nineAmOnWednesday,
        isEmpty,
        reason: 'the original slot is represented by the child event',
      );
    });

    test('yields nothing for a malformed rule (documents a known limitation)', () {
      // Measured: SfCalendar returns an empty collection for a malformed rule rather
      // than throwing, so the event silently disappears. Asserted here so the
      // behaviour is visible and a future fix has something to change deliberately,
      // rather than discovering it from a user report. See the class doc.
      final broken = event(
        id: 'broken',
        localStart: monday,
        recurrenceRule: 'this is not an rrule',
      );

      final result = EventOccurrenceExpander.expand(
        events: [broken],
        rangeStart: monday,
        rangeEnd: weekEnd,
      );

      expect(
        result,
        isEmpty,
        reason: 'known limitation: a corrupt RRULE hides the event entirely',
      );
    });

    test('yields nothing when a valid rule has no occurrences in range', () {
      // The reason the empty case above cannot simply fall back to the base event:
      // this is indistinguishable from it, and falling back would duplicate events.
      final spent = event(
        id: 'spent',
        localStart: monday,
        recurrenceRule: 'FREQ=DAILY;INTERVAL=1;COUNT=2',
      );

      final result = EventOccurrenceExpander.expand(
        events: [spent],
        rangeStart: DateTime(2026, 4, 1),
        rangeEnd: DateTime(2026, 4, 7),
      );

      expect(result, isEmpty);
    });

    test('returns occurrences sorted by start time', () {
      final later = event(id: 'later', localStart: DateTime(2026, 3, 5, 8));
      final earlier = event(id: 'earlier', localStart: DateTime(2026, 3, 3, 8));

      final result = EventOccurrenceExpander.expand(
        events: [later, earlier],
        rangeStart: monday,
        rangeEnd: weekEnd,
      );

      expect(result.map((e) => e.id), ['earlier', 'later']);
    });

    test('every day of a series starts undone, even if the series row is marked done', () {
      // Completing one session used to mark the series row done, which made every day
      // done: gone from "up next", reminders silenced. Completion now lives on a day's
      // own event, so the series' flag must not leak into its days.
      final series = event(
        id: 'jog',
        localStart: monday,
        recurrenceRule: 'FREQ=DAILY;COUNT=3',
        isCompleted: true,
      ).copyWith(actualDuration: 45);

      final result = EventOccurrenceExpander.expand(
        events: [series],
        rangeStart: monday,
        rangeEnd: weekEnd,
      );

      expect(result, hasLength(3));
      expect(result.every((e) => !e.isCompleted), isTrue);
      expect(result.every((e) => e.actualDuration == null), isTrue);
    });

    test('a split-off day keeps its own completion', () {
      final wednesday = monday.add(const Duration(days: 2));
      final series = event(id: 'jog', localStart: monday, recurrenceRule: 'FREQ=DAILY;COUNT=3');
      final doneWednesday = event(
        id: 'jog-wed',
        localStart: wednesday,
        parentEventId: 'jog',
        exceptionDate: wednesday.toUtc(),
        isCompleted: true,
      );

      final result = EventOccurrenceExpander.expand(
        events: [series, doneWednesday],
        rangeStart: monday,
        rangeEnd: weekEnd,
      );

      // Monday, Tuesday, then Wednesday's own event in the series' place.
      expect(result.map((e) => '${e.id}:${e.isCompleted}'), [
        'jog:false',
        'jog:false',
        'jog-wed:true',
      ]);
    });

    test('returns nothing for no events', () {
      expect(
        EventOccurrenceExpander.expand(
          events: [],
          rangeStart: monday,
          rangeEnd: weekEnd,
        ),
        isEmpty,
      );
    });
  });
}
