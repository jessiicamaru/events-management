import 'dart:async';

import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/assistant/domain/assistant_models.dart';

/// The assistant's endpoints, scripted. Everything else on [ApiService] is unused here.
class FakeAssistantApi implements ApiService {
  FakeAssistantApi({
    this.settings = const AssistantSettings(assistantEnabled: true, alwaysConfirm: false, serverConfigured: true),
    this.latestConversationId,
    this.history = const [],
  });

  AssistantSettings settings;
  String? latestConversationId;
  List<AssistantMessage> history;

  /// A send waits here until the test calls [reply], so a test can look at the chat
  /// mid-turn. Created by the send itself, inside the test's zone: a Completer made in
  /// setUp lives outside a widget test's fake-async zone, so completing it resumed the
  /// provider on the real microtask queue, which `pump` does not drain.
  Completer<AssistantReply>? _waiting;

  /// A reply given before anything was sent; the next send returns it at once.
  AssistantReply? _queued;

  /// Thrown by the next send instead of replying.
  AssistantFailure? failNextSend;

  /// Thrown by the settings request.
  AssistantFailure? failSettings;

  final List<({String conversationId, String text})> sent = [];
  int conversationsCreated = 0;
  final List<bool> settingsUpdates = [];

  void reply(String text, {List<String> tools = const [], String status = 'Completed'}) {
    final reply = AssistantReply(status: status, reply: text, toolsUsed: tools);
    final waiting = _waiting;
    if (waiting == null) {
      _queued = reply;
    } else {
      _waiting = null;
      waiting.complete(reply);
    }
  }

  @override
  Future<AssistantSettings> fetchAssistantSettings() async {
    if (failSettings != null) throw AssistantException(failSettings!);
    return settings;
  }

  @override
  Future<AssistantSettings> updateAssistantSettings({required bool enabled, required bool alwaysConfirm}) async {
    settingsUpdates.add(enabled);
    settings = AssistantSettings(
      assistantEnabled: enabled,
      alwaysConfirm: alwaysConfirm,
      serverConfigured: settings.serverConfigured,
    );
    return settings;
  }

  @override
  Future<String?> fetchLatestAssistantConversationId() async => latestConversationId;

  @override
  Future<String> createAssistantConversation() async {
    conversationsCreated++;
    return 'conversation-$conversationsCreated';
  }

  @override
  Future<List<AssistantMessage>> fetchAssistantMessages(String conversationId) async => history;

  @override
  Future<AssistantReply> sendAssistantMessage(String conversationId, String text) async {
    sent.add((conversationId: conversationId, text: text));
    final failure = failNextSend;
    if (failure != null) {
      failNextSend = null;
      throw AssistantException(failure);
    }
    final queued = _queued;
    if (queued != null) {
      _queued = null;
      return queued;
    }
    return (_waiting = Completer<AssistantReply>()).future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
