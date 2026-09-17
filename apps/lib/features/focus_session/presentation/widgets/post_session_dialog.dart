import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/network/api_service.dart';
import '../../../calendar/domain/models/event_model.dart';
import '../../../calendar/presentation/events_provider.dart';
import '../../../habits/presentation/habits_provider.dart';
import '../../../habits/presentation/providers/heatmap_provider.dart';
import '../../../../core/localization/locale_provider.dart';

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
    final translations = ref.read(translationsProvider);
    
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
          ShadToast.destructive(title: Text(translations.translate('error_title')), description: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final targetMins = widget.targetSeconds ~/ 60;
    final actualMins = widget.actualSeconds ~/ 60;
    final translations = ref.watch(translationsProvider);

    return ShadDialog(
      title: Text(translations.translate('session_complete')),
      description: Text('${translations.translate('focused_minutes')} $actualMins ${translations.translate('minutes_label')}'),
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
                _buildStat(translations.translate('target'), '$targetMins ${translations.translate('min_suffix')}', theme),
                _buildStat(translations.translate('actual'), '$actualMins ${translations.translate('min_suffix')}', theme),
              ],
            ),
            const SizedBox(height: 24),
            
            // Options
            if (widget.actualSeconds > widget.targetSeconds) ...[
              Text(
                translations.translate('overtime_question'),
                style: theme.textTheme.small,
              ),
              const SizedBox(height: 12),
              ShadSwitch(
                value: _updateCalendar,
                onChanged: (val) => setState(() => _updateCalendar = val),
                label: Text(translations.translate('update_calendar')),
              ),
            ],

            const SizedBox(height: 24),
            ShadButton(
              width: double.infinity,
              onPressed: _isSubmitting ? null : _submit,
              backgroundColor: Colors.green.shade600,
              child: _isSubmitting 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(translations.translate('mark_complete')),
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
