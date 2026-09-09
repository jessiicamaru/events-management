import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../habits/domain/models/habit_model.dart';
import '../providers/category_filter_provider.dart';

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
            child: Text('Unscheduled Habits', style: theme.textTheme.h4),
          ),
          Expanded(
            child: habitsAsync.when(
              data: (habits) {
                final filteredHabits = selectedCategory == null 
                    ? habits 
                    : habits.where((h) => h.category == selectedCategory).toList();
                
                if (filteredHabits.isEmpty) {
                  return const Center(child: Text(AppConstants.noUnscheduledHabitsMessage));
                }
                return ListView.builder(
                  scrollDirection: isDesktop ? Axis.vertical : Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredHabits.length,
                  itemBuilder: (context, index) {
                    final habit = filteredHabits[index];
                    final content = ShadCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(habit.name, style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
                          if (habit.category != null) ...[
                            const SizedBox(height: 4),
                            Text(habit.category!, style: TextStyle(fontSize: 10, color: theme.colorScheme.mutedForeground)),
                          ]
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
              error: (err, stack) => Center(child: Text('${AppConstants.errorPrefix}$err')),
            ),
          ),
        ],
      ),
    );
  }
}
