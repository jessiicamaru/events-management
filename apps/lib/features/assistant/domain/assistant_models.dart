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
  tool,

  /// A proposal card. Never stored on the server: the chat places the proposals a tool step
  /// made after the reply that explains them.
  proposal;

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
    this.proposals = const [],
  });

  final AssistantRole role;
  final String? content;
  final String? toolName;
  final DateTime createdAt;

  /// On a tool step that proposed something: the proposals, as they stand now.
  final List<AssistantProposal> proposals;

  factory AssistantMessage.fromJson(Map<String, dynamic> json) => AssistantMessage(
        role: AssistantRole.parse(json['role'] as String?),
        content: json['content'] as String?,
        toolName: json['toolName'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        proposals: AssistantProposal.listFromJson(json['proposals']),
      );
}

/// The answer to one message: the reply, and the tools that ran to produce it.
class AssistantReply {
  const AssistantReply({
    required this.status,
    this.reply,
    this.toolsUsed = const [],
    this.proposals = const [],
  });

  /// The server's turn status: `Completed`, `Truncated`, `Refused` or `StepLimitReached`.
  final String status;
  final String? reply;
  final List<String> toolsUsed;

  /// What the assistant proposed adding this turn — shown as cards under the reply.
  final List<AssistantProposal> proposals;

  factory AssistantReply.fromJson(Map<String, dynamic> json) => AssistantReply(
        status: json['status'] as String? ?? 'Completed',
        reply: json['reply'] as String?,
        toolsUsed: (json['toolsUsed'] as List? ?? const []).cast<String>(),
        proposals: AssistantProposal.listFromJson(json['proposals']),
      );
}

/// Where a proposal stands. Only [pending] offers "Add to calendar".
enum AssistantProposalStatus {
  pending,
  applied,
  dismissed,
  undone;

  static AssistantProposalStatus parse(String? value) => switch (value) {
        'applied' => AssistantProposalStatus.applied,
        'dismissed' => AssistantProposalStatus.dismissed,
        'undone' => AssistantProposalStatus.undone,
        _ => AssistantProposalStatus.pending,
      };
}

/// A day on which a proposed time clashes with something already booked.
class AssistantProposalConflict {
  const AssistantProposalConflict({required this.date, required this.title});

  final DateTime date;
  final String title;
}

/// A repeating session the assistant suggested, waiting for the user's tap. Nothing is on
/// the calendar until [status] is [AssistantProposalStatus.applied].
class AssistantProposal {
  const AssistantProposal({
    required this.id,
    required this.status,
    required this.title,
    required this.start,
    required this.end,
    required this.days,
    required this.firstDate,
    this.conflicts = const [],
    this.habitName,
  });

  final String id;
  final AssistantProposalStatus status;
  final String title;

  /// "HH:mm", local.
  final String start;
  final String end;

  /// 1 = Monday … 7 = Sunday.
  final List<int> days;
  final DateTime firstDate;
  final List<AssistantProposalConflict> conflicts;

  /// The existing habit it joins; null when adding it creates a new habit.
  final String? habitName;

  bool get everyDay => days.length == DateTime.daysPerWeek;

  factory AssistantProposal.fromJson(Map<String, dynamic> json) => AssistantProposal(
        id: json['id'] as String,
        status: AssistantProposalStatus.parse(json['status'] as String?),
        title: json['title'] as String,
        start: json['start'] as String,
        end: json['end'] as String,
        days: (json['days'] as List).cast<int>(),
        firstDate: DateTime.parse(json['firstDate'] as String),
        conflicts: [
          for (final c in (json['conflicts'] as List? ?? const []).cast<Map<String, dynamic>>())
            AssistantProposalConflict(date: DateTime.parse(c['date'] as String), title: c['title'] as String),
        ],
        habitName: json['habitName'] as String?,
      );

  static List<AssistantProposal> listFromJson(Object? value) => [
        for (final json in (value as List? ?? const []).cast<Map<String, dynamic>>()) AssistantProposal.fromJson(json),
      ];
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

  /// Undo refused: a day of the added event already holds the user's own work.
  proposalHasActivity,

  /// The server could not add the proposal, e.g. its category is no longer the user's.
  proposalRefused,

  unknown,
}

/// A request to the assistant that did not produce a reply.
class AssistantException implements Exception {
  const AssistantException(this.failure);

  final AssistantFailure failure;

  @override
  String toString() => 'AssistantException($failure)';
}
