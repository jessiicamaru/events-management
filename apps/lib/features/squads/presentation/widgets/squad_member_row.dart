import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../domain/models/squad_model.dart';

class SquadMemberRow extends StatelessWidget {
  final SquadMemberModel member;
  final int rank;
  final bool isBuddyMode;
  final VoidCallback? onPoke;

  const SquadMemberRow({
    super.key,
    required this.member,
    required this.rank,
    required this.isBuddyMode,
    this.onPoke,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    String rankIcon = '';
    
    if (!isBuddyMode) {
      if (rank == 1) rankIcon = '🥇 ';
      if (rank == 2) rankIcon = '🥈 ';
      if (rank == 3) rankIcon = '🥉 ';
    }
    
    final name = member.email.split('@').first;
    final emoji = member.unlockedEmojis.isNotEmpty ? member.unlockedEmojis.first : '👍';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.accent.withOpacity(0.1),
      ),
      child: Row(
        children: [
          if (!isBuddyMode)
            SizedBox(
              width: 30,
              child: Text(
                rankIcon.isNotEmpty ? rankIcon : '#$rank',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            child: Text(name[0].toUpperCase(), style: TextStyle(color: theme.colorScheme.primaryForeground)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.large),
                Text('${member.totalXP} XP', style: theme.textTheme.muted),
              ],
            ),
          ),
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          ShadButton.outline(
            onPressed: onPoke,
            child: const Icon(LucideIcons.hand),
          ),
        ],
      ),
    );
  }
}
