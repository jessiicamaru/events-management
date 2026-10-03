import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/network/api_service.dart';

/// The request bodies of the per-day calls, checked at the wire.
///
/// Every widget test fakes [ApiService] as a whole, so without these a renamed JSON key
/// would pass the whole suite and 404 against the real server — the same class of bug
/// that silently dropped reminder edits.
void main() {
  late RequestOptions? seen;
  late Object? reply;

  ApiService api() {
    seen = null;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            seen = options;
            handler.resolve(Response(requestOptions: options, statusCode: 200, data: reply));
          },
        ),
      );
    return ApiService(dio);
  }

  final friday = DateTime.utc(2026, 9, 11, 10);

  group('completeSession', () {
    setUp(() => reply = null);

    test('sends which day of a series the session was for, in UTC', () async {
      await api().completeSession(
        'jog',
        '00:25:00',
        true,
        occurrenceStart: DateTime(2026, 9, 11, 17), // local time on the device
      );

      expect(seen?.method, 'PUT');
      expect(seen?.path, '/events/jog/complete-session');
      final body = seen?.data as Map;
      expect(body['actualDuration'], '00:25:00');
      expect(body['updateCalendar'], true);
      expect(body['occurrenceStart'], DateTime(2026, 9, 11, 17).toUtc().toIso8601String());
      expect((body['occurrenceStart'] as String).endsWith('Z'), isTrue);
    });

    test('sends no day at all for an ordinary event', () async {
      await api().completeSession('single', '00:25:00', false);

      expect((seen?.data as Map).containsKey('occurrenceStart'), isFalse,
          reason: 'absent, not null — the server reads absent as "not a series day"');
    });
  });

  group('materializeOccurrence', () {
    test('posts the day and returns the new event id', () async {
      reply = 'f87a9ec1-730c-4925-82b9-b7cdc6feaf55'; // a bare JSON string, as the server sends a Guid

      final id = await api().materializeOccurrence('jog', friday);

      expect(seen?.method, 'POST');
      expect(seen?.path, '/events/jog/occurrences');
      expect(seen?.data, {'occurrenceStart': '2026-09-11T10:00:00.000Z'});
      expect(id, 'f87a9ec1-730c-4925-82b9-b7cdc6feaf55');
    });
  });
}
