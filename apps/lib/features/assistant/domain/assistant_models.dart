/// The user's assistant settings, as `GET /assistant/settings` returns them.
class AssistantSettings {
  const AssistantSettings({
    required this.assistantEnabled,
    required this.alwaysConfirm,
    required this.serverConfigured,
    this.consentedAt,
  });

  final bool assistantEnabled;
  final bool alwaysConfirm;

  /// False when the server has no model configured: the assistant cannot answer anyone.
  final bool serverConfigured;
  final DateTime? consentedAt;

  factory AssistantSettings.fromJson(Map<String, dynamic> json) => AssistantSettings(
        assistantEnabled: json['assistantEnabled'] as bool? ?? false,
        alwaysConfirm: json['alwaysConfirm'] as bool? ?? false,
        serverConfigured: json['serverConfigured'] as bool? ?? true,
        consentedAt: json['consentedAt'] == null ? null : DateTime.parse(json['consentedAt'] as String),
      );
}

/// Who wrote a message, as the server stores it.
enum AssistantRole {
  user,
  assistant,

  /// A tool the assistant ran — shown as a small step, never with its raw result.
  tool;

  static AssistantRole parse(String? value) => switch (value) {
        'user' => AssistantRole.user,
        'tool' => AssistantRole.tool,
        _ => AssistantRole.assistant,
      };
}

/// One entry of a conversation.
class AssistantMessage {
  const AssistantMessage({
    required this.role,
    required this.createdAt,
    this.content,
    this.toolName,
  });

  final AssistantRole role;
  final String? content;
  final String? toolName;
  final DateTime createdAt;

  factory AssistantMessage.fromJson(Map<String, dynamic> json) => AssistantMessage(
        role: AssistantRole.parse(json['role'] as String?),
        content: json['content'] as String?,
        toolName: json['toolName'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// The answer to one message: the reply, and the tools that ran to produce it.
class AssistantReply {
  const AssistantReply({required this.status, this.reply, this.toolsUsed = const []});

  /// The server's turn status: `Completed`, `Truncated`, `Refused` or `StepLimitReached`.
  final String status;
  final String? reply;
  final List<String> toolsUsed;

  factory AssistantReply.fromJson(Map<String, dynamic> json) => AssistantReply(
        status: json['status'] as String? ?? 'Completed',
        reply: json['reply'] as String?,
        toolsUsed: (json['toolsUsed'] as List? ?? const []).cast<String>(),
      );
}

/// Why the assistant could not answer. Each has its own wording in the app.
enum AssistantFailure {
  /// The server has no model configured (503).
  notConfigured,

  /// The user has not turned the assistant on (403).
  disabled,

  /// The day's message allowance is used up (429).
  dailyLimit,

  /// The model provider failed or timed out (502).
  modelUnavailable,

  /// The conversation is gone (404).
  conversationNotFound,

  /// No answer from the server at all: offline, or it took too long.
  network,

  unknown,
}

/// A request to the assistant that did not produce a reply.
class AssistantException implements Exception {
  const AssistantException(this.failure);

  final AssistantFailure failure;

  @override
  String toString() => 'AssistantException($failure)';
}
