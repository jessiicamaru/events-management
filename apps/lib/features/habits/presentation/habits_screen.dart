import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/utils/app_constants.dart';
import '../domain/models/habit_model.dart';
import 'habits_provider.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final theme = ShadTheme.of(context);

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
                    AppConstants.habitsTitle,
                    style: theme.textTheme.h3,
                  ),
                  ShadButton.outline(
                    child: Icon(LucideIcons.plus, size: 16),
                    onPressed: () => _showAddHabitDialog(context, ref),
                  ),
                ],
              ),
            ),
            Expanded(
              child: habitsAsync.when(
                data: (habits) {
                  if (habits.isEmpty) {
                    return const Center(child: Text(AppConstants.noHabitsMessage));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ShadCard(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(habit.name, style: theme.textTheme.large),
                                  const SizedBox(height: 4),
                                  ShadBadge.secondary(
                                    child: Text(habit.category ?? AppConstants.uncategorized),
                                  ),
                                ],
                              ),
                              Text('${habit.targetDays.length} days/week', style: theme.textTheme.muted),
                            ],
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
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return ShadDialog(
          title: const Text(AppConstants.addHabit),
          description: const Text('Enter the details for your new habit.'),
          child: Container(
            width: 320,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ShadInput(
              controller: nameController,
              placeholder: const Text(AppConstants.habitNameLabel),
            ),
          ),
          actions: [
            ShadButton.secondary(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppConstants.cancel),
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
              child: const Text(AppConstants.add),
            ),
          ],
        );
      },
    );
  }
}
