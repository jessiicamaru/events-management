import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/calendar/domain/event_occurrence.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_task_model.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';
import 'package:habit_tracker/features/calendar/presentation/providers/event_tasks_provider.dart';

/// The tasks of one event, with a checkbox each.
///
/// Takes the whole event rather than its id, because the id is not enough for a day of
/// a repeating series: every day carries the series' id. For such a day the list shows
/// the series' tasks as a template — all unticked, since it is a fresh day — and the
/// first tick gives the day its own event with its own copy of the tasks, then ticks
/// the copy. From then on the list follows that day's copy, so ticking Monday never
/// ticks Tuesday.
class EventTasksChecklist extends ConsumerStatefulWidget {
  const EventTasksChecklist({super.key, required this.event, this.onStartPomodoro});

  final EventModel event;
  final VoidCallback? onStartPomodoro;

  @override
  ConsumerState<EventTasksChecklist> createState() => _EventTasksChecklistState();
}

class _EventTasksChecklistState extends ConsumerState<EventTasksChecklist> {
  /// Set once this day has been split off, when the widget still holds the series day
  /// it was built with. After the events reload, the parent rebuilds with the day's own
  /// event and this is no longer needed.
  String? _dayEventId;
  bool _splittingOff = false;

  bool get _showingTemplate => _dayEventId == null && widget.event.isSeriesOccurrence;
  String get _tasksEventId => _dayEventId ?? widget.event.id;

  @override
  void didUpdateWidget(covariant EventTasksChecklist oldWidget) {
    super.didUpdateWidget(oldWidget);

    final isAnotherDay = oldWidget.event.id != widget.event.id ||
        oldWidget.event.startTime != widget.event.startTime;
    if (isAnotherDay) _dayEventId = null;
  }

  Future<void> _toggle(EventTaskModel task, bool value) async {
    if (!_showingTemplate) {
      await ref.read(eventTasksProvider(_tasksEventId).notifier).toggleTask(task.id, value);
      return;
    }

    setState(() => _splittingOff = true);
    final api = ref.read(apiServiceProvider);
    final toaster = ShadToaster.maybeOf(context);
    final translations = ref.read(translationsProvider);

    try {
      final dayId = await ref.read(eventsProvider.notifier).materializeOccurrence(widget.event);

      // Straight through the API rather than the tasks provider: that provider is
      // auto-disposed and not yet watched for the new id, so a tick sent through it could
      // land before its first fetch and be overwritten by it.
      final copies = await api.fetchEventTasks(dayId);
      final copy = copiedTaskFor(task, copies);
      if (copy != null) await api.toggleEventTask(dayId, copy.id, value);

      if (!mounted) return;
      ref.invalidate(eventTasksProvider(dayId));
      setState(() => _dayEventId = dayId);
    } catch (e) {
      toaster?.show(
        ShadToast.destructive(
          title: Text(translations.translate('error_title')),
          description: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) setState(() => _splittingOff = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(eventTasksProvider(_tasksEventId));
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translations.translate('tasks_checklist'),
          style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.border),
            borderRadius: theme.radius,
          ),
          child: tasksAsync.when(
            data: (stored) {
              // The series' ticks belong to no particular day, so a template shows none.
              final tasks = _showingTemplate
                  ? [for (final t in stored) t.copyWith(isCompleted: false)]
                  : stored;

              if (tasks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      translations.translate('no_tasks_for_event'),
                      style: theme.textTheme.muted,
                    ),
                  ),
                );
              }

              final completedCount = tasks.where((t) => t.isCompleted).length;
              final progress = completedCount / tasks.length;

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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          child: ShadCheckbox(
                            value: task.isCompleted,
                            // Disabled while the day is being split off, so a second tap
                            // cannot act on the series' tasks meanwhile.
                            onChanged: _splittingOff ? null : (val) => _toggle(task, val),
                            label: _TaskLabel(task: task),
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

class _TaskLabel extends StatelessWidget {
  const _TaskLabel({required this.task});

  final EventTaskModel task;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Row(
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
    );
  }
}
