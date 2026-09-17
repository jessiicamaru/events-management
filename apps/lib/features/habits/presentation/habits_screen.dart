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
                                            onPressed: () => _showEditHabitDialog(context, ref, habit),
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

  void _showAddHabitDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final translations = ref.read(translationsProvider);
    String selectedCategory = 'Uncategorized';
    List<int> selectedDays = List<int>.from(AppConstants.defaultTargetDays);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return ShadDialog(
              title: Text(translations.translate('add_habit')),
              description: Text(translations.translate('add_habit_desc')),
              actions: [
                ShadButton.secondary(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(translations.translate('cancel')),
                ),
                ShadButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ShadToaster.of(context).show(
                        ShadToast.destructive(
                          title: Text(translations.translate('habit_name_empty')),
                        ),
                      );
                      return;
                    }
                    
                    final newHabit = HabitModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      category: selectedCategory,
                      targetDays: selectedDays,
                    );
                    Navigator.of(context).pop();
                    await ref.read(habitsProvider.notifier).addHabit(newHabit);
                  },
                  child: Text(translations.translate('add_btn')),
                ),
              ],
              child: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translations.translate('habit_name_placeholder'),
                      style: ShadTheme.of(context).textTheme.small.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ShadInput(
                      controller: nameController,
                      placeholder: Text(translations.translate('habit_name_placeholder')),
                    ),
                    const SizedBox(height: 16),
                    _buildCategorySelector(
                      context,
                      translations,
                      selectedCategory,
                      (val) => setState(() => selectedCategory = val),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditHabitDialog(BuildContext context, WidgetRef ref, HabitModel habit) {
    final nameController = TextEditingController(text: habit.name);
    final translations = ref.read(translationsProvider);
    String selectedCategory = habit.category ?? 'Uncategorized';
    List<int> selectedDays = List<int>.from(habit.targetDays);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return ShadDialog(
              title: Text(translations.translate('edit_habit')),
              description: Text(translations.translate('edit_habit_desc')),
              actions: [
                ShadButton.destructive(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showDeleteConfirmation(context, ref, habit.id);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.trash, size: 16),
                      const SizedBox(width: 4),
                      Text(translations.translate('delete_btn')),
                    ],
                  ),
                ),
                ShadButton.secondary(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(translations.translate('cancel')),
                ),
                ShadButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ShadToaster.of(context).show(
                        ShadToast.destructive(
                          title: Text(translations.translate('habit_name_empty')),
                        ),
                      );
                      return;
                    }
                    
                    final updatedHabit = habit.copyWith(
                      name: name,
                      category: selectedCategory,
                      targetDays: selectedDays,
                    );
                    Navigator.of(context).pop();
                    await ref.read(habitsProvider.notifier).editHabit(updatedHabit);
                    
                    if (context.mounted) {
                      ShadToaster.of(context).show(
                        ShadToast(
                          title: Text(translations.translate('habit_updated_toast')),
                        ),
                      );
                    }
                  },
                  child: Text(translations.translate('save_btn')),
                ),
              ],
              child: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translations.translate('habit_name_placeholder'),
                      style: ShadTheme.of(context).textTheme.small.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ShadInput(
                      controller: nameController,
                      placeholder: Text(translations.translate('habit_name_placeholder')),
                    ),
                    const SizedBox(height: 16),
                    _buildCategorySelector(
                      context,
                      translations,
                      selectedCategory,
                      (val) => setState(() => selectedCategory = val),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String habitId) {
    final translations = ref.read(translationsProvider);
    showDialog(
      context: context,
      builder: (context) {
        return ShadDialog(
          title: Text(translations.translate('delete_habit')),
          description: Text(translations.translate('delete_habit_confirm')),
          actions: [
            ShadButton.secondary(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(translations.translate('cancel')),
            ),
            ShadButton.destructive(
              onPressed: () async {
                Navigator.of(context).pop();
                await ref.read(habitsProvider.notifier).deleteHabit(habitId);
                if (context.mounted) {
                  ShadToaster.of(context).show(
                    ShadToast(
                      title: Text(translations.translate('habit_deleted_toast')),
                    ),
                  );
                }
              },
              child: Text(translations.translate('delete_btn')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategorySelector(
    BuildContext context,
    AppTranslations translations,
    String selectedCategory,
    void Function(String) onChanged,
  ) {
    final theme = ShadTheme.of(context);
    final categories = ['Health', 'Work', 'Learning', 'Wellness', 'Uncategorized'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translations.translate('category'),
          style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ShadSelect<String>(
            placeholder: Text(translations.translate('select_category')),
            initialValue: selectedCategory,
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
            options: categories.map((c) {
              String translatedName = c;
              if (c == 'Health') translatedName = translations.translate('category_health');
              if (c == 'Work') translatedName = translations.translate('category_work');
              if (c == 'Learning') translatedName = translations.translate('category_learning');
              if (c == 'Wellness') translatedName = translations.translate('category_wellness');
              if (c == 'Uncategorized') translatedName = translations.translate('uncategorized');
              return ShadOption(value: c, child: Text(translatedName));
            }).toList(),
            selectedOptionBuilder: (context, value) {
              if (value == 'Health') return Text(translations.translate('category_health'));
              if (value == 'Work') return Text(translations.translate('category_work'));
              if (value == 'Learning') return Text(translations.translate('category_learning'));
              if (value == 'Wellness') return Text(translations.translate('category_wellness'));
              if (value == 'Uncategorized') return Text(translations.translate('uncategorized'));
              return Text(value);
            },
          ),
        ),
      ],
    );
  }
}
