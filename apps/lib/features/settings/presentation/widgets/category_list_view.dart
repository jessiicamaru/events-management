import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/calendar/models/event_category.dart';
import 'package:habit_tracker/features/calendar/presentation/providers/event_category_provider.dart';
import 'package:habit_tracker/features/habits/presentation/habits_provider.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/settings/presentation/category_management_screen.dart' show colorPalette;

class CategoryListView extends ConsumerWidget {
  final AsyncValue<List<EventCategory>> categoriesAsync;
  final bool isSquad;
  final ShadThemeData theme;

  const CategoryListView({
    super.key,
    required this.categoriesAsync,
    required this.isSquad,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = ref.watch(translationsProvider);
    return categoriesAsync.when(
      data: (allCategories) {
        final categories = allCategories.where((c) => isSquad ? c.squadId != null : c.squadId == null).toList();

        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.tags, size: 48, color: theme.colorScheme.mutedForeground),
                const SizedBox(height: 16),
                Text(
                  isSquad ? translations.translate('no_squad_categories') : translations.translate('no_personal_categories'),
                  style: theme.textTheme.large.copyWith(color: theme.colorScheme.mutedForeground),
                ),
                const SizedBox(height: 8),
                Text(
                  translations.translate('create_category_prompt'),
                  style: theme.textTheme.muted,
                ),
              ],
            ),
          );
        }
        
        return ListView.separated(
          itemCount: categories.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final category = categories[index];
            final color = colorPalette[category.colorPreset] ?? Colors.blueGrey;
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.border),
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.card,
              ),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      category.name,
                      style: theme.textTheme.large,
                    ),
                  ),
                  ShadButton.ghost(
                    width: 32,
                    height: 32,
                    padding: EdgeInsets.zero,
                    child: const Icon(LucideIcons.pencil, size: 16),
                    onPressed: () {
                      final habits = ref.read(habitsProvider).value ?? [];
                      final events = ref.read(eventsProvider).value ?? [];
                      
                      final affectedHabitsCount = habits.where((h) => h.categoryId == category.id).length;
                      final affectedEventsCount = events.where((e) => e.categoryId == category.id).length;

                      showDialog(
                        context: context,
                        builder: (ctx) => EditCategoryDialog(
                          category: category,
                          affectedHabitsCount: affectedHabitsCount,
                          affectedEventsCount: affectedEventsCount,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  ShadButton.ghost(
                    width: 32,
                    height: 32,
                    padding: EdgeInsets.zero,
                    hoverBackgroundColor: theme.colorScheme.destructive,
                    hoverForegroundColor: theme.colorScheme.destructiveForeground,
                    child: const Icon(LucideIcons.trash2, size: 16),
                    onPressed: () {
                      final habits = ref.read(habitsProvider).value ?? [];
                      final events = ref.read(eventsProvider).value ?? [];
                      
                      final affectedHabitsCount = habits.where((h) => h.categoryId == category.id).length;
                      final affectedEventsCount = events.where((e) => e.categoryId == category.id).length;

                      showDialog(
                        context: context,
                        builder: (ctx) => DeleteCategoryDialog(
                          category: category,
                          affectedHabitsCount: affectedHabitsCount,
                          affectedEventsCount: affectedEventsCount,
                          allCategories: categories,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e', style: TextStyle(color: theme.colorScheme.destructive))),
    );
  }
}

class EditCategoryDialog extends ConsumerStatefulWidget {
  final EventCategory category;
  final int affectedHabitsCount;
  final int affectedEventsCount;

  const EditCategoryDialog({
    super.key,
    required this.category,
    required this.affectedHabitsCount,
    required this.affectedEventsCount,
  });

  @override
  ConsumerState<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends ConsumerState<EditCategoryDialog> {
  late String name;
  late String selectedColor;
  bool _isLoading = false;
  bool _showWarning = false;

  @override
  void initState() {
    super.initState();
    name = widget.category.name;
    selectedColor = widget.category.colorPreset;
  }

  Future<void> _performUpdate() async {
    setState(() => _isLoading = true);
    try {
      final updatedCategory = widget.category.copyWith(
        name: name.trim(),
        colorPreset: selectedColor,
      );
      
      await ref.read(eventCategoriesProvider(squadId: widget.category.squadId).notifier)
         .updateCategory(updatedCategory);
      ref.invalidate(habitsProvider);
      ref.invalidate(eventsProvider);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);
    final isSquad = widget.category.squadId != null;

    if (_showWarning) {
      return ShadDialog(
        title: Text(translations.translate('edit_category')),
        description: Text(
          '${translations.translate('delete_category_desc_1')}${widget.affectedEventsCount}${translations.translate('delete_category_desc_2')}${widget.affectedHabitsCount}${translations.translate('delete_category_desc_3')}',
        ),
        actions: [
          ShadButton.outline(
            child: Text(translations.translate('cancel')),
            onPressed: () => setState(() => _showWarning = false),
          ),
          ShadButton(
            onPressed: _isLoading ? null : () => _performUpdate(),
            child: _isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(translations.translate('save_btn')),
          ),
        ],
      );
    }

    return ShadDialog(
      title: Text(translations.translate('edit_category')),
      description: Text(isSquad ? translations.translate('edit_category_desc_squad') : translations.translate('edit_category_desc_personal')),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.pop(context),
          child: Text(translations.translate('cancel')),
        ),
        ShadButton(
          onPressed: () {
            if (name.trim().isNotEmpty) {
              if (widget.affectedHabitsCount > 0 || widget.affectedEventsCount > 0) {
                setState(() => _showWarning = true);
              } else {
                _performUpdate();
              }
            }
          },
          child: Text(translations.translate('save_btn')),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(translations.translate('name'), style: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ShadInput(
              initialValue: name,
              placeholder: const Text('e.g. Work, Health, etc.'),
              onChanged: (val) => name = val,
            ),
            const SizedBox(height: 16),
            Text(translations.translate('color'), style: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colorPalette.entries.map((entry) {
                final colorName = entry.key;
                final color = entry.value;
                final isSelected = selectedColor == colorName;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColor = colorName;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class DeleteCategoryDialog extends ConsumerStatefulWidget {
  final EventCategory category;
  final int affectedHabitsCount;
  final int affectedEventsCount;
  final List<EventCategory> allCategories;

  const DeleteCategoryDialog({
    super.key,
    required this.category,
    required this.affectedHabitsCount,
    required this.affectedEventsCount,
    required this.allCategories,
  });

  @override
  ConsumerState<DeleteCategoryDialog> createState() => _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends ConsumerState<DeleteCategoryDialog> {
  bool _isReplacing = false;
  String? _selectedReplacementId;
  bool _isLoading = false;

  Future<void> _performDelete({String? replacementId}) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(eventCategoriesProvider(squadId: widget.category.squadId).notifier)
         .deleteCategory(widget.category.id, replacementCategoryId: replacementId);
      ref.invalidate(habitsProvider);
      ref.invalidate(eventsProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete category: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableCategories = widget.allCategories.where((c) => c.id != widget.category.id).toList();
    final translations = ref.watch(translationsProvider);

    return ShadDialog(
      title: Text(translations.translate('delete_category')),
      description: Text(
        '${translations.translate('delete_category_desc_1')}${widget.affectedEventsCount}${translations.translate('delete_category_desc_2')}${widget.affectedHabitsCount}${translations.translate('delete_category_desc_3')}',
      ),
      actions: [
        if (!_isReplacing) ...[
          ShadButton.outline(
            child: Text(translations.translate('cancel')),
            onPressed: () => Navigator.of(context).pop(),
          ),
          if (availableCategories.isNotEmpty)
            ShadButton.secondary(
               child: Text(translations.translate('replace_items')),
               onPressed: () => setState(() => _isReplacing = true),
            ),
          ShadButton.destructive(
            onPressed: _isLoading ? null : () => _performDelete(),
            child: _isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(translations.translate('delete_btn')),
          ),
        ] else ...[
          ShadButton.outline(
            child: Text(translations.translate('cancel')),
            onPressed: () => setState(() => _isReplacing = false),
          ),
          ShadButton(
            onPressed: _isLoading || _selectedReplacementId == null
                ? null 
                : () => _performDelete(replacementId: _selectedReplacementId),
            child: _isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(translations.translate('confirm_replace_delete')),
          ),
        ],
      ],
      child: _isReplacing
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(translations.translate('select_replacement_category')),
                  const SizedBox(height: 8),
                  ShadSelect<String>(
                    placeholder: Text(translations.translate('select_category')),
                    initialValue: _selectedReplacementId,
                    onChanged: (val) {
                      setState(() {
                        _selectedReplacementId = val;
                      });
                    },
                    options: availableCategories.map((c) {
                      return ShadOption(
                        value: c.id,
                        child: Text(c.name),
                      );
                    }).toList(),
                    selectedOptionBuilder: (context, value) {
                      final c = availableCategories.firstWhere((cat) => cat.id == value);
                      return Text(c.name);
                    },
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
