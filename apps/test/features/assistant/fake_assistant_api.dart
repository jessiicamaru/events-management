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

  /// Proposal actions the chat asked for, as "apply:id", "dismiss:id", "undo:id".
  final List<String> proposalActions = [];

  /// Thrown by the next proposal action instead of answering.
  AssistantFailure? failNextProposalAction;

  Future<AssistantProposal> _act(String action, String id, AssistantProposalStatus next) async {
    proposalActions.add('$action:$id');
    final failure = failNextProposalAction;
    if (failure != null) {
      failNextProposalAction = null;
      throw AssistantException(failure);
    }
    return proposal(id: id, status: next);
  }

  @override
  Future<AssistantProposal> applyAssistantProposal(String proposalId) =>
      _act('apply', proposalId, AssistantProposalStatus.applied);

  @override
  Future<AssistantProposal> dismissAssistantProposal(String proposalId) =>
      _act('dismiss', proposalId, AssistantProposalStatus.dismissed);

  @override
  Future<AssistantProposal> undoAssistantProposal(String proposalId) =>
      _act('undo', proposalId, AssistantProposalStatus.undone);

  /// A daily 05:00–05:45 run from Tue 29 Sep, as the server proposes it.
  static AssistantProposal proposal({
    String id = 'p1',
    AssistantProposalStatus status = AssistantProposalStatus.pending,
    List<AssistantProposalConflict> conflicts = const [],
    String start = '05:00',
    String end = '05:45',
  }) =>
      AssistantProposal(
        id: id,
        status: status,
        title: 'Chạy bộ',
        start: start,
        end: end,
        days: const [1, 2, 3, 4, 5, 6, 7],
        firstDate: DateTime(2026, 9, 29),
        conflicts: conflicts,
      );

  void reply(
    String text, {
    List<String> tools = const [],
    String status = 'Completed',
    List<AssistantProposal> proposals = const [],
  }) {
    final reply = AssistantReply(status: status, reply: text, toolsUsed: tools, proposals: proposals);
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
