import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../domain/models/habit_model.dart';
import '../habits_provider.dart';
import 'habit_category_selector.dart';
import 'habit_tasks_editor.dart';

class EditHabitDialog extends ConsumerStatefulWidget {
  final HabitModel habit;

  const EditHabitDialog({
    super.key,
    required this.habit,
  });

  @override
  ConsumerState<EditHabitDialog> createState() => _EditHabitDialogState();
}

class _EditHabitDialogState extends ConsumerState<EditHabitDialog> {
  late final TextEditingController _nameController;
  late String _selectedCategory;
  late List<int> _selectedDays;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit.name);
    _selectedCategory = widget.habit.category ?? 'Uncategorized';
    _selectedDays = List<int>.from(widget.habit.targetDays);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String habitId) {
    final translations = ref.read(translationsProvider);
    final notifier = ref.read(habitsProvider.notifier);
    
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
                Navigator.of(context).pop(); // close confirm dialog
                Navigator.of(context).pop(); // close edit dialog
                await notifier.deleteHabit(habitId);
                
                if (mounted) {
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

  Future<void> _submit() async {
    final translations = ref.read(translationsProvider);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: Text(translations.translate('habit_name_empty')),
        ),
      );
      return;
    }
    
    final updatedHabit = widget.habit.copyWith(
      name: name,
      category: _selectedCategory,
      targetDays: _selectedDays,
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
  }

  @override
  Widget build(BuildContext context) {
    final translations = ref.watch(translationsProvider);

    return ShadDialog(
      title: Text(translations.translate('edit_habit')),
      description: Text(translations.translate('edit_habit_desc')),
      actions: [
        ShadButton.destructive(
          onPressed: () {
            Navigator.of(context).pop();
            _showDeleteConfirmation(context, ref, widget.habit.id);
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
          onPressed: _submit,
          child: Text(translations.translate('save_btn')),
        ),
      ],
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              translations.translate('habit_name_placeholder'),
              style: ShadTheme.of(context).textTheme.small.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ShadInput(
              controller: _nameController,
              placeholder: Text(translations.translate('habit_name_placeholder')),
            ),
            const SizedBox(height: 16),
            HabitCategorySelector(
              selectedCategory: _selectedCategory,
              onCategoryChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 24),
            HabitTasksEditor(habitId: widget.habit.id),
          ],
        ),
      ),
    );
  }
}
