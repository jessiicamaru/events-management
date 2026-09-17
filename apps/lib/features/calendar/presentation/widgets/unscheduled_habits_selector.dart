import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../habits/domain/models/habit_model.dart';
import '../../../../core/localization/locale_provider.dart';

class UnscheduledHabitsSelector extends ConsumerWidget {
  final List<HabitModel> habits;
  final HabitModel? selectedHabit;
  final ValueChanged<HabitModel> onSelect;

  const UnscheduledHabitsSelector({
    super.key,
    required this.habits,
    this.selectedHabit,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (habits.isEmpty) return const SizedBox.shrink();

    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translations.translate('unscheduled_habits'),
          style: theme.textTheme.small.copyWith(
            color: theme.colorScheme.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: habits.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final habit = habits[index];
              final isSelected = selectedHabit?.id == habit.id;
              
              String? translatedCategory = habit.category;
              if (habit.category == 'Health') translatedCategory = translations.translate('category_health');
              if (habit.category == 'Work') translatedCategory = translations.translate('category_work');
              if (habit.category == 'Learning') translatedCategory = translations.translate('category_learning');
              if (habit.category == 'Wellness') translatedCategory = translations.translate('category_wellness');

              return GestureDetector(
                onTap: () => onSelect(habit),
                child: SizedBox(
                  width: 140,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.muted,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.border,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          translations.translate(habit.name),
                          style: theme.textTheme.small.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? theme.colorScheme.primary : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (translatedCategory != null)
                          Text(
                            translatedCategory,
                            style: TextStyle(fontSize: 10, color: theme.colorScheme.mutedForeground),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
