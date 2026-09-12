import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.users, size: 64, color: theme.colorScheme.mutedForeground),
            const SizedBox(height: 16),
            Text('No Squad Yet', style: theme.textTheme.h2),
            const SizedBox(height: 8),
            Text(
              'Join a squad to stay accountable and earn more XP together!',
              style: theme.textTheme.muted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ShadButton(
              onPressed: onCreateSquad,
              child: const Text('Create Squad'),
            ),
            const SizedBox(height: 16),
            ShadButton.outline(
              onPressed: onJoinSquad,
              child: const Text('Join with Code'),
            ),
          ],
        ),
      ),
    );
  }
}
