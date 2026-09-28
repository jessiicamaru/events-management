import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/core/utils/level_system.dart';
import 'package:habit_tracker/core/widgets/xp_progress_bar.dart';

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
          final level = LevelSystem.getLevel(profile.totalXP);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileCard(context, theme, profile.email, level, profile.totalXP, profile.currentStreak, translations),
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

  Widget _buildProfileCard(BuildContext context, ShadThemeData theme, String email, int level, int xp, int streak, AppTranslations translations) {
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
              Row(
                children: [
                  Text('${translations.translate('level_label')} $level', style: theme.textTheme.small),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _showLevelTableDialog(context, translations),
                    child: Icon(
                      LucideIcons.info,
                      size: 14,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(LucideIcons.flame, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '$streak ${translations.translate('days_count')}',
                    style: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          XpProgressBar(totalXp: xp),
        ],
      ),
    );
  }

  void _showLevelTableDialog(BuildContext context, AppTranslations translations) {
    showDialog(
      context: context,
      builder: (ctx) => ShadDialog(
        title: Text(translations.translate('level_xp_table_title')),
        description: Text(translations.translate('level_xp_table_desc')),
        actions: [
          ShadButton(
            child: Text(translations.translate('close_button')),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              SizedBox(
                height: 350,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: 29, // Level 1 to 30 transition rows
                  itemBuilder: (context, index) {
                    final lvl = index + 1;
                    final xpDiff = LevelSystem.getXpDiffForLevel(lvl);
                    final cumulative = LevelSystem.getXpForLevelStart(lvl + 1);
                    
                    final prefix = translations.translate('level_prefix');
                    final totalLabel = translations.translate('total_label');
                    
                    return _buildLevelRow(
                      '$prefix $lvl ➔ $prefix ${lvl + 1}',
                      '$xpDiff XP',
                      '$totalLabel: $cumulative XP',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelRow(String title, String xpNeeded, String cumulative) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(xpNeeded, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(cumulative, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
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
                color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.card,
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
                color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.card,
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
