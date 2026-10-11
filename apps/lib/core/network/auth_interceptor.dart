import 'package:dio/dio.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';

/// Attaches the bearer token to every request, and ends the session when the server
/// rejects it.
///
/// The rule for that second part is narrower than it looks: a 401 ends the session only
/// when the request that was refused carried **the token the session currently holds**.
///
/// Logging out on any 401 at all meant a request that had gone out before the user was
/// signed in could log them straight back out again. The calendar and habits screens
/// fetch as soon as they are built, which is while login is still in flight, so those
/// requests carry no token; their 401s came back a moment *after* the token was stored
/// and tore the fresh session down — login succeeded and the app returned to the login
/// screen. It is a race, so it only happened sometimes, which is what made the E2E suite
/// flaky and would have shown up for a real user on a slow connection.
///
/// A request that carried no token, or one from a session that has since ended, says
/// nothing about whether the token held *now* is still good, so neither ends the session.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.readToken,
    required this.currentToken,
    required this.onSessionExpired,
  });

  /// The token to send, awaited per request; null when signed out.
  final Future<String?> Function() readToken;

  /// The token held right now, read without waiting — what a 401 is judged against.
  final String? Function() currentToken;

  /// Called when the current session's own token is refused.
  final Future<void> Function() onSessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await readToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    // Record which session this request belongs to, so its response can be attributed
    // to one. The header alone would not do: it is gone from a redirect, and reading it
    // back means re-parsing the 'Bearer ' prefix.
    options.extra[AppConstants.requestSessionTokenKey] = token;
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == AppConstants.unauthorizedStatusCode &&
        _refusedTheCurrentSession(err.requestOptions)) {
      await onSessionExpired();
    }
    handler.next(err);
  }

  bool _refusedTheCurrentSession(RequestOptions options) {
    final sentWith = options.extra[AppConstants.requestSessionTokenKey];
    // Not a string: the request went out with no token, or never passed through
    // [onRequest] at all. Either way it was not this session being refused.
    if (sentWith is! String) return false;
    final current = currentToken();
    // Already signed out, or signed in again since: nothing left for this to end.
    return current != null && current == sentWith;
  }
}
