import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';
import 'package:habit_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:habit_tracker/features/auth/presentation/screens/login_screen.dart';
import '../../../../test_utils.dart';

/// Answers the login request with a token, as the real server does on success.
class _TokenIssuingApi implements ApiService {
  @override
  Future<Response> post(String path, {dynamic data}) async => Response(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {'accessToken': 'test-token'},
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Keeps the token in memory. The real notifier writes to secure storage, which is
/// a platform plugin and not available in widget tests.
class _InMemoryAuth extends Auth {
  @override
  Future<String?> build() async => null;

  @override
  Future<void> login(String token) async => state = AsyncData(token);
}

void main() {
  testWidgets('a successful login lands on the home screen', (tester) async {
    // Regression: Home became the landing route in the router's redirect, but the
    // login screen navigated to '/calendar' itself, so that is where users ended up.
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/home', builder: (_, _) => const Text('HOME SCREEN')),
        GoRoute(path: '/calendar', builder: (_, _) => const Text('CALENDAR SCREEN')),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...commonTestOverrides,
          apiServiceProvider.overrideWithValue(_TokenIssuingApi()),
          authProvider.overrideWith(_InMemoryAuth.new),
        ],
        child: ShadApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(ShadInput).at(0), 'dung@gmail.com');
    await tester.enterText(find.byType(ShadInput).at(1), 'Password123!');
    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();

    expect(find.text('HOME SCREEN'), findsOneWidget);
    expect(find.text('CALENDAR SCREEN'), findsNothing);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppConstants.landingRoute,
    );
  });
}
