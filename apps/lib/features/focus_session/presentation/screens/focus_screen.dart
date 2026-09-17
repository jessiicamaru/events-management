import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/utils/app_constants.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';
import 'package:habit_tracker/features/focus_session/presentation/providers/timer_provider.dart';
import 'package:habit_tracker/features/focus_session/domain/models/timer_state.dart';
import 'package:habit_tracker/features/focus_session/presentation/widgets/post_session_dialog.dart';
import 'package:habit_tracker/features/focus_session/presentation/widgets/timer_display.dart';
import 'package:habit_tracker/features/focus_session/presentation/widgets/timer_controls.dart';
import '../../../../core/localization/locale_provider.dart';

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
    final translations = ref.watch(translationsProvider);

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
                translations.translate('focus_session_title'),
                style: theme.textTheme.h2,
              ),
              const SizedBox(height: 8),
              Text(
                translations.translate(widget.event.title),
                style: theme.textTheme.large.copyWith(color: theme.colorScheme.mutedForeground),
              ),
              const Spacer(),

              // Timer Display
              state.maybeMap(
                initial: (_) => const CircularProgressIndicator(),
                running: (s) => TimerDisplay(remaining: s.remainingSeconds, isPaused: false),
                paused: (s) => TimerDisplay(remaining: s.remainingSeconds, isPaused: true),
                targetReached: (_) => const TimerDisplay(isTargetReached: true),
                overtime: (s) => TimerDisplay(overtime: s.overtimeSeconds),
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
                running: (_) => TimerControls(
                  isRunning: true,
                  onPause: () => ref.read(timerProvider.notifier).pause(),
                  onResume: () {},
                  onFinish: () => ref.read(timerProvider.notifier).finish(),
                  onExpandTime: () {},
                ),
                paused: (_) => TimerControls(
                  isPaused: true,
                  onPause: () {},
                  onResume: () => ref.read(timerProvider.notifier).resume(),
                  onFinish: () => ref.read(timerProvider.notifier).finish(),
                  onExpandTime: () {},
                ),
                targetReached: (_) => TimerControls(
                  isTargetReached: true,
                  onPause: () {},
                  onResume: () {},
                  onFinish: () => ref.read(timerProvider.notifier).finish(),
                  onExpandTime: () => ref.read(timerProvider.notifier).startOvertime(),
                ),
                overtime: (_) => TimerControls(
                  isOvertime: true,
                  onPause: () {},
                  onResume: () {},
                  onFinish: () => ref.read(timerProvider.notifier).finish(),
                  onExpandTime: () {},
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
