import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../domain/models/event_task_model.dart';
import '../providers/event_tasks_provider.dart';

class EventTasksChecklist extends ConsumerWidget {
  final String eventId;
  final VoidCallback? onStartPomodoro;

  const EventTasksChecklist({super.key, required this.eventId, this.onStartPomodoro});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(eventTasksProvider(eventId));
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translations.translate('tasks_checklist') ?? 'Tasks',
          style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
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
                      translations.translate('no_tasks_for_event') ?? 'No tasks for this session.',
                      style: theme.textTheme.muted,
                    ),
                  ),
                );
              }

              final completedCount = tasks.where((t) => t.isCompleted).length;
              final progress = tasks.isEmpty ? 0.0 : completedCount / tasks.length;

              return Column(
                children: [
                  // Progress header
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: theme.colorScheme.secondary,
                              color: progress == 1.0 ? Colors.green : theme.colorScheme.primary,
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$completedCount/${tasks.length}',
                          style: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Task list
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Container(
                        decoration: BoxDecoration(
                          border: index < tasks.length - 1
                              ? Border(bottom: BorderSide(color: theme.colorScheme.border))
                              : null,
                        ),
                        child: ShadCheckbox(
                          value: task.isCompleted,
                          onChanged: (val) {
                            ref.read(eventTasksProvider(eventId).notifier).toggleTask(task.id, val);
                          },
                          label: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: TextStyle(
                                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                        color: task.isCompleted ? theme.colorScheme.mutedForeground : null,
                                      ),
                                    ),
                                    if (task.description != null)
                                      Text(
                                        task.description!,
                                        style: theme.textTheme.small.copyWith(
                                          color: theme.colorScheme.mutedForeground,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (task.estimatedMinutes != null)
                                ShadBadge.secondary(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.clock, size: 10),
                                      const SizedBox(width: 4),
                                      Text('${task.estimatedMinutes}m'),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
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
}
