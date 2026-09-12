import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class TimerDisplay extends StatelessWidget {
  final int remaining;
  final bool isPaused;
  final bool isTargetReached;
  final int overtime;

  const TimerDisplay({
    super.key,
    this.remaining = 0,
    this.isPaused = false,
    this.isTargetReached = false,
    this.overtime = 0,
  });

  String _formatTime(int seconds) {
    final m = (seconds / 60).floor().toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    if (isTargetReached) {
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

    if (overtime > 0) {
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
}
