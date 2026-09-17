import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/pomodoro_state.dart';
import 'timer_notifier.dart';
import '../../../core/localization/locale_provider.dart';

class PomodoroScreen extends ConsumerWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timerProvider);
    final notifier = ref.read(timerProvider.notifier);
    final translations = ref.watch(translationsProvider);

    final minutes = (state.remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (state.remainingSeconds % 60).toString().padLeft(2, '0');

    String translatedStatus = translations.translate('status_ready');
    if (state.status == TimerStatus.running) {
      translatedStatus = translations.translate('status_running');
    } else if (state.status == TimerStatus.paused) {
      translatedStatus = translations.translate('status_paused');
    }

    return Scaffold(
      appBar: AppBar(title: Text(translations.translate('pomodoro_timer'))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$minutes:$seconds',
              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('${translations.translate('status_label')}: $translatedStatus'),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.status == TimerStatus.initial || state.status == TimerStatus.paused)
                  ElevatedButton(
                    onPressed: notifier.start,
                    child: Text(translations.translate('start')),
                  ),
                if (state.status == TimerStatus.running)
                  ElevatedButton(
                    onPressed: notifier.pause,
                    child: Text(translations.translate('pause')),
                  ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: notifier.reset,
                  child: Text(translations.translate('reset')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
