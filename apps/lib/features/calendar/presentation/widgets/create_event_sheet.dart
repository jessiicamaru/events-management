import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/theme/app_theme.dart';
import 'package:habit_tracker/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';
import 'package:habit_tracker/features/habits/presentation/habits_provider.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/unscheduled_habits_selector.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/event_tasks_editor.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_task_model.dart';
import 'package:habit_tracker/features/habits/presentation/providers/habit_tasks_provider.dart';
import 'package:habit_tracker/features/calendar/presentation/providers/event_category_provider.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/custom_recurrence_dialog.dart';



class CreateEventSheet extends ConsumerStatefulWidget {
  final AsyncValue<List<HabitModel>>? habitsAsync;
  final DateTime? initialDate;
  final HabitModel? initialHabit;
  final EventModel? eventToEdit;

  const CreateEventSheet({
    super.key,
    this.habitsAsync,
    this.initialDate,
    this.initialHabit,
    this.eventToEdit,
  });

  @override
  ConsumerState<CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends ConsumerState<CreateEventSheet> {
  final _titleController = TextEditingController();
  final _targetDurationController = TextEditingController();
  String? _selectedCategoryId;
  HabitModel? _selectedHabit;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isSubmitting = false;
  List<EventTaskModel>? _localTasks;
  String _selectedRepeatPreset = 'none';
  String? _recurrenceRule;

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      final evt = widget.eventToEdit!;
      _titleController.text = evt.title;
      _selectedCategoryId = evt.categoryId;
      _startDate = evt.startTime.toLocal();
      _startTime = TimeOfDay.fromDateTime(evt.startTime.toLocal());
      _endTime = TimeOfDay.fromDateTime(evt.endTime.toLocal());
      if (evt.targetDuration != null) {
        _targetDurationController.text = evt.targetDuration.toString();
      } else {
        _updateTargetDuration();
      }
      _recurrenceRule = evt.recurrenceRule;
      if (_recurrenceRule == null || _recurrenceRule!.isEmpty) {
        _selectedRepeatPreset = 'none';
      } else if (_recurrenceRule == 'RRULE:FREQ=DAILY;INTERVAL=1') {
        _selectedRepeatPreset = 'daily';
      } else if (_recurrenceRule == 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR') {
        _selectedRepeatPreset = 'weekday';
      } else if (_recurrenceRule!.startsWith('RRULE:FREQ=WEEKLY;INTERVAL=1;BYDAY=')) {
        _selectedRepeatPreset = 'weekly';
      } else if (_recurrenceRule!.startsWith('RRULE:FREQ=WEEKLY;INTERVAL=2;BYDAY=')) {
        _selectedRepeatPreset = 'biweekly';
      } else if (_recurrenceRule!.startsWith('RRULE:FREQ=MONTHLY;BYMONTHDAY=')) {
        _selectedRepeatPreset = 'monthly';
      } else if (_recurrenceRule == 'RRULE:FREQ=YEARLY') {
        _selectedRepeatPreset = 'yearly';
      } else {
        _selectedRepeatPreset = 'custom';
      }
    } else if (widget.initialDate != null) {
      _startDate = widget.initialDate!;
      _startTime = TimeOfDay.fromDateTime(widget.initialDate!);
      
      // Auto-extend end time by 1 hour from initial date
      final endDateTime = widget.initialDate!.add(const Duration(hours: 1));
      _endTime = TimeOfDay.fromDateTime(endDateTime);
      _updateTargetDuration();
    }
    
    if (widget.initialHabit != null) {
      if (widget.eventToEdit == null) {
        _fillFromHabit(widget.initialHabit!);
      } else {
        _selectedHabit = widget.initialHabit;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetDurationController.dispose();
    super.dispose();
  }

  void _fillFromHabit(HabitModel habit) async {
    setState(() {
      _selectedHabit = habit;
      _titleController.text = habit.name;
      _selectedCategoryId = habit.categoryId;
    });

    if (widget.eventToEdit == null) {
      try {
        final habitTasks = await ref.read(habitTasksProvider(habit.id).future);
        if (!mounted) return;
        setState(() {
          _localTasks = habitTasks.map((t) => EventTaskModel(
            id: DateTime.now().millisecondsSinceEpoch.toString() + t.id,
            eventId: 'temp',
            title: t.title,
            description: t.description,
            order: t.order,
            priority: t.priority,
            estimatedMinutes: t.estimatedMinutes,
            isCompleted: false,
          )).toList();
        });
      } catch (e) {
        // ignore
      }
    }
  }

  String _getWeekdayName(int weekday, AppTranslations translations) {
    switch (weekday) {
      case DateTime.monday: return translations.translate('monday');
      case DateTime.tuesday: return translations.translate('tuesday');
      case DateTime.wednesday: return translations.translate('wednesday');
      case DateTime.thursday: return translations.translate('thursday');
      case DateTime.friday: return translations.translate('friday');
      case DateTime.saturday: return translations.translate('saturday');
      case DateTime.sunday: return translations.translate('sunday');
      default: return '';
    }
  }

  void _handleRepeatPresetChanged(String? preset) async {
    if (preset == null || preset == 'none') {
      setState(() {
        _selectedRepeatPreset = 'none';
        _recurrenceRule = null;
      });
      return;
    }

    if (preset == 'custom') {
      final customRule = await showShadDialog<String>(
        context: context,
        builder: (context) => CustomRecurrenceDialog(initialRrule: _recurrenceRule),
      );
      if (customRule != null) {
        setState(() {
          _selectedRepeatPreset = 'custom';
          _recurrenceRule = customRule;
        });
      } else {
        // Revert preset if cancelled
        setState(() {});
      }
      return;
    }

    setState(() {
      _selectedRepeatPreset = preset;
      final weekdayCode = _getWeekdayCode(_startDate.weekday);
      switch (preset) {
        case 'daily':
          _recurrenceRule = 'RRULE:FREQ=DAILY;INTERVAL=1';
          break;
        case 'weekday':
          _recurrenceRule = 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR';
          break;
        case 'weekly':
          _recurrenceRule = 'RRULE:FREQ=WEEKLY;INTERVAL=1;BYDAY=$weekdayCode';
          break;
        case 'biweekly':
          _recurrenceRule = 'RRULE:FREQ=WEEKLY;INTERVAL=2;BYDAY=$weekdayCode';
          break;
        case 'monthly':
          _recurrenceRule = 'RRULE:FREQ=MONTHLY;BYMONTHDAY=${_startDate.day}';
          break;
        case 'yearly':
          _recurrenceRule = 'RRULE:FREQ=YEARLY';
          break;
      }
    });
  }

  String _getWeekdayCode(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'MO';
      case DateTime.tuesday: return 'TU';
      case DateTime.wednesday: return 'WE';
      case DateTime.thursday: return 'TH';
      case DateTime.friday: return 'FR';
      case DateTime.saturday: return 'SA';
      case DateTime.sunday: return 'SU';
      default: return 'MO';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) {
      setState(() {
        _startTime = picked;
        // Auto-extend end time by 1h
        final newEndHour = (picked.hour + 1) % 24;
        _endTime = TimeOfDay(hour: newEndHour, minute: picked.minute);
        _updateTargetDuration();
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: _endTime);
    if (picked != null) {
      setState(() {
        _endTime = picked;
        _updateTargetDuration();
      });
    }
  }

  void _updateTargetDuration() {
    final start = DateTime(2000, 1, 1, _startTime.hour, _startTime.minute);
    var end = DateTime(2000, 1, 1, _endTime.hour, _endTime.minute);
    if (end.isBefore(start)) end = end.add(const Duration(days: 1));
    final diffMins = end.difference(start).inMinutes;
    _targetDurationController.text = diffMins.toString();
  }

  Future<void> _submit() async {
    final translations = ref.read(translationsProvider);
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _isSubmitting = false);
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: Text(translations.translate('event_title_empty')),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final start = DateTime(
      _startDate.year, _startDate.month, _startDate.day,
      _startTime.hour, _startTime.minute,
    );
    final end = DateTime(
      _startDate.year, _startDate.month, _startDate.day,
      _endTime.hour, _endTime.minute,
    );

    final event = EventModel(
      id: widget.eventToEdit?.id ?? '',
      title: title,
      habitId: _selectedHabit?.id ?? '',
      startTime: start.toUtc(),
      endTime: (end.isBefore(start) ? start.add(const Duration(hours: 1)) : end).toUtc(),
      targetDuration: int.tryParse(_targetDurationController.text),
      isCompleted: widget.eventToEdit?.isCompleted ?? false,
      tasks: widget.eventToEdit == null ? _localTasks : null,
      actualDuration: widget.eventToEdit?.actualDuration,
      createdAt: widget.eventToEdit?.createdAt,
      userId: widget.eventToEdit?.userId,
      categoryId: _selectedCategoryId,
      recurrenceRule: _recurrenceRule,
    );

    String? editScope;
    DateTime? originalOccurrenceDate;
    if (widget.eventToEdit != null && (widget.eventToEdit!.recurrenceRule != null || widget.eventToEdit!.parentEventId != null)) {
      editScope = await showRecurrenceEditOptionDialog(context, translations);
      if (editScope == null) {
        setState(() => _isSubmitting = false);
        return;
      }
      originalOccurrenceDate = widget.eventToEdit!.startTime;
    }

    try {
      if (widget.eventToEdit != null) {
        await ref.read(eventsProvider.notifier).updateEvent(
          event, 
          editScope: editScope, 
          originalOccurrenceDate: originalOccurrenceDate
        );
      } else {
        await ref.read(eventsProvider.notifier).addEvent(event);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ShadToaster.of(context).show(
          ShadToast(
            title: Text(widget.eventToEdit != null ? translations.translate('event_updated_toast') : translations.translate('event_created_toast')),
            description: Text('${translations.translate('scheduled_event_toast')} "$title" at ${_startTime.format(context)}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: Text(translations.translate('error')),
            description: Text('${translations.translate('failed_to_create_event')}: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final habits = ref.watch(habitsProvider).value ?? [];
    final appSettings = ref.watch(appSettingsProvider);
    final brandColor = AppTheme.getBrandColor(appSettings.primaryColor);
    final currentLocale = ref.watch(localeProvider);
    final translations = ref.watch(translationsProvider);
    final localeStr = currentLocale == AppLocale.en ? 'en_US' : 'vi';
    final categoriesAsync = ref.watch(eventCategoriesProvider(squadId: null));

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle (We can keep it above if the sheet background is still normal, but wait, if the header is colored, the handle should be inside the colored area)
          Container(
            decoration: BoxDecoration(
              color: brandColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      Text(
                        widget.eventToEdit != null ? translations.translate('update_event') : translations.translate('schedule_event'), 
                        style: theme.textTheme.h4.copyWith(color: Colors.white)
                      ),
                      const Spacer(),
                      ShadButton.ghost(
                        size: ShadButtonSize.sm,
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Icon(LucideIcons.x, size: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),



          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: Quick fill from habits
                  if (habits.isNotEmpty)
                    UnscheduledHabitsSelector(
                      habits: habits,
                      selectedHabit: _selectedHabit,
                      onSelect: _fillFromHabit,
                    ),

                  if (_selectedHabit != null || widget.eventToEdit != null) ...[
                    const SizedBox(height: 16),
                    EventTasksEditor(
                      eventId: widget.eventToEdit?.id,
                      localTasks: _localTasks,
                      onLocalTasksChanged: (tasks) {
                        setState(() {
                          _localTasks = tasks;
                        });
                      },
                    ),
                  ],

                  const SizedBox(height: 16),
                  // Title field
                  Text(translations.translate('title'), style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ShadInput(
                    controller: _titleController,
                    placeholder: Text(translations.translate('event_title_placeholder')),
                  ),
                  const SizedBox(height: 16),

                  Text(translations.translate('category'), style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  categoriesAsync.when(
                    data: (categories) => SizedBox(
                      width: double.infinity,
                      child: ShadSelect<String>(
                        placeholder: Text(translations.translate('select_category')),
                        initialValue: _selectedCategoryId,
                        onChanged: (val) => setState(() => _selectedCategoryId = val),
                        options: categories.map((c) {
                          return ShadOption(value: c.id, child: Text(c.name));
                        }).toList(),
                        selectedOptionBuilder: (context, value) {
                          final cat = categories.firstWhere((c) => c.id == value, orElse: () => categories.first);
                          return Text(cat.name);
                        },
                      ),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, ___) => const Text('Error loading categories'),
                  ),
                  const SizedBox(height: 16),

                  // Date
                  Text(translations.translate('date'), style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ShadButton.outline(
                    width: double.infinity,
                    onPressed: _pickDate,
                    child: Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 16),
                        const SizedBox(width: 8),
                        Text(DateFormat('EEEE, MMM d, yyyy', localeStr).format(_startDate)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time
                  Text(translations.translate('time'), style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ShadButton.outline(
                          onPressed: _pickStartTime,
                          child: Row(
                            children: [
                              const Icon(LucideIcons.clock, size: 16),
                              const SizedBox(width: 8),
                              Text(_startTime.format(context)),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('→', style: theme.textTheme.p),
                      ),
                      Expanded(
                        child: ShadButton.outline(
                          onPressed: _pickEndTime,
                          child: Row(
                            children: [
                              const Icon(LucideIcons.clock, size: 16),
                              const SizedBox(width: 8),
                              Text(_endTime.format(context)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                   // Target Duration
                  Text(translations.translate('target_duration'), style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ShadInput(
                    controller: _targetDurationController,
                    placeholder: Text(translations.translate('duration_placeholder')),
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 16),

                  Text(translations.translate('repeat'), style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ShadSelect<String>(
                      placeholder: Text(translations.translate('does_not_repeat')),
                      initialValue: _selectedRepeatPreset,
                      onChanged: (val) {
                        _handleRepeatPresetChanged(val);
                      },
                      options: [
                        ShadOption(value: 'none', child: Text(translations.translate('does_not_repeat'))),
                        ShadOption(value: 'daily', child: Text(translations.translate('every_day'))),
                        ShadOption(value: 'weekday', child: Text(translations.translate('every_weekday'))),
                        ShadOption(value: 'weekly', child: Text('${translations.translate('every_week')} ${_getWeekdayName(_startDate.weekday, translations)}')),
                        ShadOption(value: 'biweekly', child: Text('${translations.translate('every_2_weeks')} ${_getWeekdayName(_startDate.weekday, translations)}')),
                        ShadOption(value: 'monthly', child: Text('${translations.translate('every_month')} ${_startDate.day}')),
                        ShadOption(value: 'yearly', child: Text('${translations.translate('every_year')} ${DateFormat('MMM d').format(_startDate)}')),
                        ShadOption(value: 'custom', child: Text(translations.translate('custom_dots'))),
                      ],
                      selectedOptionBuilder: (context, value) {
                        switch (value) {
                          case 'none': return Text(translations.translate('does_not_repeat'));
                          case 'daily': return Text(translations.translate('every_day'));
                          case 'weekday': return Text(translations.translate('every_weekday'));
                          case 'weekly': return Text('${translations.translate('every_week')} ${_getWeekdayName(_startDate.weekday, translations)}');
                          case 'biweekly': return Text('${translations.translate('every_2_weeks')} ${_getWeekdayName(_startDate.weekday, translations)}');
                          case 'monthly': return Text('${translations.translate('every_month')} ${_startDate.day}');
                          case 'yearly': return Text('${translations.translate('every_year')} ${DateFormat('MMM d').format(_startDate)}');
                          case 'custom': return Text(translations.translate('custom'));
                          default: return Text(translations.translate('does_not_repeat'));
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Submit
                  ShadButton(
                    width: double.infinity,
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(widget.eventToEdit != null ? translations.translate('update_event_btn') : translations.translate('create_event_btn')),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
