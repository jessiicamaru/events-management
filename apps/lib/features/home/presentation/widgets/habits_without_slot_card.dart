import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';

/// Habits with nothing booked on today's calendar.
///
/// The one thing on this screen the user can act on immediately, and it was not
/// visible anywhere before: the habits list shows every habit regardless of the
/// day, and the calendar shows only what is already scheduled — never the gap
/// between them.
class HabitsWithoutSlotCard extends ConsumerWidget {
  const HabitsWithoutSlotCard({
    super.key,
    required this.habits,
    required this.onTapHabit,
  });

  final List<HabitModel> habits;

  /// Opens the calendar so the habit can be dropped onto a time.
  final ValueChanged<HabitModel> onTapHabit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);

    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            translations.translate('home_habits_without_a_slot'),
            style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (habits.isEmpty)
            Text(
              translations.translate('home_every_habit_has_a_slot'),
              style: theme.textTheme.muted,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final habit in habits)
                  ShadButton.outline(
                    size: ShadButtonSize.sm,
                    onPressed: () => onTapHabit(habit),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.plus, size: 14),
                        const SizedBox(width: 6),
                        Text(habit.name),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
