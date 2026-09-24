import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../events_provider.dart';
import '../../../habits/presentation/habits_provider.dart';
import '../../domain/models/event_model.dart';
import '../../../habits/domain/models/habit_model.dart';
import 'event_tasks_checklist.dart';
import '../../../focus_session/presentation/screens/focus_screen.dart';
import '../../../focus_session/presentation/widgets/post_session_dialog.dart';

class CommandCenterPanel extends ConsumerWidget {
  const CommandCenterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final habitsAsync = ref.watch(habitsProvider);
    final translations = ref.watch(translationsProvider);
    final currentLocale = ref.watch(localeProvider);
    final localeStr = currentLocale == AppLocale.en ? 'en_US' : 'vi';
    final theme = ShadTheme.of(context);

    // Look for current or upcoming event across all days
    final now = DateTime.now();
    final allEvents = List<EventModel>.from(eventsAsync.value ?? []);
    allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

    EventModel? activeEvent;
    
    // 1. First, try to find an event that is currently happening
    for (var event in allEvents) {
      if (now.isAfter(event.startTime) && now.isBefore(event.endTime)) {
        activeEvent = event;
        break;
      }
    }

    // 2. If no event is currently happening, find the next upcoming event
    if (activeEvent == null) {
      for (var event in allEvents) {
        if (now.isBefore(event.startTime) && !event.isCompleted) {
          activeEvent = event;
          break;
        }
      }
    }

    if (activeEvent == null) {
      return const SizedBox.shrink();
    }

    final habit = habitsAsync.value?.firstWhere(
      (h) => h.id == activeEvent!.habitId,
      orElse: () => HabitModel(id: '', name: 'Unknown', targetDays: []),
    );

    final habitColor = habit != null ? AppTheme.getHabitColor(habit.category) : theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        border: Border(top: BorderSide(color: theme.colorScheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: habitColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          translations.translate('up_next'),
                          style: theme.textTheme.small.copyWith(color: theme.colorScheme.mutedForeground),
                        ),
                        Text(
                          activeEvent.title,
                          style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('MMM d', localeStr).format(activeEvent.startTime.toLocal()),
                        style: theme.textTheme.small.copyWith(color: theme.colorScheme.mutedForeground),
                      ),
                      Text(
                        '${DateFormat.Hm().format(activeEvent.startTime.toLocal())} - ${DateFormat.Hm().format(activeEvent.endTime.toLocal())}',
                        style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: EventTasksChecklist(eventId: activeEvent.id),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ShadButton(
                onPressed: () async {
                  final focusResult = await Navigator.of(context).push<Map<String, int>>(
                    MaterialPageRoute(
                      builder: (_) => FocusScreen(event: activeEvent!),
                    ),
                  );
                  if (focusResult != null && context.mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => PostSessionDialog(
                        event: activeEvent!,
                        actualSeconds: focusResult['actual']!,
                        targetSeconds: focusResult['target']!,
                      ),
                    );
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.playCircle, size: 18),
                    const SizedBox(width: 8),
                    Text(translations.translate('start_session')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
