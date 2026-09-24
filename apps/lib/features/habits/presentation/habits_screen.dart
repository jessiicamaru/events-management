import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/habits/presentation/habits_provider.dart';
import 'package:habit_tracker/features/habits/presentation/providers/heatmap_provider.dart';
import 'package:habit_tracker/features/habits/presentation/widgets/heatmap_widget.dart';
import 'package:habit_tracker/features/habits/presentation/widgets/add_habit_dialog.dart';
import 'package:habit_tracker/features/habits/presentation/widgets/edit_habit_dialog.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    translations.translate('nav_habits'),
                    style: theme.textTheme.h3,
                  ),
                  ShadButton.outline(
                    child: const Icon(LucideIcons.plus, size: 16),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => const AddHabitDialog(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: habitsAsync.when(
                data: (habits) {
                  if (habits.isEmpty) {
                    return Center(child: Text(translations.translate('no_habits_yet')));
                  }
                  
                  final heatmapAsync = ref.watch(heatmapProvider);
                  
                  return CustomScrollView(
                     slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: heatmapAsync.when(
                            data: (data) => HeatmapWidget(data: data),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, stack) => Text('${translations.translate('error_heatmap')} $err'),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final habit = habits[index];
                              
                              String categoryText = habit.category ?? translations.translate('uncategorized');
                              if (habit.category == 'Health') categoryText = translations.translate('category_health');
                              if (habit.category == 'Work') categoryText = translations.translate('category_work');
                              if (habit.category == 'Learning') categoryText = translations.translate('category_learning');
                              if (habit.category == 'Wellness') categoryText = translations.translate('category_wellness');

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: ShadCard(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              translations.translate(habit.name),
                                              style: theme.textTheme.large,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            ShadBadge.secondary(
                                              child: Text(categoryText),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              if (habit.currentStreak > 0)
                                                Row(
                                                  children: [
                                                    const Icon(LucideIcons.flame, color: Colors.orange, size: 18),
                                                    const SizedBox(width: 4),
                                                    Text('${habit.currentStreak}', style: theme.textTheme.large.copyWith(color: Colors.orange)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          const SizedBox(width: 12),
                                          ShadButton.ghost(
                                            size: ShadButtonSize.sm,
                                            onPressed: () => showDialog(
                                              context: context,
                                              builder: (context) => EditHabitDialog(habit: habit),
                                            ),
                                            child: const Icon(LucideIcons.pencil, size: 16),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: habits.length,
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('${translations.translate('error_heatmap')} $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
