import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/localization/locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HabitCategorySelector extends ConsumerWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  const HabitCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = ref.watch(translationsProvider);
    final theme = ShadTheme.of(context);
    final categories = ['Uncategorized', 'Health', 'Work', 'Learning', 'Fitness'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          translations.translate('category'),
          style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            final isSelected = selectedCategory == cat;
            return GestureDetector(
              onTap: () => onCategoryChanged(cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.muted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  cat,
                  style: theme.textTheme.small.copyWith(
                    color: isSelected ? theme.colorScheme.primaryForeground : theme.colorScheme.foreground,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
