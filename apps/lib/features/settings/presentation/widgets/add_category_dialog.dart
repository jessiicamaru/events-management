import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/calendar/presentation/providers/event_category_provider.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/settings/presentation/category_management_screen.dart'
    show colorPalette;

class AddCategoryDialog extends StatefulWidget {
  final bool isSquad;
  final AppTranslations translations;

  const AddCategoryDialog({
    super.key,
    required this.isSquad,
    required this.translations,
  });

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  String name = '';
  String selectedColor = 'Slate';

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadDialog(
      title: Text(widget.translations.translate('new_category')),
      description: Text(
        widget.isSquad
            ? widget.translations.translate('create_squad_category_desc')
            : widget.translations.translate('create_personal_category_desc'),
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.translations.translate('cancel')),
        ),
        Consumer(
          builder: (context, ref, child) {
            return ShadButton(
              onPressed: () {
                if (name.trim().isNotEmpty) {
                  ref
                      .read(
                        eventCategoriesProvider(
                          squadId: widget.isSquad ? 'TODO_SQUAD_ID' : null,
                        ).notifier,
                      )
                      .addCategory(name.trim(), selectedColor);
                  Navigator.pop(context);
                }
              },
              child: Text(widget.translations.translate('save_btn')),
            );
          },
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.translations.translate('name'),
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ShadInput(
              placeholder: const Text('e.g. Work, Health, etc.'),
              onChanged: (val) => name = val,
            ),
            const SizedBox(height: 24),
            Text(
              'Color',
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colorPalette.entries.map((e) {
                final isSelected = selectedColor == e.key;
                return GestureDetector(
                  onTap: () => setState(() => selectedColor = e.key),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: e.value,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.foreground,
                              width: 2,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: e.value.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
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
