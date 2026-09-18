import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/calendar_settings_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/calendar_event_style.dart';
import '../../../../core/localization/locale_provider.dart';
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
            Text('Event Style', style: theme.textTheme.large),
            const SizedBox(height: 8),
            Text(
              'Choose how events look on the calendar.',
              style: theme.textTheme.muted,
            ),
            const SizedBox(height: 16),
            ShadSelect<CalendarEventStyle>(
              placeholder: const Text('Style'),
              initialValue: settings.eventStyle,
              options: CalendarEventStyle.values.map((style) {
                String label = '';
                switch (style) {
                  case CalendarEventStyle.dot: label = 'Dot'; break;
                  case CalendarEventStyle.colored: label = 'Colored'; break;
                  case CalendarEventStyle.mixed: label = 'Mixed'; break;
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
                  case CalendarEventStyle.dot: return const Text('Dot');
                  case CalendarEventStyle.colored: return const Text('Colored');
                  case CalendarEventStyle.mixed: return const Text('Mixed');
                  default: return const Text('Unknown');
                }
              },
            ),
            const SizedBox(height: 32),
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
