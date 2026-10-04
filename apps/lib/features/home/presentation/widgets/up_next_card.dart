import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/event_tasks_checklist.dart';
import 'package:habit_tracker/features/focus_session/presentation/screens/focus_screen.dart';
import 'package:habit_tracker/features/focus_session/presentation/widgets/post_session_dialog.dart';

/// The event to deal with next, its checklist, and the way into a focus session.
///
/// This is what used to be `CommandCenterPanel`, pinned under the calendar grid.
/// The recurrence expansion it carried — a fourth copy of the same loop — now lives
/// in `EventOccurrenceExpander`, reached through `HomeAgenda`, so this widget only
/// lays out an event it is handed.
class UpNextCard extends ConsumerWidget {
  const UpNextCard({
    super.key,
    required this.event,
    required this.isHappeningNow,
  });

  final EventModel event;

  /// Changes the label from "up next" to "happening now". The card is otherwise
  /// the same: the useful actions do not differ once an event has started.
  final bool isHappeningNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);
    final localeStr = ref.watch(localeProvider) == AppLocale.en ? 'en_US' : 'vi';

    final start = event.startTime.toLocal();
    final end = event.endTime.toLocal();

    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: isHappeningNow
                      ? theme.colorScheme.primary
                      : theme.colorScheme.mutedForeground,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translations.translate(
                        isHappeningNow ? 'home_happening_now' : 'up_next',
                      ),
                      style: theme.textTheme.small.copyWith(
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.title,
                      style: theme.textTheme.large.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('MMM d', localeStr).format(start),
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                  Text(
                    '${DateFormat.Hm().format(start)} - ${DateFormat.Hm().format(end)}',
                    style: theme.textTheme.small.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          EventTasksChecklist(eventId: event.id),
          const SizedBox(height: 16),
          ShadButton(
            onPressed: () => _startSession(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.playCircle, size: 18),
                const SizedBox(width: 8),
                Text(translations.translate('start_session')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSession(BuildContext context) async {
    final navigator = Navigator.of(context);

    final focusResult = await navigator.push<Map<String, int>>(
      MaterialPageRoute(builder: (_) => FocusScreen(event: event)),
    );

    if (focusResult == null || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PostSessionDialog(
        event: event,
        actualSeconds: focusResult['actual']!,
        targetSeconds: focusResult['target']!,
      ),
    );
  }
}
