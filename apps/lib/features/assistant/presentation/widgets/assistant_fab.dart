import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';

/// Opens the assistant. Shown by the tab shell, and on the calendar — which has its own
/// "create event" button in the same corner — as a small one stacked above it.
class AssistantFab extends ConsumerWidget {
  const AssistantFab({super.key, this.mini = false});

  final bool mini;

  /// Its own hero tag: the calendar shows it next to another FloatingActionButton, and two
  /// with the default tag on one route make the Hero transition throw.
  static const String heroTag = 'assistant-fab';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final t = ref.watch(translationsProvider);

    return FloatingActionButton(
      heroTag: heroTag,
      mini: mini,
      tooltip: t.translate('assistant_open'),
      backgroundColor: theme.colorScheme.secondary,
      foregroundColor: theme.colorScheme.secondaryForeground,
      shape: const CircleBorder(),
      onPressed: () => context.push(AppConstants.assistantRoute),
      child: Icon(LucideIcons.sparkles, size: mini ? 18 : 22),
    );
  }
}
