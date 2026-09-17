import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/localization/locale_provider.dart';

class FriendActivityFeed extends ConsumerWidget {
  const FriendActivityFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(translations.translate('friend_activity'), style: theme.textTheme.h4),
        const SizedBox(height: 16),
        _buildFeedItem(theme, translations.translate('mock_activity_1'), translations.translate('mock_time_1')),
        _buildFeedItem(theme, translations.translate('mock_activity_2'), translations.translate('mock_time_2'), icon: LucideIcons.flame, color: Colors.orange),
        _buildFeedItem(theme, translations.translate('mock_activity_3'), translations.translate('mock_time_3'), icon: LucideIcons.userPlus),
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
