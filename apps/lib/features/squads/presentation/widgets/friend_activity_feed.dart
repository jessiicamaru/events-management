import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class FriendActivityFeed extends StatelessWidget {
  const FriendActivityFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Friend Activity', style: theme.textTheme.h4),
        const SizedBox(height: 16),
        _buildFeedItem(theme, 'Alex completed "Read 20 pages"', '10m ago'),
        _buildFeedItem(theme, 'Sam reached a 5-day streak on "Morning Jog"!', '1h ago', icon: LucideIcons.flame, color: Colors.orange),
        _buildFeedItem(theme, 'Taylor joined Alpha Squad', '2h ago', icon: LucideIcons.userPlus),
      ],
    );
  }

  Widget _buildFeedItem(ShadThemeData theme, String message, String time, {IconData icon = LucideIcons.checkCircle2, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: theme.textTheme.p),
                const SizedBox(height: 4),
                Text(time, style: theme.textTheme.muted.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
