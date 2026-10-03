import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/calendar/domain/event_occurrence.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_task_model.dart';

void main() {
  final start = DateTime.utc(2026, 9, 11, 10);

  EventModel event({String? rule, String? parentEventId}) => EventModel(
        id: 'e1',
        title: 'Jogging',
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
        habitId: '',
        recurrenceRule: rule,
        parentEventId: parentEventId,
      );

  EventTaskModel task(String id, String title, int order) =>
      EventTaskModel(id: id, eventId: 'x', title: title, order: order);

  group('isSeriesOccurrence', () {
    test('is true for a day of a repeating series', () {
      expect(event(rule: 'RRULE:FREQ=DAILY').isSeriesOccurrence, isTrue);
    });

    test('is false for an ordinary event', () {
      expect(event().isSeriesOccurrence, isFalse);
      expect(event(rule: '').isSeriesOccurrence, isFalse);
    });

    test('is false for a day that already has its own event', () {
      expect(event(parentEventId: 'series').isSeriesOccurrence, isFalse);
    });
  });

  group('copiedTaskFor', () {
    test('matches on position and title', () {
      final copies = [task('c0', 'Warm up', 0), task('c1', 'Run 5 km', 1)];

      expect(copiedTaskFor(task('t1', 'Run 5 km', 1), copies)?.id, 'c1');
    });

    test('tells apart two tasks with the same name by position', () {
      final copies = [task('c0', 'Stretch', 0), task('c2', 'Stretch', 2)];

      expect(copiedTaskFor(task('t2', 'Stretch', 2), copies)?.id, 'c2');
    });

    test('falls back to the title when the day was reordered', () {
      final copies = [task('c0', 'Run 5 km', 0), task('c1', 'Warm up', 1)];

      expect(copiedTaskFor(task('t0', 'Warm up', 0), copies)?.id, 'c1');
    });

    test('is null when the day no longer has that task', () {
      expect(copiedTaskFor(task('t0', 'Warm up', 0), [task('c0', 'Run', 0)]), isNull);
    });
  });
}
