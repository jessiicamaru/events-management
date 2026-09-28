import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/calendar/presentation/providers/calendar_settings_provider.dart';
import 'package:habit_tracker/features/calendar/domain/models/calendar_event_style.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/settings/presentation/category_management_screen.dart';
class CalendarSettingsSheet extends ConsumerWidget {
  const CalendarSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final settings = ref.watch(calendarSettingsProvider);
    final translations = ref.watch(translationsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: theme.colorScheme.border)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(translations.translate('calendar_settings_title'), style: theme.textTheme.h4),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(translations.translate('visible_hours'), style: theme.textTheme.large),
            const SizedBox(height: 8),
            Text(
              translations.translate('visible_hours_desc'),
              style: theme.textTheme.muted,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(translations.translate('start_hour'), style: theme.textTheme.small),
                      const SizedBox(height: 8),
                      ShadSelect<int>(
                        placeholder: Text(translations.translate('start_hour')),
                        initialValue: settings.visibleStartHour,
                        options: List.generate(24, (index) => ShadOption(
                          value: index,
                          child: Text('$index:00'),
                        )),
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(calendarSettingsProvider.notifier).updateSettings(startHour: val);
                          }
                        },
                        selectedOptionBuilder: (context, value) => Text('$value:00'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(translations.translate('end_hour'), style: theme.textTheme.small),
                      const SizedBox(height: 8),
                      ShadSelect<int>(
                        placeholder: Text(translations.translate('end_hour')),
                        initialValue: settings.visibleEndHour,
                        options: List.generate(24, (index) => ShadOption(
                          value: index + 1,
                          child: Text('${index + 1}:00'),
                        )),
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(calendarSettingsProvider.notifier).updateSettings(endHour: val);
                          }
                        },
                        selectedOptionBuilder: (context, value) => Text('$value:00'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(translations.translate('event_style'), style: theme.textTheme.large),
            const SizedBox(height: 8),
            Text(
              translations.translate('event_style_desc'),
              style: theme.textTheme.muted,
            ),
            const SizedBox(height: 16),
            ShadSelect<CalendarEventStyle>(
              placeholder: Text(translations.translate('style')),
              initialValue: settings.eventStyle,
              options: CalendarEventStyle.values.map((style) {
                String label = '';
                switch (style) {
                  case CalendarEventStyle.dot:
                    label = translations.translate('style_dot');
                    break;
                  case CalendarEventStyle.colored:
                    label = translations.translate('style_colored');
                    break;
                  case CalendarEventStyle.mixed:
                    label = translations.translate('style_mixed');
                    break;
                }
                return ShadOption(
                  value: style,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(calendarSettingsProvider.notifier).updateSettings(eventStyle: val);
                }
              },
              selectedOptionBuilder: (context, value) {
                switch (value) {
                  case CalendarEventStyle.dot:
                    return Text(translations.translate('style_dot'));
                  case CalendarEventStyle.colored:
                    return Text(translations.translate('style_colored'));
                  case CalendarEventStyle.mixed:
                    return Text(translations.translate('style_mixed'));
                }
              },
            ),
            const SizedBox(height: 24),
            ShadButton.outline(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const CategoryManagementScreen(),
                ));
              },
              child: Text(translations.translate('manage_categories')),
            ),
            const SizedBox(height: 16),
            ShadButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(translations.translate('done')),
            ),
          ],
        ),
      ),
    );
  }
}
