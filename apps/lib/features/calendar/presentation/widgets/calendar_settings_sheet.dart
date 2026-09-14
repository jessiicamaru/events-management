import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/calendar_settings_provider.dart';
import '../../../../core/theme/app_theme.dart';

class CalendarSettingsSheet extends ConsumerWidget {
  const CalendarSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final settings = ref.watch(calendarSettingsProvider);

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
                Text('Calendar Settings', style: theme.textTheme.h4),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Visible Hours', style: theme.textTheme.large),
            const SizedBox(height: 8),
            Text(
              'Select the time range visible in the calendar grid.',
              style: theme.textTheme.muted,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start Hour', style: theme.textTheme.small),
                      const SizedBox(height: 8),
                      ShadSelect<int>(
                        placeholder: const Text('Start'),
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
                      Text('End Hour', style: theme.textTheme.small),
                      const SizedBox(height: 8),
                      ShadSelect<int>(
                        placeholder: const Text('End'),
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
            const SizedBox(height: 32),
            ShadButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
