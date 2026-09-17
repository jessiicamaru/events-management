import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/user_profile_provider.dart';
import '../../../../core/localization/locale_provider.dart';

class CosmeticsScreen extends ConsumerWidget {
  const CosmeticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final userProfile = ref.watch(userProfileProvider);
    final translations = ref.watch(translationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(translations.translate('cosmetics_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: userProfile.when(
        data: (profile) {
          final level = (profile.totalXP / 1000).floor() + 1;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileCard(theme, profile.email, level, profile.totalXP, translations),
                const SizedBox(height: 32),
                Text(translations.translate('cosmetics_emojis_title'), style: theme.textTheme.h4),
                const SizedBox(height: 8),
                Text(translations.translate('cosmetics_emojis_desc'), style: theme.textTheme.muted),
                const SizedBox(height: 16),
                _buildEmojiGrid(context, ref, theme, profile.unlockedEmojis, profile.totalXP),
                const SizedBox(height: 32),
                Text(translations.translate('cosmetics_heatmap_colors_title'), style: theme.textTheme.h4),
                const SizedBox(height: 8),
                Text(translations.translate('cosmetics_heatmap_colors_desc'), style: theme.textTheme.muted),
                const SizedBox(height: 16),
                _buildColorGrid(context, ref, theme, profile.avatarBorderColor, profile.totalXP),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${translations.translate('error_heatmap')} $err')),
      ),
    );
  }

  Widget _buildProfileCard(ShadThemeData theme, String email, int level, int xp, AppTranslations translations) {
    final progress = (xp % 1000) / 1000.0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: theme.colorScheme.primary,
            child: Text(email[0].toUpperCase(), style: TextStyle(fontSize: 24, color: theme.colorScheme.primaryForeground)),
          ),
          const SizedBox(height: 16),
          Text(email, style: theme.textTheme.h4),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${translations.translate('level_label')} $level', style: theme.textTheme.small),
              Text('${xp % 1000} / 1000 XP', style: theme.textTheme.small),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiGrid(BuildContext context, WidgetRef ref, ShadThemeData theme, List<String> currentEmojis, int xp) {
    // Define all available emojis and their required XP
    final availableEmojis = [
      {'emoji': '🔥', 'req': 0},
      {'emoji': '👍', 'req': 0},
      {'emoji': '👏', 'req': 0},
      {'emoji': '🚀', 'req': 500},
      {'emoji': '💯', 'req': 1000},
      {'emoji': '👑', 'req': 2000},
      {'emoji': '🏆', 'req': 3000},
      {'emoji': '⚡', 'req': 4000},
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: availableEmojis.map((item) {
        final emoji = item['emoji'] as String;
        final reqXP = item['req'] as int;
        final isUnlocked = xp >= reqXP;
        final isSelected = currentEmojis.contains(emoji);

        return GestureDetector(
          onTap: isUnlocked ? () {
            ref.read(userProfileProvider.notifier).updateCosmetics(unlockedEmojis: [emoji]);
          } : null,
          child: Opacity(
            opacity: isUnlocked ? 1.0 : 0.5,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : theme.colorScheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 32)),
                  if (!isUnlocked)
                    Text('$reqXP XP', style: theme.textTheme.small.copyWith(fontSize: 10)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorGrid(BuildContext context, WidgetRef ref, ShadThemeData theme, String? currentColor, int xp) {
    final availableColors = [
      {'color': '#22c55e', 'req': 0, 'name': 'Green'},
      {'color': '#3b82f6', 'req': 1000, 'name': 'Blue'},
      {'color': '#f59e0b', 'req': 2500, 'name': 'Orange'},
      {'color': '#ec4899', 'req': 5000, 'name': 'Pink'},
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: availableColors.map((item) {
        final colorHex = item['color'] as String;
        final reqXP = item['req'] as int;
        final isUnlocked = xp >= reqXP;
        final isSelected = (currentColor ?? '#22c55e') == colorHex;
        
        final colorValue = int.parse(colorHex.replaceAll('#', '0xFF'));
        final color = Color(colorValue);

        return GestureDetector(
          onTap: isUnlocked ? () {
            ref.read(userProfileProvider.notifier).updateCosmetics(avatarBorderColor: colorHex);
          } : null,
          child: Opacity(
            opacity: isUnlocked ? 1.0 : 0.5,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : theme.colorScheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!isUnlocked)
                    Text('$reqXP XP', style: theme.textTheme.small.copyWith(fontSize: 10)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
