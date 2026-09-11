import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/network/api_service.dart';
import '../../../calendar/domain/models/event_model.dart';
import '../../../calendar/presentation/events_provider.dart';
import '../../../habits/presentation/habits_provider.dart';
import '../../../habits/presentation/providers/heatmap_provider.dart';

class PostSessionDialog extends ConsumerStatefulWidget {
  final EventModel event;
  final int actualSeconds;
  final int targetSeconds;

  const PostSessionDialog({
    super.key,
    required this.event,
    required this.actualSeconds,
    required this.targetSeconds,
  });

  @override
  ConsumerState<PostSessionDialog> createState() => _PostSessionDialogState();
}

class _PostSessionDialogState extends ConsumerState<PostSessionDialog> {
  bool _updateCalendar = false;
  bool _isSubmitting = false;

  String _formatTime(int seconds) {
    final m = (seconds / 60).floor().toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '00:$m:$s'; // Backend expects TimeSpan, simple HH:MM:SS format
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    
    try {
      final actualDurationStr = _formatTime(widget.actualSeconds);
      
      await ref.read(apiServiceProvider).completeSession(
        widget.event.id,
        actualDurationStr,
        _updateCalendar,
      );

      if (mounted) {
        // Invalidate state to refresh UI
        ref.invalidate(eventsProvider);
        ref.invalidate(habitsProvider);
        ref.invalidate(heatmapProvider);

        // Pop the dialog
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ShadToaster.of(context).show(
          ShadToast.destructive(title: const Text('Error'), description: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final targetMins = widget.targetSeconds ~/ 60;
    final actualMins = widget.actualSeconds ~/ 60;

    return ShadDialog(
      title: const Text('Session Complete!'),
      description: Text('You focused for $actualMins minutes.'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Target', '$targetMins m', theme),
                _buildStat('Actual', '$actualMins m', theme),
              ],
            ),
            const SizedBox(height: 24),
            
            // Options
            if (widget.actualSeconds > widget.targetSeconds) ...[
              Text(
                'You went overtime! Do you want to update the calendar to reflect your actual time?',
                style: theme.textTheme.small,
              ),
              const SizedBox(height: 12),
              ShadSwitch(
                value: _updateCalendar,
                onChanged: (val) => setState(() => _updateCalendar = val),
                label: const Text('Update Calendar'),
              ),
            ],

            const SizedBox(height: 24),
            ShadButton(
              width: double.infinity,
              onPressed: _isSubmitting ? null : _submit,
              backgroundColor: Colors.green.shade600,
              child: _isSubmitting 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Mark as Complete'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, ShadThemeData theme) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.small.copyWith(color: theme.colorScheme.mutedForeground)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.h4),
      ],
    );
  }
}
