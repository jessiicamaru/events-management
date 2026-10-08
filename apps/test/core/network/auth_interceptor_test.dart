import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/network/auth_interceptor.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';

/// Answers every request with a fixed status, so the error path taken is Dio's real
/// one: the adapter returns the status, Dio rejects it, and the error interceptors run.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.statusCode);

  final int statusCode;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  /// Builds a Dio wired to the interceptor under test.
  ///
  /// [sent] is the token the request goes out with, [held] the one the session holds by
  /// the time the answer comes back — the two differ exactly in the cases this fix is
  /// about.
  ({Dio dio, _StubAdapter adapter, List<String> expiries}) harness({
    String? sent,
    String? held,
    int statusCode = 401,
  }) {
    final expiries = <String>[];
    final adapter = _StubAdapter(statusCode);
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthInterceptor(
        readToken: () async => sent,
        currentToken: () => held,
        onSessionExpired: () async => expiries.add('logout'),
      ));
    return (dio: dio, adapter: adapter, expiries: expiries);
  }

  group('AuthInterceptor request', () {
    test('sends the bearer token and records the session it belongs to', () async {
      final h = harness(sent: 'token-a', held: 'token-a', statusCode: 200);

      await h.dio.get('/habits');

      final sentRequest = h.adapter.requests.single;
      expect(sentRequest.headers['Authorization'], 'Bearer token-a');
      expect(sentRequest.extra[AppConstants.requestSessionTokenKey], 'token-a');
    });

    test('sends no Authorization header when signed out', () async {
      final h = harness(sent: null, held: null, statusCode: 200);

      await h.dio.get('/habits');

      final sentRequest = h.adapter.requests.single;
      expect(sentRequest.headers.containsKey('Authorization'), isFalse);
      expect(sentRequest.extra[AppConstants.requestSessionTokenKey], isNull);
    });
  });

  group('AuthInterceptor 401', () {
    test('ends the session when the token it currently holds is refused', () async {
      final h = harness(sent: 'token-a', held: 'token-a');

      await expectLater(h.dio.get('/habits'), throwsA(isA<DioException>()));

      expect(h.expiries, ['logout']);
    });

    test('keeps the session when the refused request carried no token', () async {
      // The race this fix is for: the screen fetched before login finished, so the
      // request went out with no token; by the time its 401 came back the user was
      // signed in, and logging out here dropped them back on the login screen.
      final h = harness(sent: null, held: 'token-a');

      await expectLater(h.dio.get('/habits'), throwsA(isA<DioException>()));

      expect(h.expiries, isEmpty);
    });

    test('keeps the session when the refused token is from an earlier one', () async {
      final h = harness(sent: 'token-a', held: 'token-b');

      await expectLater(h.dio.get('/habits'), throwsA(isA<DioException>()));

      expect(h.expiries, isEmpty);
    });

    test('does nothing when already signed out', () async {
      final h = harness(sent: 'token-a', held: null);

      await expectLater(h.dio.get('/habits'), throwsA(isA<DioException>()));

      expect(h.expiries, isEmpty);
    });

    test('leaves the error itself untouched for the caller to handle', () async {
      final h = harness(sent: 'token-a', held: 'token-a');

      await expectLater(
        h.dio.get('/habits'),
        throwsA(isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          AppConstants.unauthorizedStatusCode,
        )),
      );
    });
  });

  group('AuthInterceptor other failures', () {
    test('a 500 never ends the session', () async {
      final h = harness(sent: 'token-a', held: 'token-a', statusCode: 500);

      await expectLater(h.dio.get('/habits'), throwsA(isA<DioException>()));

      expect(h.expiries, isEmpty);
    });

    test('a 403 never ends the session', () async {
      final h = harness(sent: 'token-a', held: 'token-a', statusCode: 403);

      await expectLater(h.dio.get('/habits'), throwsA(isA<DioException>()));

      expect(h.expiries, isEmpty);
    });
  });
}
