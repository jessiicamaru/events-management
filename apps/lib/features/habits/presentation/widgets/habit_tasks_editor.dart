import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_task_model.dart';
import 'package:habit_tracker/features/habits/presentation/providers/habit_tasks_provider.dart';

class HabitTasksEditor extends ConsumerWidget {
  final String habitId;

  const HabitTasksEditor({super.key, required this.habitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(habitTasksProvider(habitId));
    final translations = ref.watch(translationsProvider);
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              translations.translate('habit_tasks_title') ?? 'Habit Tasks (Optional)',
              style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
            ),
            ShadButton.ghost(
              size: ShadButtonSize.sm,
              onPressed: () => _showTaskDialog(context, ref, habitId: habitId),
              child: Row(
                children: [
                  const Icon(LucideIcons.plus, size: 16),
                  const SizedBox(width: 4),
                  Text(translations.translate('add_task') ?? 'Add Task'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.border),
            borderRadius: theme.radius,
          ),
          child: tasksAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      translations.translate('no_tasks_yet') ?? 'No tasks added yet. Add a task to create a checklist for this habit.',
                      style: theme.textTheme.muted,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                onReorder: (oldIndex, newIndex) {
                  ref.read(habitTasksProvider(habitId).notifier).reorderTasks(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Container(
                    key: ValueKey(task.id),
                    decoration: BoxDecoration(
                      border: index < tasks.length - 1
                          ? Border(bottom: BorderSide(color: theme.colorScheme.border))
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.gripVertical, size: 16, color: Colors.grey),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(task.title, style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w500)),
                                if (task.estimatedMinutes != null)
                                  Text('${task.estimatedMinutes} ${translations.translate('minutes_short') ?? 'min'}', style: theme.textTheme.muted),
                              ],
                            ),
                          ),
                          _buildPriorityBadge(task.priority, theme),
                          ShadButton.ghost(
                            size: ShadButtonSize.sm,
                            onPressed: () => _showTaskDialog(context, ref, habitId: habitId, task: task),
                            child: const Icon(LucideIcons.pencil, size: 16),
                          ),
                          ShadButton.ghost(
                            size: ShadButtonSize.sm,
                            onPressed: () => ref.read(habitTasksProvider(habitId).notifier).deleteTask(task.id),
                            child: const Icon(LucideIcons.trash, size: 16, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: $err'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority, ShadThemeData theme) {
    Color color;
    String label;
    switch (priority) {
      case TaskPriority.high:
        color = Colors.red;
        label = 'High';
        break;
      case TaskPriority.medium:
        color = Colors.orange;
        label = 'Medium';
        break;
      case TaskPriority.low:
        color = Colors.green;
        label = 'Low';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: theme.textTheme.small.copyWith(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showTaskDialog(BuildContext context, WidgetRef ref, {required String habitId, HabitTaskModel? task}) {
    final isEdit = task != null;
    final titleController = TextEditingController(text: task?.title);
    final descController = TextEditingController(text: task?.description);
    final estimateController = TextEditingController(text: task?.estimatedMinutes?.toString());
    TaskPriority selectedPriority = task?.priority ?? TaskPriority.medium;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return ShadDialog(
              title: Text(isEdit ? 'Edit Task' : 'Add Task'),
              actions: [
                ShadButton.secondary(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ShadButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;
                    
                    int? estimatedMinutes;
                    if (estimateController.text.isNotEmpty) {
                      estimatedMinutes = int.tryParse(estimateController.text);
                    }

                    if (isEdit) {
                      final updated = task.copyWith(
                        title: titleController.text.trim(),
                        description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                        priority: selectedPriority,
                        estimatedMinutes: estimatedMinutes,
                      );
                      ref.read(habitTasksProvider(habitId).notifier).updateTask(updated);
                    } else {
                      final newTask = HabitTaskModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        habitId: habitId,
                        title: titleController.text.trim(),
                        description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                        order: 999, // Backend should handle exact ordering, or we append to end
                        priority: selectedPriority,
                        estimatedMinutes: estimatedMinutes,
                      );
                      ref.read(habitTasksProvider(habitId).notifier).addTask(newTask);
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
              child: Container(
                width: 400,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShadInput(
                      controller: titleController,
                      placeholder: const Text('Task title'),
                    ),
                    const SizedBox(height: 12),
                    ShadInput(
                      controller: descController,
                      placeholder: const Text('Description (optional)'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ShadSelect<TaskPriority>(
                            placeholder: const Text('Priority'),
                            initialValue: selectedPriority,
                            onChanged: (val) {
                              if (val != null) setState(() => selectedPriority = val);
                            },
                            options: const [
                              ShadOption(value: TaskPriority.low, child: Text('Low')),
                              ShadOption(value: TaskPriority.medium, child: Text('Medium')),
                              ShadOption(value: TaskPriority.high, child: Text('High')),
                            ],
                            selectedOptionBuilder: (context, value) => Text(value.name.toUpperCase()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ShadInput(
                            controller: estimateController,
                            placeholder: const Text('Est. minutes'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
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
}
