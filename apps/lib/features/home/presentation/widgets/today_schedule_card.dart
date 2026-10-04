import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';

/// What is still to come today, after the event on the card above.
class TodayScheduleCard extends ConsumerWidget {
  const TodayScheduleCard({super.key, required this.events});

  final List<EventModel> events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);

    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            translations.translate('home_rest_of_today'),
            style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Text(
              translations.translate('home_nothing_left_today'),
              style: theme.textTheme.muted,
            )
          else
            for (final event in events) _EventRow(event: event),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final start = event.startTime.toLocal();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              DateFormat.Hm().format(start),
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Text(
              event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.small.copyWith(
                // A completed event still belongs on the list — it is part of the
                // shape of the day — but it should not compete for attention.
                decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                color: event.isCompleted
                    ? theme.colorScheme.mutedForeground
                    : theme.colorScheme.foreground,
              ),
            ),
          ),
          if (event.reminderMinutesBefore.isNotEmpty) ...[
            const SizedBox(width: 8),
            Icon(
              LucideIcons.bell,
              size: 13,
              color: theme.colorScheme.mutedForeground,
            ),
          ],
        ],
      ),
    );
  }
}
