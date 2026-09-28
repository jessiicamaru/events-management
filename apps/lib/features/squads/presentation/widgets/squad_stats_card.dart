import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/squads/domain/models/squad_model.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/core/utils/level_system.dart';
import 'package:habit_tracker/core/widgets/xp_progress_bar.dart';

class SquadStatsCard extends ConsumerWidget {
  final SquadModel squad;

  const SquadStatsCard({super.key, required this.squad});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);
    final level = LevelSystem.getLevel(squad.totalSquadXP);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.flame, size: 48, color: Colors.orange),
          const SizedBox(height: 16),
          Text(squad.name, style: theme.textTheme.h3),
          const SizedBox(height: 8),
          Text('${translations.translate('total_xp')}: ${squad.totalSquadXP}', style: theme.textTheme.muted),
          const SizedBox(height: 16),
          XpProgressBar(totalXp: squad.totalSquadXP),
          const SizedBox(height: 12),
          Text('${translations.translate('level_label')} $level', style: theme.textTheme.small),
        ],
      ),
    );
  }
}
