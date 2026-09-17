import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/localization/locale_provider.dart';

class TimerControls extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = ref.watch(translationsProvider);

    if (isTargetReached) {
      return Column(
        children: [
          ShadButton(
            width: double.infinity,
            backgroundColor: Colors.green.shade600,
            onPressed: onFinish,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.check, size: 18),
                const SizedBox(width: 8),
                Text(translations.translate('complete_session')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ShadButton.outline(
            width: double.infinity,
            onPressed: onExpandTime,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.plus, size: 18),
                const SizedBox(width: 8),
                Text(translations.translate('expand_time')),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.check, size: 18),
            const SizedBox(width: 8),
            Text(translations.translate('finish_session')),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.pause, size: 18),
                  const SizedBox(width: 8),
                  Text(translations.translate('pause')),
                ],
              ),
            ),
          ),
        if (isPaused)
          Expanded(
            child: ShadButton(
              onPressed: onResume,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.play, size: 18),
                  const SizedBox(width: 8),
                  Text(translations.translate('resume')),
                ],
              ),
            ),
          ),
        const SizedBox(width: 16),
        Expanded(
          child: ShadButton(
            onPressed: onFinish,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.check, size: 18),
                const SizedBox(width: 8),
                Text(translations.translate('finish_now')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
