import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../calendar_screen.dart';
import '../providers/category_filter_provider.dart';
import 'calendar_settings_sheet.dart';
import '../../../../core/localization/locale_provider.dart';

class CalendarToolbar extends ConsumerWidget {
  final DateTime displayDate;
  final AppCalendarView currentView;
  final ValueChanged<AppCalendarView> onViewChanged;
  final VoidCallback onTodayPressed;
  final VoidCallback onNextPressed;
  final VoidCallback onPrevPressed;
  final int totalEvents;

  const CalendarToolbar({
    super.key,
    required this.displayDate,
    required this.currentView,
    required this.onViewChanged,
    required this.onTodayPressed,
    required this.onNextPressed,
    required this.onPrevPressed,
    required this.totalEvents,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final currentLocale = ref.watch(localeProvider);
    final translations = ref.watch(translationsProvider);
    final localeStr = currentLocale == AppLocale.en ? 'en_US' : 'vi';
    final monthFormat = DateFormat('MMMM yyyy', localeStr);
    final shortMonthFormat = DateFormat('MMM', localeStr);
    final selectedCategory = ref.watch(categoryFilterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Date Block + Month vs Navigator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Date Block and Month Text
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date Block
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          color: theme.colorScheme.primary,
                          child: Text(
                            shortMonthFormat.format(displayDate).toUpperCase(),
                            style: theme.textTheme.small.copyWith(color: theme.colorScheme.primaryForeground, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          color: theme.colorScheme.background,
                          child: Text(
                            displayDate.day.toString(),
                            style: theme.textTheme.large.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Month Text and Badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthFormat.format(displayDate),
                        style: theme.textTheme.h4,
                      ),
                      const SizedBox(height: 4),
                      ShadBadge.secondary(
                        child: Text('$totalEvents ${translations.translate('events_count')}'),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Right: Navigator
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShadButton.outline(
                    width: 32,
                    height: 32,
                    padding: EdgeInsets.zero,
                    onPressed: onPrevPressed,
                    child: const Icon(LucideIcons.chevronLeft, size: 16),
                  ),
                  const SizedBox(width: 8),
                  ShadButton.outline(
                    width: 32,
                    height: 32,
                    padding: EdgeInsets.zero,
                    onPressed: onNextPressed,
                    child: const Icon(LucideIcons.chevronRight, size: 16),
                  ),
                  const SizedBox(width: 8),
                  ShadButton.outline(
                    width: 32,
                    height: 32,
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => const CalendarSettingsSheet(),
                      );
                    },
                    child: const Icon(LucideIcons.settings, size: 16),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bottom Row: View Switcher vs Category Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // View Switcher (Icons)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewButton(AppCalendarView.day, LucideIcons.layoutList, theme),
                    _buildViewButton(AppCalendarView.threeDay, LucideIcons.columns, theme),
                    _buildViewButton(AppCalendarView.month, LucideIcons.calendarDays, theme),
                  ],
                ),
              ),
              
              // Category Filter Dropdown
              SizedBox(
                width: 180,
                child: ShadSelect<String>(
                  initialValue: selectedCategory ?? 'All',
                  placeholder: Text(translations.translate('all_categories')),
                  onChanged: (value) => ref.read(categoryFilterProvider.notifier).setCategory(value == 'All' ? null : value),
                  options: [
                    ShadOption(value: 'All', child: Text(translations.translate('all_categories'))),
                    ShadOption(value: 'Health', child: Text(translations.translate('category_health'))),
                    ShadOption(value: 'Work', child: Text(translations.translate('category_work'))),
                    ShadOption(value: 'Learning', child: Text(translations.translate('category_learning'))),
                    ShadOption(value: 'Wellness', child: Text(translations.translate('category_wellness'))),
                  ],
                  selectedOptionBuilder: (context, value) {
                    if (value == 'All') return Text(translations.translate('all_categories'));
                    if (value == 'Health') return Text(translations.translate('category_health'));
                    if (value == 'Work') return Text(translations.translate('category_work'));
                    if (value == 'Learning') return Text(translations.translate('category_learning'));
                    if (value == 'Wellness') return Text(translations.translate('category_wellness'));
                    return Text(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(AppCalendarView view, IconData icon, ShadThemeData theme) {
    final isSelected = currentView == view;
    return GestureDetector(
      onTap: () => onViewChanged(view),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4), // slightly inner radius
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? theme.colorScheme.primaryForeground : theme.colorScheme.foreground,
        ),
      ),
    );
  }
}
