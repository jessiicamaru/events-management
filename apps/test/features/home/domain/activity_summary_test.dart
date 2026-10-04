import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/core/network/api_service.dart';
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
        'totalScheduled': 0,
        'totalCompleted': 0,
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
        'totalScheduled': 0,
        'totalCompleted': 0,
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
