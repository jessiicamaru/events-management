import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/localization/locale_provider.dart';

class SquadEmptyState extends ConsumerWidget {
  final VoidCallback onCreateSquad;
  final VoidCallback onJoinSquad;

  const SquadEmptyState({
    super.key,
    required this.onCreateSquad,
    required this.onJoinSquad,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.users, size: 64, color: theme.colorScheme.mutedForeground),
            const SizedBox(height: 16),
            Text(translations.translate('no_squad_yet'), style: theme.textTheme.h2),
            const SizedBox(height: 8),
            Text(
              translations.translate('join_squad_prompt'),
              style: theme.textTheme.muted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ShadButton(
              onPressed: onCreateSquad,
              child: Text(translations.translate('create_squad')),
            ),
            const SizedBox(height: 16),
            ShadButton.outline(
              onPressed: onJoinSquad,
              child: Text(translations.translate('join_with_code')),
            ),
          ],
        ),
      ),
    );
  }
}
