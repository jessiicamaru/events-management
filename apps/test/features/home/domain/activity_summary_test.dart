import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/home/domain/models/activity_summary.dart';
import 'package:habit_tracker/features/home/presentation/widgets/activity_summary_card.dart';
import '../activity_summary_fixture.dart';

void main() {
  group('ActivitySummary.fromJson', () {
    test('reads the days and totals the server sends', () {
      final summary = ActivitySummary.fromJson(serverResponse());

      expect(summary.days, hasLength(3));
      expect(summary.days[1].scheduled, 3);
      expect(summary.days[1].completed, 2);
      expect(summary.days[1].focusMinutes, 75);
      expect(summary.totalFocusMinutes, 95);
      expect(summary.bestFocusMinutes, 75);
    });

    test('keeps the calendar day the server meant, with no time part', () {
      // The server sends midnight UTC. Converting to local time first would move the
      // day backwards for anyone west of UTC, shifting every bar by one.
      final summary = ActivitySummary.fromJson(serverResponse());

      expect(summary.days.last.date, DateTime(2026, 9, 10));
      expect(summary.days.last.date.isUtc, isFalse);
      expect(summary.days.last.date.hour, 0);
    });

    test('has no completion rate when nothing was scheduled', () {
      // Null, not 0%: "0% done" would read as failure when nothing was booked.
      final summary = ActivitySummary.fromJson({
        'days': <dynamic>[],
        'totalOneOffScheduled': 0,
        'totalOneOffCompleted': 0,
        'totalFocusMinutes': 0,
        'bestFocusMinutes': 0,
      });

      expect(summary.completionRate, isNull);
      expect(summary.isEmpty, isTrue);
    });

    test('computes the completion rate', () {
      expect(ActivitySummary.fromJson(serverResponse()).completionRate, 0.75);
    });

    test('counts focus time without any scheduled events as activity', () {
      // A focus session on an event that was later deleted still happened.
      final summary = ActivitySummary.fromJson({
        'days': <dynamic>[],
        'totalOneOffScheduled': 0,
        'totalOneOffCompleted': 0,
        'totalFocusMinutes': 30,
        'bestFocusMinutes': 30,
      });

      expect(summary.isEmpty, isFalse);
    });

    test('tolerates missing fields', () {
      final summary = ActivitySummary.fromJson(<String, dynamic>{});

      expect(summary.days, isEmpty);
      expect(summary.totalScheduled, 0);
    });
  });

  group('ActivitySummary.withRepeatingDays', () {
    /// What the server sends for Mon 7 .. Sun 13 Sep: one-off events and focus time only.
    ActivitySummary week({int oneOffOnWednesday = 0, int focusOnWednesday = 0}) =>
        ActivitySummary.fromJson({
          'days': [
            for (var d = 7; d <= 13; d++)
              {
                'date': '2026-09-${d.toString().padLeft(2, '0')}T00:00:00Z',
                'oneOffScheduled': d == 9 ? oneOffOnWednesday : 0,
                'oneOffCompleted': 0,
                'focusMinutes': d == 9 ? focusOnWednesday : 0,
              },
          ],
          'totalFocusMinutes': focusOnWednesday,
          'bestFocusMinutes': focusOnWednesday,
        });

    EventModel daily({String? rule, String? exceptionDates}) => EventModel(
          id: 'jog',
          title: 'Jogging',
          startTime: DateTime(2026, 9, 1, 7).toUtc(),
          endTime: DateTime(2026, 9, 1, 8).toUtc(),
          habitId: '',
          recurrenceRule: rule ?? 'RRULE:FREQ=DAILY',
          recurrenceExceptionDates: exceptionDates,
          isCompleted: true, // a legacy "whole series done" flag must not count
        );

    EventModel splitOff(int day, {bool done = true, DateTime? movedTo}) {
      final slot = DateTime(2026, 9, day, 7);
      final start = movedTo ?? slot;
      return EventModel(
        id: 'jog-$day',
        title: 'Jogging',
        startTime: start.toUtc(),
        endTime: start.add(const Duration(hours: 1)).toUtc(),
        habitId: '',
        parentEventId: 'jog',
        exceptionDate: slot.toUtc(),
        isCompleted: done,
      );
    }

    test('counts every day of a daily event as scheduled', () {
      final summary = week().withRepeatingDays([daily()]);

      expect(summary.days.map((d) => d.scheduled), [1, 1, 1, 1, 1, 1, 1]);
      expect(summary.totalScheduled, 7);
      expect(summary.totalCompleted, 0, reason: "the series' own flag says nothing about a day");
    });

    test('3 done out of 7, not 3 out of 3', () {
      // The finding in one line: before, only the split-off (completed) days were
      // counted, so this showed "3 of 3 · 100%".
      final summary = week().withRepeatingDays([
        daily(),
        splitOff(8),
        splitOff(9),
        splitOff(10),
      ]);

      expect(summary.totalScheduled, 7);
      expect(summary.totalCompleted, 3);
      expect(summary.completionRate, closeTo(3 / 7, 1e-9));
    });

    test('counts a split-off day once, on its own day, even when it was moved', () {
      final summary = week().withRepeatingDays([
        daily(),
        splitOff(9, movedTo: DateTime(2026, 9, 9, 19)),
      ]);

      final wednesday = summary.days.firstWhere((d) => d.date.day == 9);
      expect(wednesday.scheduled, 1, reason: 'the split-off day replaces the series day');
      expect(wednesday.completed, 1);
    });

    test('adds to the one-off events the server counted, and leaves focus time alone', () {
      final summary = week(oneOffOnWednesday: 2, focusOnWednesday: 40)
          .withRepeatingDays([daily()]);

      final wednesday = summary.days.firstWhere((d) => d.date.day == 9);
      expect(wednesday.scheduled, 3);
      expect(wednesday.focusMinutes, 40);
      expect(summary.totalFocusMinutes, 40);
    });

    test('skips a deleted day and days the rule does not produce', () {
      final weekdaysOnly = daily(
        rule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
        exceptionDates: DateTime(2026, 9, 9, 7).toUtc().toIso8601String(),
      );

      final summary = week().withRepeatingDays([weekdaysOnly]);

      expect(summary.days.map((d) => d.scheduled), [1, 1, 0, 1, 1, 0, 0],
          reason: 'Mon, Tue, (Wed deleted), Thu, Fri; no weekend');
    });

    test('ignores one-off events, which the server already counted', () {
      final oneOff = EventModel(
        id: 'dentist',
        title: 'Dentist',
        startTime: DateTime(2026, 9, 9, 15).toUtc(),
        endTime: DateTime(2026, 9, 9, 16).toUtc(),
        habitId: '',
      );

      final summary = week(oneOffOnWednesday: 1).withRepeatingDays([oneOff]);

      expect(summary.totalScheduled, 1, reason: 'not counted a second time');
    });
  });

  group('ApiService.fetchActivitySummary', () {
    test('asks the summary endpoint for the requested number of days', () async {
      RequestOptions? seen;

      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              seen = options;
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: serverResponse(),
                  statusCode: 200,
                ),
              );
            },
          ),
        );

      final summary = await ApiService(dio).fetchActivitySummary(days: 14);

      expect(seen?.method, 'GET');
      expect(seen?.path, '/analytics/summary');
      expect(seen?.queryParameters, {'days': 14});
      expect(summary.totalCompleted, 3);
    });
  });

  group('formatFocusDuration', () {
    final en = AppTranslations(AppLocale.en);
    final vi = AppTranslations(AppLocale.vi);

    test('uses minutes under an hour', () {
      expect(formatFocusDuration(en, 0), '0 min');
      expect(formatFocusDuration(en, 45), '45 min');
      expect(formatFocusDuration(en, 59), '59 min');
    });

    test('drops the minutes on a whole hour', () {
      expect(formatFocusDuration(en, 60), '1h');
      expect(formatFocusDuration(en, 120), '2h');
    });

    test('uses hours and minutes above an hour', () {
      expect(formatFocusDuration(en, 95), '1h 35m');
      expect(formatFocusDuration(en, 2066), '34h 26m');
    });

    test('is translated', () {
      expect(formatFocusDuration(vi, 45), '45 phút');
      expect(formatFocusDuration(vi, 95), '1 giờ 35 phút');
    });
  });
}
