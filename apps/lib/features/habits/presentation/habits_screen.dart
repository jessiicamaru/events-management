import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_constants.dart';
import '../domain/models/habit_model.dart';
import 'habits_provider.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.habitsTitle)),
      body: habitsAsync.when(
        data: (habits) {
          if (habits.isEmpty) {
            return const Center(child: Text(AppConstants.noHabitsMessage));
          }
          return ListView.builder(
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return ListTile(
                title: Text(habit.name),
                subtitle: Text('${AppConstants.categoryLabel}: ${habit.category ?? AppConstants.uncategorized}'),
                trailing: Text('${habit.targetDays.length} days/week'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${AppConstants.errorPrefix}$err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddHabitDialog(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppConstants.addHabit),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: AppConstants.habitNameLabel),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppConstants.cancel),
            ),
            ElevatedButton(
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
