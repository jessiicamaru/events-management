import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class TimerControls extends StatelessWidget {
  final bool isRunning;
  final bool isPaused;
  final bool isTargetReached;
  final bool isOvertime;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;
  final VoidCallback onExpandTime;

  const TimerControls({
    super.key,
    this.isRunning = false,
    this.isPaused = false,
    this.isTargetReached = false,
    this.isOvertime = false,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
    required this.onExpandTime,
  });

  @override
  Widget build(BuildContext context) {
    if (isTargetReached) {
      return Column(
        children: [
          ShadButton(
            width: double.infinity,
            backgroundColor: Colors.green.shade600,
            onPressed: onFinish,
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
            onPressed: onExpandTime,
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

    if (isOvertime) {
      return ShadButton(
        width: double.infinity,
        backgroundColor: Colors.amber.shade600,
        onPressed: onFinish,
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isRunning)
          Expanded(
            child: ShadButton.outline(
              onPressed: onPause,
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
        if (isPaused)
          Expanded(
            child: ShadButton(
              onPressed: onResume,
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
          child: ShadButton(
            onPressed: onFinish,
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
}
