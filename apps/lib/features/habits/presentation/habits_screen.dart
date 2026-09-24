import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/habits/presentation/habits_provider.dart';
import 'package:habit_tracker/features/habits/presentation/providers/heatmap_provider.dart';
import 'package:habit_tracker/features/habits/presentation/widgets/heatmap_widget.dart';
import 'package:habit_tracker/features/habits/presentation/widgets/add_habit_dialog.dart';
import 'package:habit_tracker/features/habits/presentation/widgets/edit_habit_dialog.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/calendar/presentation/providers/event_category_provider.dart';

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
                ],
              ),
            ),
            Expanded(
              child: habitsAsync.when(
                data: (habits) {
                  final heatmapAsync = ref.watch(heatmapProvider);
                  final categoriesAsync = ref.watch(eventCategoriesProvider(squadId: null));
                  
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
                      if (habits.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32.0),
                            child: Center(child: Text(translations.translate('no_habits_yet'))),
                          ),
                        )
                      else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final habit = habits[index];
                              
                              String categoryText = translations.translate('uncategorized');
                              if (habit.categoryId != null) {
                                categoriesAsync.whenData((categories) {
                                  final cat = categories.where((c) => c.id == habit.categoryId).firstOrNull;
                                  if (cat != null) {
                                    categoryText = cat.name;
                                  }
                                });
                              }

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
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ShadButton(
                            width: double.infinity,
                            onPressed: () => showDialog(
                              context: context,
                              builder: (context) => const AddHabitDialog(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.plus, size: 16),
                                const SizedBox(width: 8),
                                Text(translations.translate('add_habit')),
                              ],
                            ),
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
