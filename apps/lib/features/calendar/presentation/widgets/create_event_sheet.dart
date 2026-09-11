import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../habits/domain/models/habit_model.dart';
import '../../domain/models/event_model.dart';
import '../events_provider.dart';

class CreateEventSheet extends ConsumerStatefulWidget {
  final AsyncValue<List<HabitModel>> habitsAsync;
  final DateTime? initialDate;

  const CreateEventSheet({
    super.key,
    required this.habitsAsync,
    this.initialDate,
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
    if (widget.initialDate != null) {
      _startDate = widget.initialDate!;
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
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(title: Text('Title is required')),
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
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      habitId: _selectedHabit?.id ?? '',
      startTime: start,
      endTime: end.isBefore(start) ? start.add(const Duration(hours: 1)) : end,
      targetDuration: int.tryParse(_targetDurationController.text),
    );

    await ref.read(eventsProvider.notifier).addEvent(event);

    if (mounted) {
      Navigator.of(context).pop();
      ShadToaster.of(context).show(
        ShadToast(
          title: const Text('Event Created'),
          description: Text('Scheduled "$title" at ${_startTime.format(context)}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final habits = widget.habitsAsync.value ?? [];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text('Schedule Event', style: theme.textTheme.h4),
                const Spacer(),
                ShadButton.ghost(
                  size: ShadButtonSize.sm,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Icon(LucideIcons.x, size: 18),
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
                  if (habits.isNotEmpty) ...[
                    Text('Unscheduled Habits', style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.mutedForeground,
                      fontWeight: FontWeight.w600,
                    )),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: habits.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final habit = habits[index];
                          final isSelected = _selectedHabit?.id == habit.id;
                          return GestureDetector(
                            onTap: () => _fillFromHabit(habit),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                    : theme.colorScheme.muted,
                                border: Border.all(
                                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.border,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    habit.name,
                                    style: theme.textTheme.small.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? theme.colorScheme.primary : null,
                                    ),
                                  ),
                                  if (habit.category != null)
                                    Text(
                                      habit.category!,
                                      style: TextStyle(fontSize: 10, color: theme.colorScheme.mutedForeground),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Title field
                  Text('Title', style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ShadInput(
                    controller: _titleController,
                    placeholder: const Text('Event title'),
                  ),
                  const SizedBox(height: 16),

                  // Category
                  Text('Category', style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ShadSelect<String>(
                    placeholder: const Text('Select category'),
                    initialValue: _selectedCategory,
                    onChanged: (val) => setState(() => _selectedCategory = val),
                    options: _categories.map((c) => ShadOption(value: c, child: Text(c))).toList(),
                    selectedOptionBuilder: (context, value) => Text(value),
                  ),
                  const SizedBox(height: 16),

                  // Date
                  Text('Date', style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ShadButton.outline(
                    width: double.infinity,
                    onPressed: _pickDate,
                    child: Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 16),
                        const SizedBox(width: 8),
                        Text(DateFormat('EEEE, MMM d, yyyy').format(_startDate)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time
                  Text('Time', style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
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
                  Text('Target Duration (mins)', style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ShadInput(
                    controller: _targetDurationController,
                    placeholder: const Text('e.g. 45'),
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 28),

                  // Submit
                  ShadButton(
                    width: double.infinity,
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Create Event'),
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
