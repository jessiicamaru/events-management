import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../settings/presentation/providers/app_settings_provider.dart';
import '../../../habits/domain/models/habit_model.dart';
import '../../domain/models/event_model.dart';
import '../events_provider.dart';
import 'unscheduled_habits_selector.dart';
import '../../../../core/localization/locale_provider.dart';

class CreateEventSheet extends ConsumerStatefulWidget {
  final AsyncValue<List<HabitModel>> habitsAsync;
  final DateTime? initialDate;
  final HabitModel? initialHabit;
  final EventModel? eventToEdit;

  const CreateEventSheet({
    super.key,
    required this.habitsAsync,
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
  String? _selectedCategory;
  HabitModel? _selectedHabit;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isSubmitting = false;

  static const List<String> _categories = ['Health', 'Work', 'Learning', 'Wellness'];

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      final evt = widget.eventToEdit!;
      _titleController.text = evt.title;
      _startDate = evt.startTime.toLocal();
      _startTime = TimeOfDay.fromDateTime(evt.startTime.toLocal());
      _endTime = TimeOfDay.fromDateTime(evt.endTime.toLocal());
      if (evt.targetDuration != null) {
        _targetDurationController.text = evt.targetDuration.toString();
      } else {
        _updateTargetDuration();
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
      _selectedHabit = widget.initialHabit;
      if (widget.eventToEdit == null) {
        _titleController.text = widget.initialHabit!.name;
      }
      _selectedCategory = widget.initialHabit!.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetDurationController.dispose();
    super.dispose();
  }

  void _fillFromHabit(HabitModel habit) {
    setState(() {
      _selectedHabit = habit;
      _titleController.text = habit.name;
      _selectedCategory = habit.category;
    });
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
      ShadToaster.of(context).show(
        ShadToast.destructive(title: Text(translations.translate('title_required_toast'))),
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
      id: widget.eventToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      habitId: _selectedHabit?.id ?? '',
      startTime: start,
      endTime: end.isBefore(start) ? start.add(const Duration(hours: 1)) : end,
      targetDuration: int.tryParse(_targetDurationController.text),
      isCompleted: widget.eventToEdit?.isCompleted ?? false,
      actualDuration: widget.eventToEdit?.actualDuration,
      createdAt: widget.eventToEdit?.createdAt,
      userId: widget.eventToEdit?.userId,
    );

    try {
      if (widget.eventToEdit != null) {
        await ref.read(eventsProvider.notifier).updateEvent(event);
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
    final habits = widget.habitsAsync.value ?? [];
    final appSettings = ref.watch(appSettingsProvider);
    final brandColor = AppTheme.getBrandColor(appSettings.primaryColor);
    final currentLocale = ref.watch(localeProvider);
    final translations = ref.watch(translationsProvider);
    final localeStr = currentLocale == AppLocale.en ? 'en_US' : 'vi';

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
                  UnscheduledHabitsSelector(
                    habits: habits,
                    selectedHabit: _selectedHabit,
                    onSelect: _fillFromHabit,
                  ),

                  // Title field
                  Text(translations.translate('title'), style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ShadInput(
                    controller: _titleController,
                    placeholder: Text(translations.translate('event_title_placeholder')),
                  ),
                  const SizedBox(height: 16),

                  // Category
                  Text(translations.translate('category'), style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ShadSelect<String>(
                      placeholder: Text(translations.translate('select_category')),
                      initialValue: _selectedCategory,
                      onChanged: (val) => setState(() => _selectedCategory = val),
                      options: _categories.map((c) {
                        String translatedName = c;
                        if (c == 'Health') translatedName = translations.translate('category_health');
                        if (c == 'Work') translatedName = translations.translate('category_work');
                        if (c == 'Learning') translatedName = translations.translate('category_learning');
                        if (c == 'Wellness') translatedName = translations.translate('category_wellness');
                        return ShadOption(value: c, child: Text(translatedName));
                      }).toList(),
                      selectedOptionBuilder: (context, value) {
                        if (value == 'Health') return Text(translations.translate('category_health'));
                        if (value == 'Work') return Text(translations.translate('category_work'));
                        if (value == 'Learning') return Text(translations.translate('category_learning'));
                        if (value == 'Wellness') return Text(translations.translate('category_wellness'));
                        return Text(value);
                      },
                    ),
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
