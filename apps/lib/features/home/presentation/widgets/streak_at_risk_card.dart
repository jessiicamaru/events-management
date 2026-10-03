import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/habits/domain/streak_at_risk.dart';

/// Habits whose streak will break tonight unless they are done.
///
/// Shown only when the day is running out (`StreakAtRisk`), and only for habits with a
/// streak to lose. Outside those hours the screen says nothing about them, which is the
/// difference between a nudge and a scold.
class StreakAtRiskCard extends ConsumerWidget {
  const StreakAtRiskCard({
    super.key,
    required this.atRisk,
    required this.onTapHabit,
  });

  final List<HabitAtRisk> atRisk;

  /// Called with the row that was tapped. Every row is today's, so the caller has nowhere
  /// else to send them than today — the habit is passed so a future destination (the
  /// occurrence itself, rather than the day) does not need the signature changed.
  final ValueChanged<HabitAtRisk> onTapHabit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);

    if (atRisk.isEmpty) return const SizedBox.shrink();

    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.flame, size: 16, color: theme.colorScheme.destructive),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  translations.translate('home_streak_at_risk'),
                  style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final habit in atRisk) _AtRiskRow(habit: habit, onTap: onTapHabit),
        ],
      ),
    );
  }
}

class _AtRiskRow extends ConsumerWidget {
  const _AtRiskRow({required this.habit, required this.onTap});

  final HabitAtRisk habit;
  final ValueChanged<HabitAtRisk> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);
    final start = habit.occurrence.startTime.toLocal();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onTap(habit),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.habit.name, style: theme.textTheme.small),
                    Text(
                      translations.translate(
                        'home_streak_days',
                        params: {'n': '${habit.streak}'},
                      ),
                      style: theme.textTheme.muted,
                    ),
                  ],
                ),
              ),
              Text(
                TimeOfDay.fromDateTime(start).format(context),
                style: theme.textTheme.muted,
              ),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronRight, size: 16, color: theme.colorScheme.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}
