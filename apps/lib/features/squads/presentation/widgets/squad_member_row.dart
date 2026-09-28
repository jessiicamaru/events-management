import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/squads/domain/models/squad_model.dart';

class SquadMemberRow extends StatelessWidget {
  final SquadMemberModel member;
  final int rank;
  final bool isBuddyMode;
  final List<String> currentUserEmojis;
  final VoidCallback? onPoke;
  final ValueChanged<String>? onReact;

  const SquadMemberRow({
    super.key,
    required this.member,
    required this.rank,
    required this.isBuddyMode,
    required this.currentUserEmojis,
    this.onPoke,
    this.onReact,
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
    
    final name = member.nickname ?? member.email.split('@').first;
    final emoji = member.unlockedEmojis.isNotEmpty ? member.unlockedEmojis.first : '👍';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.accent.withValues(alpha: 0.1),
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
          
          // Avatar with custom unlocked border color
          Container(
            padding: const EdgeInsets.all(2), // spacing between border and avatar
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: member.avatarBorderColor != null && member.avatarBorderColor!.startsWith('#')
                    ? Color(int.parse(member.avatarBorderColor!.replaceAll('#', '0xFF')))
                    : Colors.transparent,
                width: member.avatarBorderColor != null ? 3.0 : 0.0,
              ),
            ),
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(color: theme.colorScheme.primaryForeground),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.large),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('${member.totalXP} XP', style: theme.textTheme.muted),
                    if (member.currentStreak > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.flame, size: 12, color: Colors.orange),
                            const SizedBox(width: 2),
                            Text(
                              '${member.currentStreak}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Popup menu for emoji reactions
          if (onReact != null && currentUserEmojis.isNotEmpty)
            PopupMenuButton<String>(
              icon: Text(emoji, style: const TextStyle(fontSize: 22)),
              tooltip: 'Thả biểu cảm',
              onSelected: onReact,
              itemBuilder: (context) => currentUserEmojis.map((e) => PopupMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(fontSize: 24)),
              )).toList(),
            )
          else
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
