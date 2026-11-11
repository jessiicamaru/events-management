import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/assistant/domain/assistant_models.dart';
import 'package:habit_tracker/features/assistant/presentation/assistant_labels.dart';

/// A session the assistant suggested, with the only way it reaches the calendar: the user's
/// tap on "Add to calendar". Once added, the same card can take it back.
class AssistantProposalCard extends ConsumerWidget {
  const AssistantProposalCard({
    super.key,
    required this.proposal,
    required this.busy,
    required this.onAdd,
    required this.onDismiss,
    required this.onUndo,
  });

  final AssistantProposal proposal;

  /// A tap on this card is being handled; its buttons wait.
  final bool busy;
  final VoidCallback onAdd;
  final VoidCallback onDismiss;
  final VoidCallback onUndo;

  /// Clashing event names listed on the card; the day count covers the rest.
  static const int _maxClashTitles = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final t = ref.watch(translationsProvider);
    final p = proposal;
    final clashTitles = p.conflicts.map((c) => c.title).toSet().take(_maxClashTitles).join(', ');

    Widget line(IconData icon, String text, {Color? color}) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(icon, size: 15, color: color ?? theme.colorScheme.mutedForeground),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: theme.textTheme.small.copyWith(color: color))),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ShadCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.calendarPlus, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(p.title, style: theme.textTheme.large)),
              ],
            ),
            line(LucideIcons.clock, '${AssistantLabels.days(t, p.days)} · ${p.start}–${p.end}'),
            line(LucideIcons.calendarDays,
                t.translate('assistant_proposal_from', params: {'date': AssistantLabels.date(t, p.firstDate)})),
            line(
              LucideIcons.repeat,
              p.habitName == null
                  ? t.translate('assistant_proposal_new_habit')
                  : t.translate('assistant_proposal_on_habit', params: {'habit': p.habitName!}),
            ),
            p.conflicts.isEmpty
                ? line(LucideIcons.circleCheck, t.translate('assistant_proposal_no_clash'))
                : line(
                    LucideIcons.triangleAlert,
                    t.translate('assistant_proposal_clashes',
                        params: {'n': '${p.conflicts.length}', 'titles': clashTitles}),
                    color: theme.colorScheme.destructive,
                  ),
            const SizedBox(height: 12),
            _Actions(proposal: p, busy: busy, onAdd: onAdd, onDismiss: onDismiss, onUndo: onUndo),
          ],
        ),
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({
    required this.proposal,
    required this.busy,
    required this.onAdd,
    required this.onDismiss,
    required this.onUndo,
  });

  final AssistantProposal proposal;
  final bool busy;
  final VoidCallback onAdd;
  final VoidCallback onDismiss;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final t = ref.watch(translationsProvider);

    Widget status(IconData icon, String key) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.mutedForeground),
            const SizedBox(width: 6),
            Text(t.translate(key), style: theme.textTheme.muted),
          ],
        );

    return switch (proposal.status) {
      AssistantProposalStatus.pending => Row(
          children: [
            Expanded(
              child: ShadButton(
                onPressed: busy ? null : onAdd,
                leading: busy
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(LucideIcons.plus, size: 16),
                child: Text(t.translate('assistant_proposal_add')),
              ),
            ),
            const SizedBox(width: 8),
            ShadButton.outline(
              onPressed: busy ? null : onDismiss,
              child: Text(t.translate('assistant_proposal_dismiss')),
            ),
          ],
        ),
      AssistantProposalStatus.applied => Row(
          children: [
            Icon(LucideIcons.circleCheck, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(child: Text(t.translate('assistant_proposal_added'), style: theme.textTheme.small)),
            ShadButton.ghost(
              size: ShadButtonSize.sm,
              onPressed: busy ? null : onUndo,
              child: Text(t.translate('assistant_proposal_undo')),
            ),
          ],
        ),
      AssistantProposalStatus.dismissed => status(LucideIcons.x, 'assistant_proposal_dismissed'),
      AssistantProposalStatus.undone => status(LucideIcons.undo2, 'assistant_proposal_undone'),
    };
  }
}
