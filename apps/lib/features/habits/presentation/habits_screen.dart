import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/utils/app_constants.dart';
import '../domain/models/habit_model.dart';
import 'habits_provider.dart';
import 'providers/heatmap_provider.dart';
import 'widgets/heatmap_widget.dart';
import '../../../core/localization/locale_provider.dart';

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
                    onPressed: () => _showAddHabitDialog(context, ref),
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
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          if (habit.currentStreak > 0)
                                            Row(
                                              children: [
                                                const Icon(LucideIcons.flame, color: Colors.orange, size: 18),
                                                const SizedBox(width: 4),
                                                Text('${habit.currentStreak}', style: theme.textTheme.large.copyWith(color: Colors.orange)),
                                              ],
                                            ),
                                          const SizedBox(height: 4),
                                          Text('${habit.targetDays.length} ${translations.translate('days_week')}', style: theme.textTheme.muted),
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

  void _showAddHabitDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final translations = ref.read(translationsProvider);
    
    showDialog(
      context: context,
      builder: (context) {
        return ShadDialog(
          title: Text(translations.translate('add_habit')),
          description: Text(translations.translate('add_habit_desc')),
          child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ShadInput(
              controller: nameController,
              placeholder: Text(translations.translate('habit_name_placeholder')),
            ),
          ),
          actions: [
            ShadButton.secondary(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(translations.translate('cancel')),
            ),
            ShadButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final newHabit = HabitModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    targetDays: AppConstants.defaultTargetDays,
                  );
                  Navigator.of(context).pop();
                  await ref.read(habitsProvider.notifier).addHabit(newHabit);
                }
              },
              child: Text(translations.translate('add_btn')),
            ),
          ],
        );
      },
    );
  }
}
