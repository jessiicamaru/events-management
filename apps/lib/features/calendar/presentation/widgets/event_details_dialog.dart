import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../domain/models/event_model.dart';
import '../../../habits/domain/models/habit_model.dart';

class EventDetailsDialog extends StatelessWidget {
  final EventModel event;
  final HabitModel habit;

  const EventDetailsDialog({
    super.key,
    required this.event,
    required this.habit,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return ShadDialog(
      title: Text(event.title),
      description: const Text('Event Details'),
      actions: [
        ShadButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
      child: Container(
        width: 350,
        padding: const EdgeInsets.symmetric(vertical: 16),
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
          ],
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
