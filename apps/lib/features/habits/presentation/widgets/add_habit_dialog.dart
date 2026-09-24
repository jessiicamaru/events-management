import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:habit_tracker/core/utils/app_constants.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/habits/presentation/habits_provider.dart';
import 'package:habit_tracker/features/habits/presentation/widgets/habit_category_selector.dart';

class AddHabitDialog extends ConsumerStatefulWidget {
  const AddHabitDialog({super.key});

  @override
  ConsumerState<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends ConsumerState<AddHabitDialog> {
  final _nameController = TextEditingController();
  String? _selectedCategoryId;
  final List<int> _selectedDays = List<int>.from(AppConstants.defaultTargetDays);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
    
    final newHabit = HabitModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      categoryId: _selectedCategoryId,
      targetDays: _selectedDays,
    );
    Navigator.of(context).pop();
    await ref.read(habitsProvider.notifier).addHabit(newHabit);
  }

  @override
  Widget build(BuildContext context) {
    final translations = ref.watch(translationsProvider);

    return ShadDialog(
      title: Text(translations.translate('add_habit')),
      description: Text(translations.translate('add_habit_desc')),
      actions: [
        ShadButton.secondary(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(translations.translate('cancel')),
        ),
        ShadButton(
          onPressed: _submit,
          child: Text(translations.translate('add_btn')),
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
              selectedCategoryId: _selectedCategoryId,
              onCategoryChanged: (val) => setState(() => _selectedCategoryId = val),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
