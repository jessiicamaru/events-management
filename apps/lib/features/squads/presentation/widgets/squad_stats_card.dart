import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../domain/models/squad_model.dart';

class SquadStatsCard extends StatelessWidget {
  final SquadModel squad;

  const SquadStatsCard({super.key, required this.squad});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
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
          Text('Total XP: ${squad.totalSquadXP}', style: theme.textTheme.muted),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text('Level $level', style: theme.textTheme.small),
        ],
      ),
    );
  }
}
