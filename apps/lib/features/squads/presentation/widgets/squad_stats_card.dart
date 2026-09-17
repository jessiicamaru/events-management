import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../domain/models/squad_model.dart';
import '../../../../core/localization/locale_provider.dart';

class SquadStatsCard extends ConsumerWidget {
  final SquadModel squad;

  const SquadStatsCard({super.key, required this.squad});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);
    final level = (squad.totalSquadXP / 1000).floor() + 1;
    final progress = (squad.totalSquadXP % 1000) / 1000.0;

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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text('${translations.translate('level_label')} $level', style: theme.textTheme.small),
        ],
      ),
    );
  }
}
