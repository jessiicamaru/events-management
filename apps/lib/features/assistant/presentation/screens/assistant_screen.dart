import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/assistant/domain/assistant_models.dart';
import 'package:habit_tracker/features/assistant/presentation/assistant_labels.dart';
import 'package:habit_tracker/features/assistant/presentation/providers/assistant_chat_provider.dart';
import 'package:habit_tracker/features/assistant/presentation/providers/assistant_progress_provider.dart';
import 'package:habit_tracker/features/assistant/presentation/providers/assistant_settings_provider.dart';
import 'package:habit_tracker/features/assistant/presentation/widgets/assistant_composer.dart';
import 'package:habit_tracker/features/assistant/presentation/widgets/assistant_consent_view.dart';
import 'package:habit_tracker/features/assistant/presentation/widgets/assistant_empty_state.dart';
import 'package:habit_tracker/features/assistant/presentation/widgets/assistant_message_bubble.dart';
import 'package:habit_tracker/features/assistant/presentation/widgets/assistant_tool_step.dart';
import 'package:habit_tracker/features/assistant/presentation/widgets/assistant_typing_indicator.dart';

/// The assistant: consent first, then the chat.
class AssistantScreen extends ConsumerWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final settings = ref.watch(assistantSettingsProvider);
    final enabled = settings.value?.assistantEnabled ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('assistant_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [if (enabled) const _ChatMenu()],
      ),
      body: settings.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Message(
          text: t.translate('assistant_load_error'),
          actionLabel: t.translate('assistant_retry'),
          onAction: () => ref.invalidate(assistantSettingsProvider),
        ),
        data: (s) {
          if (!s.serverConfigured) return _Message(text: t.translate('assistant_not_configured'));
          if (!s.assistantEnabled) {
            return AssistantConsentView(
              busy: settings.isLoading,
              onAccept: () => ref.read(assistantSettingsProvider.notifier).setEnabled(true),
            );
          }
          return const _ChatView();
        },
      ),
    );
  }
}

class _ChatMenu extends ConsumerWidget {
  const _ChatMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final sending = ref.watch(assistantChatProvider.select((s) => s.sending));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: t.translate('assistant_new_chat'),
          icon: const Icon(LucideIcons.squarePen),
          onPressed: sending ? null : () => ref.read(assistantChatProvider.notifier).startNewConversation(),
        ),
        PopupMenuButton<void>(
          itemBuilder: (_) => [
            PopupMenuItem<void>(
              onTap: () => ref.read(assistantSettingsProvider.notifier).setEnabled(false),
              child: Text(t.translate('assistant_turn_off')),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChatView extends ConsumerStatefulWidget {
  const _ChatView();

  @override
  ConsumerState<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<_ChatView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(assistantChatProvider.notifier).load());
  }

  void _send(String text) {
    ref.read(assistantChatProvider.notifier).send(text);
  }

  @override
  Widget build(BuildContext context) {
    // Progress over the hub, only while the chat is on screen.
    ref.watch(assistantProgressProvider);

    final t = ref.watch(translationsProvider);
    final theme = ShadTheme.of(context);
    final chat = ref.watch(assistantChatProvider);

    ref.listen(assistantChatProvider.select((s) => s.failure), (_, failure) {
      // Turned off elsewhere — re-read the settings so the consent screen comes back.
      if (failure == AssistantFailure.disabled) ref.invalidate(assistantSettingsProvider);
    });

    final Widget body;
    if (chat.loading && chat.messages.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (chat.messages.isEmpty && !chat.sending) {
      body = AssistantEmptyState(onSuggestion: _send);
    } else {
      // Newest at the bottom: the list is reversed, so index 0 is the latest entry.
      final entries = [
        ...chat.messages.map((m) => _entry(t, m)),
        if (chat.sending) AssistantTypingIndicator(label: AssistantLabels.running(t, chat.activeTool)),
      ].reversed.toList();
      body = ListView.builder(
        reverse: true,
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (_, i) => entries[i],
      );
    }

    final banner = chat.failure != null
        ? AssistantLabels.failure(t, chat.failure!)
        : chat.notice != null
            ? AssistantLabels.notice(t, chat.notice!)
            : null;

    return Column(
      children: [
        Expanded(child: body),
        if (banner != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: (chat.failure != null ? theme.colorScheme.destructive : theme.colorScheme.muted)
                .withValues(alpha: 0.12),
            child: Text(
              banner,
              style: theme.textTheme.small.copyWith(
                color: chat.failure != null ? theme.colorScheme.destructive : theme.colorScheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        AssistantComposer(busy: chat.sending, onSend: _send),
      ],
    );
  }

  Widget _entry(AppTranslations t, AssistantMessage m) => switch (m.role) {
        AssistantRole.tool => AssistantToolStep(label: AssistantLabels.done(t, m.toolName ?? '')),
        AssistantRole.user => AssistantMessageBubble(text: m.content ?? '', fromUser: true),
        AssistantRole.assistant => AssistantMessageBubble(text: m.content ?? '', fromUser: false),
      };
}

/// A centred line of text, with an optional button under it.
class _Message extends StatelessWidget {
  const _Message({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: theme.textTheme.muted, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              ShadButton.outline(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
