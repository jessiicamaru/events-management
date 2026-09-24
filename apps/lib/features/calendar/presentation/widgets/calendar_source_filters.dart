import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';

enum CalendarSourceFilter { all, personal, squads }

class CalendarSourceFilters extends ConsumerWidget {
  final CalendarSourceFilter currentFilter;
  final ValueChanged<CalendarSourceFilter> onFilterChanged;

  const CalendarSourceFilters({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  Widget _buildFilterPill(String label, CalendarSourceFilter filter, ShadThemeData theme) {
    final isSelected = currentFilter == filter;
    return GestureDetector(
      onTap: () => onFilterChanged(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.muted,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: theme.textTheme.small.copyWith(
            color: isSelected ? theme.colorScheme.primaryForeground : theme.colorScheme.foreground,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = ref.watch(translationsProvider);
    final theme = ShadTheme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterPill(translations.translate('filter_all'), CalendarSourceFilter.all, theme),
          const SizedBox(width: 8),
          _buildFilterPill(translations.translate('filter_personal'), CalendarSourceFilter.personal, theme),
          const SizedBox(width: 8),
          _buildFilterPill(translations.translate('filter_squads'), CalendarSourceFilter.squads, theme),
        ],
      ),
    );
  }
}
