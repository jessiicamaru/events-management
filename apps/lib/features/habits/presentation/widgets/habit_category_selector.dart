import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/features/calendar/presentation/providers/event_category_provider.dart';

class HabitCategorySelector extends ConsumerWidget {
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;

  const HabitCategorySelector({
    super.key,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = ref.watch(translationsProvider);
    final theme = ShadTheme.of(context);
    final categoriesAsync = ref.watch(eventCategoriesProvider(squadId: null));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          translations.translate('category'),
          style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return Text(
                translations.translate('no_categories_yet'),
                style: theme.textTheme.small.copyWith(color: theme.colorScheme.mutedForeground),
              );
            }
            return ShadSelect<String>(
              placeholder: Text(translations.translate('select_category')),
              initialValue: selectedCategoryId,
              onChanged: onCategoryChanged,
              options: categories.map((cat) {
                return ShadOption(
                  value: cat.id,
                  child: Text(cat.name),
                );
              }).toList(),
              selectedOptionBuilder: (context, value) {
                final cat = categories.firstWhere((c) => c.id == value, orElse: () => categories.first);
                return Text(cat.name);
              },
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (err, stack) => Text(err.toString()),
        ),
      ],
    );
  }
}
