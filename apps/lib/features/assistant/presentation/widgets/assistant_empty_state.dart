import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/assistant/presentation/assistant_labels.dart';

/// An empty conversation: what the assistant can do, and a few questions to start with.
class AssistantEmptyState extends ConsumerWidget {
  const AssistantEmptyState({super.key, required this.onSuggestion});

  /// Called with the suggestion's text when one is tapped.
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final t = ref.watch(translationsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(LucideIcons.sparkles, size: 36, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(t.translate('assistant_empty_title'), style: theme.textTheme.h4, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(t.translate('assistant_empty_body'), style: theme.textTheme.muted, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final key in AssistantLabels.suggestionKeys)
                ShadButton.outline(
                  size: ShadButtonSize.sm,
                  onPressed: () => onSuggestion(t.translate(key)),
                  child: Text(t.translate(key)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
