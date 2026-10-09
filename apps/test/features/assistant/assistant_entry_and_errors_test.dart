import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/core/routing/app_router.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';
import 'package:habit_tracker/features/assistant/domain/assistant_models.dart';
import 'package:habit_tracker/features/assistant/presentation/widgets/assistant_fab.dart';
import '../../test_utils.dart';

void main() {
  group('the button that opens the assistant', () {
    Future<GoRouter> shellAt(WidgetTester tester, String location) async {
      final router = GoRouter(
        initialLocation: location,
        routes: [
          ShellRoute(
            builder: (context, state, child) => ScaffoldWithNavBar(child: child),
            routes: [
              for (final path in ['/home', '/calendar', '/habits'])
                GoRoute(path: path, builder: (_, _) => Text('tab $path')),
            ],
          ),
          GoRoute(path: AppConstants.assistantRoute, builder: (_, _) => const Text('assistant screen')),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        overrides: commonTestOverrides,
        child: ShadApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('is on the tabs, and opens the assistant', (tester) async {
      await shellAt(tester, '/home');

      expect(find.byType(AssistantFab), findsOneWidget);

      await tester.tap(find.byType(AssistantFab));
      await tester.pumpAndSettle();

      expect(find.text('assistant screen'), findsOneWidget);
    });

    testWidgets('is left to the calendar on its own tab, which already has a button in that corner',
        (tester) async {
      await shellAt(tester, '/calendar');

      expect(find.byType(AssistantFab), findsNothing);
    });
  });

  group('assistantFailureOf', () {
    DioException withStatus(int code) => DioException(
          requestOptions: RequestOptions(path: '/assistant'),
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: RequestOptions(path: '/assistant'), statusCode: code),
        );

    test('reads why the server refused from the status code', () {
      expect(assistantFailureOf(withStatus(503)), AssistantFailure.notConfigured);
      expect(assistantFailureOf(withStatus(403)), AssistantFailure.disabled);
      expect(assistantFailureOf(withStatus(429)), AssistantFailure.dailyLimit);
      expect(assistantFailureOf(withStatus(502)), AssistantFailure.modelUnavailable);
      expect(assistantFailureOf(withStatus(404)), AssistantFailure.conversationNotFound);
      expect(assistantFailureOf(withStatus(500)), AssistantFailure.unknown);
    });

    test('treats no answer at all as a network problem', () {
      for (final type in [DioExceptionType.receiveTimeout, DioExceptionType.connectionTimeout, DioExceptionType.connectionError]) {
        expect(
          assistantFailureOf(DioException(requestOptions: RequestOptions(path: '/assistant'), type: type)),
          AssistantFailure.network,
          reason: '$type',
        );
      }
    });
  });

  test('a turn may take far longer than the app-wide receive timeout', () {
    // The model and its tools run inside the request; at the app-wide 3 s every turn failed.
    expect(AppConstants.assistantReceiveTimeoutSeconds, greaterThan(AppConstants.receiveTimeoutSeconds * 10));
  });
}
