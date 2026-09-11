import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/utils/app_constants.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';
import 'package:habit_tracker/features/focus_session/presentation/providers/timer_provider.dart';
import 'package:habit_tracker/features/focus_session/domain/models/timer_state.dart';
import 'package:habit_tracker/features/focus_session/presentation/widgets/post_session_dialog.dart';

class FocusScreen extends ConsumerStatefulWidget {
  final EventModel event;

  const FocusScreen({super.key, required this.event});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  @override
  void initState() {
    super.initState();
    // Default to event duration, then 25 mins if not set or 0
    var targetMins = widget.event.targetDuration;
    if (targetMins == null || targetMins <= 0) {
      targetMins = widget.event.endTime.difference(widget.event.startTime).inMinutes;
      if (targetMins <= 0) targetMins = 25;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timerProvider.notifier).start(targetMins!);
    });
  }

  Future<void> _finishSession(int actualSeconds, int targetSeconds) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PostSessionDialog(
        event: widget.event,
        actualSeconds: actualSeconds,
        targetSeconds: targetSeconds,
      ),
    );
    
    // Always pop the focus screen regardless of whether they submitted or closed the dialog
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds / 60).floor().toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final state = ref.watch(timerProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              Text(
                'Focus Session',
                style: theme.textTheme.h2,
              ),
              const SizedBox(height: 8),
              Text(
                widget.event.title,
                style: theme.textTheme.large.copyWith(color: theme.colorScheme.mutedForeground),
              ),
              const Spacer(),

              // Timer Display
              state.maybeMap(
                initial: (_) => const CircularProgressIndicator(),
                running: (s) => _buildTimerDisplay(s.remainingSeconds, theme, false),
                paused: (s) => _buildTimerDisplay(s.remainingSeconds, theme, true),
                targetReached: (_) => _buildTargetReachedDisplay(theme),
                overtime: (s) => _buildOvertimeDisplay(s.overtimeSeconds, theme),
                finished: (s) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _finishSession(s.actualDurationSeconds, s.targetDurationSeconds);
                  });
                  return const SizedBox.shrink();
                },
                orElse: () => const SizedBox.shrink(),
              ),

              const Spacer(),

              // Controls
              state.maybeMap(
                running: (_) => _buildRunningControls(theme),
                paused: (_) => _buildPausedControls(theme),
                targetReached: (_) => _buildTargetReachedControls(theme),
                overtime: (_) => _buildOvertimeControls(theme),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerDisplay(int remaining, ShadThemeData theme, bool isPaused) {
    return Column(
      children: [
        Text(
          _formatTime(remaining),
          style: theme.textTheme.h1.copyWith(
            fontSize: 72,
            fontWeight: FontWeight.w700,
            color: isPaused ? theme.colorScheme.mutedForeground : theme.colorScheme.foreground,
          ),
        ),
        if (isPaused)
          Text('PAUSED', style: theme.textTheme.small.copyWith(color: theme.colorScheme.mutedForeground, letterSpacing: 2)),
      ],
    );
  }

  Widget _buildTargetReachedDisplay(ShadThemeData theme) {
    return Column(
      children: [
        Icon(LucideIcons.partyPopper, size: 64, color: Colors.green.shade400),
        const SizedBox(height: 16),
        Text(
          'Target Reached!',
          style: theme.textTheme.h2.copyWith(color: Colors.green.shade400),
        ),
      ],
    );
  }

  Widget _buildOvertimeDisplay(int overtime, ShadThemeData theme) {
    return Column(
      children: [
        Text(
          '+${_formatTime(overtime)}',
          style: theme.textTheme.h1.copyWith(
            fontSize: 72,
            fontWeight: FontWeight.w700,
            color: Colors.amber.shade600,
          ),
        ),
        Text('OVERTIME', style: theme.textTheme.small.copyWith(color: Colors.amber.shade600, letterSpacing: 2)),
      ],
    );
  }

  Widget _buildRunningControls(ShadThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: ShadButton.outline(
            onPressed: () => ref.read(timerProvider.notifier).pause(),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.pause, size: 18),
                SizedBox(width: 8),
                Text('Pause'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ShadButton(
            onPressed: () => ref.read(timerProvider.notifier).finish(),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.check, size: 18),
                SizedBox(width: 8),
                Text('Finish Now'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPausedControls(ShadThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: ShadButton(
            onPressed: () => ref.read(timerProvider.notifier).resume(),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.play, size: 18),
                SizedBox(width: 8),
                Text('Resume'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ShadButton.outline(
            onPressed: () => ref.read(timerProvider.notifier).finish(),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.check, size: 18),
                SizedBox(width: 8),
                Text('Finish Now'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetReachedControls(ShadThemeData theme) {
    return Column(
      children: [
        ShadButton(
          width: double.infinity,
          backgroundColor: Colors.green.shade600,
          onPressed: () => ref.read(timerProvider.notifier).finish(),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.check, size: 18),
              SizedBox(width: 8),
              Text('Complete Session'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ShadButton.outline(
          width: double.infinity,
          onPressed: () => ref.read(timerProvider.notifier).startOvertime(),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.plus, size: 18),
              SizedBox(width: 8),
              Text('Expand Time'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOvertimeControls(ShadThemeData theme) {
    return ShadButton(
      width: double.infinity,
      backgroundColor: Colors.amber.shade600,
      onPressed: () => ref.read(timerProvider.notifier).finish(),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.check, size: 18),
          SizedBox(width: 8),
          Text('Finish Session'),
        ],
      ),
    );
  }
}
