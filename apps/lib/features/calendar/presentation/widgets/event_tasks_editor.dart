import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../domain/models/event_task_model.dart';
import '../../../habits/domain/models/habit_task_model.dart';
import '../providers/event_tasks_provider.dart';

class EventTasksEditor extends ConsumerStatefulWidget {
  final String? eventId;
  final List<EventTaskModel>? localTasks;
  final ValueChanged<List<EventTaskModel>>? onLocalTasksChanged;

  const EventTasksEditor({
    super.key,
    this.eventId,
    this.localTasks,
    this.onLocalTasksChanged,
  });

  @override
  ConsumerState<EventTasksEditor> createState() => _EventTasksEditorState();
}

class _EventTasksEditorState extends ConsumerState<EventTasksEditor> {
  late List<EventTaskModel> _localTasks;

  @override
  void initState() {
    super.initState();
    _localTasks = widget.localTasks != null ? List.from(widget.localTasks!) : [];
  }

  @override
  void didUpdateWidget(covariant EventTasksEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.eventId == null && widget.localTasks != null && oldWidget.localTasks != widget.localTasks) {
      _localTasks = List.from(widget.localTasks!);
    }
  }

  bool get _isLocalMode => widget.eventId == null;

  void _updateLocalTasks(List<EventTaskModel> newTasks) {
    setState(() {
      _localTasks = newTasks;
    });
    widget.onLocalTasksChanged?.call(_localTasks);
  }

  @override
  Widget build(BuildContext context) {
    final translations = ref.watch(translationsProvider);
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              translations.translate('event_tasks_title') ?? 'Tasks',
              style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
            ),
            ShadButton.ghost(
              size: ShadButtonSize.sm,
              onPressed: () => _showTaskDialog(context),
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
          child: _isLocalMode ? _buildLocalList(theme, translations) : _buildRemoteList(theme, translations),
        ),
      ],
    );
  }

  Widget _buildLocalList(ShadThemeData theme, dynamic translations) {
    if (_localTasks.isEmpty) {
      return _buildEmptyState(theme, translations);
    }
    return _buildReorderableList(_localTasks, theme, translations);
  }

  Widget _buildRemoteList(ShadThemeData theme, dynamic translations) {
    final tasksAsync = ref.watch(eventTasksProvider(widget.eventId!));
    
    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return _buildEmptyState(theme, translations);
        }
        return _buildReorderableList(tasks, theme, translations);
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Error: $err'),
      ),
    );
  }

  Widget _buildEmptyState(ShadThemeData theme, dynamic translations) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          translations.translate('no_tasks_yet') ?? 'No tasks added yet.',
          style: theme.textTheme.muted,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildReorderableList(List<EventTaskModel> tasks, ShadThemeData theme, dynamic translations) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        if (_isLocalMode) {
          final item = _localTasks.removeAt(oldIndex);
          _localTasks.insert(newIndex, item);
          for (int i = 0; i < _localTasks.length; i++) {
            _localTasks[i] = _localTasks[i].copyWith(order: i);
          }
          _updateLocalTasks(_localTasks);
        } else {
          ref.read(eventTasksProvider(widget.eventId!).notifier).reorderTasks(oldIndex, newIndex);
        }
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(LucideIcons.gripVertical, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                ShadCheckbox(
                  value: task.isCompleted,
                  onChanged: (val) {
                    if (val == null) return;
                    if (_isLocalMode) {
                      final updated = _localTasks.map((t) => t.id == task.id ? t.copyWith(isCompleted: val) : t).toList();
                      _updateLocalTasks(updated);
                    } else {
                      ref.read(eventTasksProvider(widget.eventId!).notifier).toggleTask(task.id, val);
                    }
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title, 
                        style: theme.textTheme.small.copyWith(
                          fontWeight: FontWeight.w500,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted ? theme.colorScheme.mutedForeground : null,
                        )
                      ),
                      if (task.estimatedMinutes != null)
                        Text('${task.estimatedMinutes} ${translations.translate('minutes_short') ?? 'min'}', style: theme.textTheme.muted),
                    ],
                  ),
                ),
                _buildPriorityBadge(task.priority, theme),
                ShadButton.ghost(
                  size: ShadButtonSize.sm,
                  onPressed: () => _showTaskDialog(context, task: task),
                  child: const Icon(LucideIcons.pencil, size: 16),
                ),
                ShadButton.ghost(
                  size: ShadButtonSize.sm,
                  onPressed: () {
                    if (_isLocalMode) {
                      final updated = _localTasks.where((t) => t.id != task.id).toList();
                      _updateLocalTasks(updated);
                    } else {
                      ref.read(eventTasksProvider(widget.eventId!).notifier).deleteTask(task.id);
                    }
                  },
                  child: const Icon(LucideIcons.trash, size: 16, color: Colors.red),
                ),
              ],
            ),
          ),
        );
      },
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

  void _showTaskDialog(BuildContext context, {EventTaskModel? task}) {
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
                      final updated = task!.copyWith(
                        title: titleController.text.trim(),
                        description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                        priority: selectedPriority,
                        estimatedMinutes: estimatedMinutes,
                      );
                      
                      if (_isLocalMode) {
                        final updatedList = _localTasks.map((t) => t.id == task.id ? updated : t).toList();
                        _updateLocalTasks(updatedList);
                      } else {
                        ref.read(eventTasksProvider(widget.eventId!).notifier).updateTask(updated);
                      }
                    } else {
                      final newTask = EventTaskModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        eventId: widget.eventId ?? 'temp',
                        title: titleController.text.trim(),
                        description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                        order: 999,
                        priority: selectedPriority,
                        estimatedMinutes: estimatedMinutes,
                        isCompleted: false,
                      );
                      
                      if (_isLocalMode) {
                        _updateLocalTasks([..._localTasks, newTask]);
                      } else {
                        ref.read(eventTasksProvider(widget.eventId!).notifier).addTask(newTask);
                      }
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
