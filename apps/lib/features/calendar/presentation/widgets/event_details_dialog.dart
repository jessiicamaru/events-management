import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../domain/models/event_model.dart';
import '../../../habits/domain/models/habit_model.dart';

import '../events_provider.dart';

class EventDetailsDialog extends ConsumerWidget {
  final EventModel event;
  final HabitModel habit;

  const EventDetailsDialog({
    super.key,
    required this.event,
    required this.habit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('EEEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final theme = ShadTheme.of(context);

    return ShadDialog(
      title: Text(event.title),
      description: const Text('Event Details'),
      actions: const [], // We will move the close button to the bottom of the child for better layout
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, LucideIcons.calendar, 'Date', dateFormat.format(event.startTime)),
            const SizedBox(height: 12),
            _buildDetailRow(context, LucideIcons.clock, 'Time', '${timeFormat.format(event.startTime)} - ${timeFormat.format(event.endTime)}'),
            const SizedBox(height: 12),
            _buildDetailRow(context, LucideIcons.tag, 'Category', habit.category ?? 'Uncategorized'),
            const SizedBox(height: 12),
            _buildDetailRow(context, LucideIcons.checkCircle, 'Status', event.isCompleted ? 'Completed' : 'Pending'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ShadButton(
                backgroundColor: event.isCompleted ? theme.colorScheme.destructive : Colors.green,
                hoverBackgroundColor: event.isCompleted ? theme.colorScheme.destructive.withOpacity(0.9) : Colors.green.withOpacity(0.9),
                onPressed: () {
                  ref.read(eventsProvider.notifier).toggleEvent(event.id, !event.isCompleted);
                  Navigator.of(context).pop();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(event.isCompleted ? LucideIcons.xCircle : LucideIcons.checkCircle, size: 16),
                    const SizedBox(width: 8),
                    Text(event.isCompleted ? 'Mark as Pending' : 'Mark as Completed'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ShadButton.outline(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final theme = ShadTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.mutedForeground),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.small.copyWith(color: theme.colorScheme.mutedForeground)),
            const SizedBox(height: 2),
            Text(value, style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}
