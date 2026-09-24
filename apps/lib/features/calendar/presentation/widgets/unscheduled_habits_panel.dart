import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/calendar/presentation/providers/category_filter_provider.dart';
import 'package:habit_tracker/features/calendar/presentation/providers/event_category_provider.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';

class UnscheduledHabitsPanel extends ConsumerWidget {
  final AsyncValue<List<HabitModel>> habitsAsync;
  final bool isDesktop;
  final ValueChanged<HabitModel>? onHabitTapped;

  const UnscheduledHabitsPanel({
    super.key,
    required this.habitsAsync,
    this.isDesktop = true,
    this.onHabitTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final selectedCategory = ref.watch(categoryFilterProvider);
    final translations = ref.watch(translationsProvider);

    return Container(
      width: isDesktop ? 280 : double.infinity,
      decoration: BoxDecoration(
        border: Border(
          left: isDesktop ? BorderSide(color: theme.colorScheme.border) : BorderSide.none,
          top: !isDesktop ? BorderSide(color: theme.colorScheme.border) : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(translations.translate('unscheduled_habits'), style: theme.textTheme.h4),
          ),
          Expanded(
            child: habitsAsync.when(
              data: (habits) {
                final filteredHabits = selectedCategory == null 
                    ? habits 
                    : habits.where((h) => h.categoryId == selectedCategory).toList();
                
                if (filteredHabits.isEmpty) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(translations.translate('no_unscheduled_habits'), textAlign: TextAlign.center),
                  ));
                }
                return ListView.builder(
                  scrollDirection: isDesktop ? Axis.vertical : Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredHabits.length,
                  itemBuilder: (context, index) {
                    final habit = filteredHabits[index];
                    final categoriesAsync = ref.watch(eventCategoriesProvider(squadId: null));
                    String? translatedCategory = translations.translate('uncategorized');
                    if (habit.categoryId != null) {
                       categoriesAsync.whenData((categories) {
                          final cat = categories.where((c) => c.id == habit.categoryId).firstOrNull;
                          if (cat != null) {
                             translatedCategory = cat.name;
                          }
                       });
                    }

                    final content = ShadCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(translations.translate(habit.name), style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(translatedCategory ?? translations.translate('uncategorized'), style: TextStyle(fontSize: 10, color: theme.colorScheme.mutedForeground), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    );

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: isDesktop ? 8.0 : 0,
                        right: !isDesktop ? 8.0 : 0,
                      ),
                      child: Draggable<HabitModel>(
                        data: habit,
                        feedback: Material(
                          color: Colors.transparent,
                          child: SizedBox(width: isDesktop ? 248 : 200, child: content),
                        ),
                        childWhenDragging: Opacity(opacity: 0.5, child: content),
                        child: GestureDetector(
                          onTap: onHabitTapped != null ? () => onHabitTapped!(habit) : null,
                          child: content,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('${translations.translate('error_heatmap')} $err')),
            ),
          ),
        ],
      ),
    );
  }
}
