import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';
import 'package:habit_tracker/features/assistant/presentation/providers/assistant_chat_provider.dart';
import 'package:habit_tracker/features/auth/presentation/providers/auth_provider.dart';

/// Listens on the assistant hub while the chat is open, and passes each "tool started"
/// to [assistantChatProvider] — so the chat can say "looking at your calendar…" instead
/// of a silent wait.
///
/// Progress only: the reply itself is the HTTP response, so if the hub cannot connect the
/// chat still works, just without the running commentary. Failures are therefore logged
/// and dropped, never shown.
final assistantProgressProvider = Provider.autoDispose<void>((ref) {
  final api = ref.read(apiServiceProvider);
  final hubUrl = api.dio.options.baseUrl.replaceAll('/api/v1', AppConstants.assistantHubPath);

  final connection = HubConnectionBuilder()
      .withUrl(
        hubUrl,
        options: HttpConnectionOptions(
          accessTokenFactory: () async {
            final token = await ref.read(authProvider.future);
            return token ?? '';
          },
        ),
      )
      .withAutomaticReconnect()
      .build();

  connection.on(AppConstants.assistantToolStartedEvent, (arguments) {
    final payload = arguments?.firstOrNull;
    if (payload is! Map) return;
    final conversationId = payload['conversationId']?.toString();
    final tool = payload['tool']?.toString();
    if (conversationId == null || tool == null) return;
    ref.read(assistantChatProvider.notifier).toolStarted(conversationId, tool);
  });

  connection.start()?.catchError((Object e) {
    debugPrint('Assistant hub: could not connect ($e); replies still arrive, without progress.');
  });

  ref.onDispose(() => connection.stop());
});
