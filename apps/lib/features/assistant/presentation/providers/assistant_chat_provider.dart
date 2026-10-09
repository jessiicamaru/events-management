import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/assistant/domain/assistant_models.dart';
import 'package:habit_tracker/features/auth/presentation/providers/auth_provider.dart';

/// Something about the last reply worth saying, although it did arrive.
enum AssistantNotice {
  /// The reply hit the length limit and stops mid-way.
  truncated,

  /// The model declined to answer.
  refused,

  /// The assistant took too many steps and gave up before answering.
  stepLimit,
}

class AssistantChatState {
  const AssistantChatState({
    this.conversationId,
    this.messages = const [],
    this.loading = false,
    this.loaded = false,
    this.sending = false,
    this.activeTool,
    this.failure,
    this.notice,
  });

  /// Null until the first message of a new conversation is sent.
  final String? conversationId;
  final List<AssistantMessage> messages;
  final bool loading;
  final bool loaded;

  /// A turn is running on the server.
  final bool sending;

  /// The tool the server reported running, while [sending].
  final String? activeTool;

  /// Why the last request failed; cleared by the next one.
  final AssistantFailure? failure;
  final AssistantNotice? notice;

  AssistantChatState copyWith({
    String? conversationId,
    bool clearConversation = false,
    List<AssistantMessage>? messages,
    bool? loading,
    bool? loaded,
    bool? sending,
    String? activeTool,
    bool clearActiveTool = false,
    AssistantFailure? failure,
    bool clearFailure = false,
    AssistantNotice? notice,
    bool clearNotice = false,
  }) {
    return AssistantChatState(
      conversationId: clearConversation ? null : conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      loaded: loaded ?? this.loaded,
      sending: sending ?? this.sending,
      activeTool: clearActiveTool ? null : activeTool ?? this.activeTool,
      failure: clearFailure ? null : failure ?? this.failure,
      notice: clearNotice ? null : notice ?? this.notice,
    );
  }
}

/// The open conversation with the assistant.
///
/// Kept for the whole session rather than auto-disposed, so leaving the chat and coming
/// back — or a reply that arrives after the screen closed — loses nothing. It watches the
/// token, so a different account starts from its own history.
final assistantChatProvider =
    NotifierProvider<AssistantChatNotifier, AssistantChatState>(AssistantChatNotifier.new);

class AssistantChatNotifier extends Notifier<AssistantChatState> {
  @override
  AssistantChatState build() {
    ref.watch(authProvider);
    return const AssistantChatState();
  }

  /// Opens the most recent conversation, once per session.
  Future<void> load() async {
    if (state.loaded || state.loading) return;
    state = state.copyWith(loading: true, clearFailure: true);

    try {
      final api = ref.read(apiServiceProvider);
      final id = await api.fetchLatestAssistantConversationId();
      final messages = id == null ? const <AssistantMessage>[] : await api.fetchAssistantMessages(id);
      if (!ref.mounted) return;
      state = state.copyWith(conversationId: id, messages: messages, loading: false, loaded: true);
    } on AssistantException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(loading: false, failure: e.failure);
    }
  }

  /// Sends [text] and waits for the reply. The message shows at once; the reply, and a
  /// step for each tool the assistant ran, follow when the turn ends.
  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;

    state = state.copyWith(
      messages: [
        ...state.messages,
        AssistantMessage(role: AssistantRole.user, content: trimmed, createdAt: clock.now()),
      ],
      sending: true,
      clearActiveTool: true,
      clearFailure: true,
      clearNotice: true,
    );

    try {
      final api = ref.read(apiServiceProvider);
      final id = state.conversationId ?? await api.createAssistantConversation();
      if (!ref.mounted) return;
      state = state.copyWith(conversationId: id);

      final reply = await api.sendAssistantMessage(id, trimmed);
      if (!ref.mounted) return;

      final at = clock.now();
      state = state.copyWith(
        messages: [
          ...state.messages,
          for (final tool in reply.toolsUsed)
            AssistantMessage(role: AssistantRole.tool, toolName: tool, createdAt: at),
          if (reply.reply?.trim().isNotEmpty ?? false)
            AssistantMessage(role: AssistantRole.assistant, content: reply.reply, createdAt: at),
        ],
        sending: false,
        clearActiveTool: true,
        notice: _noticeFor(reply.status),
      );
    } on AssistantException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        sending: false,
        clearActiveTool: true,
        failure: e.failure,
        // Gone on the server: the next message starts a new one instead of failing again.
        clearConversation: e.failure == AssistantFailure.conversationNotFound,
      );
    }
  }

  /// The server began running [tool] for this conversation's turn.
  void toolStarted(String conversationId, String tool) {
    if (!state.sending || conversationId != state.conversationId) return;
    state = state.copyWith(activeTool: tool);
  }

  /// Starts afresh. The new conversation is created on the server with its first message.
  void startNewConversation() {
    if (state.sending) return;
    state = const AssistantChatState(loaded: true);
  }

  static AssistantNotice? _noticeFor(String status) => switch (status) {
        'Truncated' => AssistantNotice.truncated,
        'Refused' => AssistantNotice.refused,
        'StepLimitReached' => AssistantNotice.stepLimit,
        _ => null,
      };
}
