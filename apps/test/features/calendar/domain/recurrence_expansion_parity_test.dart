import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/calendar/domain/event_occurrence_expander.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';

/// The client's half of the recurrence parity check.
///
/// The server expands repeating events too (`RecurrenceExpander`), and the two must agree
/// on which days a series has — otherwise the calendar shows one week and anything the
/// server reasons about (free time, what was done) describes another. Both sides run the
/// same cases from `test-fixtures/recurrence-expansion.json`; the server's half is
/// `RecurrenceExpanderTests`.
///
/// Times in the fixture are local wall-clock values, so this test builds them with the
/// device's local zone and compares wall-clock results: it holds on any machine.
void main() {
  // `flutter test` runs from `apps/`; the fixture is shared with the server, at the root.
  final fixture = jsonDecode(
    File('../test-fixtures/recurrence-expansion.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final cases = (fixture['cases'] as List).cast<Map<String, dynamic>>();

  const seriesId = 'series';
  const duration = Duration(minutes: 30);

  group('EventOccurrenceExpander matches the shared recurrence fixture', () {
    for (final testCase in cases) {
      test(testCase['name'] as String, () {
        final start = _local(testCase['start'] as String);
        final exceptions = _strings(testCase['exceptions'])
            .map((wall) => _local(wall).toUtc().toIso8601String())
            .join(',');

        final series = EventModel(
          id: seriesId,
          title: 'Series',
          startTime: start.toUtc(),
          endTime: start.add(duration).toUtc(),
          habitId: '',
          recurrenceRule: testCase['rule'] as String,
          recurrenceExceptionDates: exceptions.isEmpty ? null : exceptions,
        );

        final children = [
          for (final (index, wall) in _strings(testCase['children']).indexed)
            EventModel(
              id: 'child-$index',
              title: 'Series',
              startTime: _local(wall).toUtc(),
              endTime: _local(wall).add(duration).toUtc(),
              habitId: '',
              parentEventId: seriesId,
              exceptionDate: _local(wall).toUtc(),
            ),
        ];

        final occurrences = EventOccurrenceExpander.expand(
          events: [series, ...children],
          rangeStart: _local(testCase['rangeStart'] as String),
          rangeEnd: _local(testCase['rangeEnd'] as String),
        );

        final seriesDays = occurrences
            .where((occurrence) => occurrence.id == seriesId)
            .map((occurrence) => _wall(occurrence.startTime.toLocal()))
            .toList();

        final clientGap = testCase['clientGap'] as String?;
        if (clientGap != null) {
          // A known gap, recorded so it is not mistaken for agreement. If this fails, the
          // client now expands the rule: delete `clientGap` from the fixture case.
          expect(seriesDays, isEmpty, reason: clientGap);
          return;
        }

        expect(seriesDays, _strings(testCase['expected']));
      });
    }
  });
}

/// A fixture time (`yyyy-MM-ddTHH:mm`, no zone) as a local [DateTime].
DateTime _local(String wall) => DateTime.parse(wall);

String _wall(DateTime local) =>
    '${local.year.toString().padLeft(4, '0')}-${_two(local.month)}-${_two(local.day)}'
    'T${_two(local.hour)}:${_two(local.minute)}';

String _two(int value) => value.toString().padLeft(2, '0');

List<String> _strings(Object? value) => value == null ? const [] : (value as List).cast<String>();
