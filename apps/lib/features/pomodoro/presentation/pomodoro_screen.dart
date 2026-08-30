import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/pomodoro_state.dart';
import 'timer_notifier.dart';

class PomodoroScreen extends ConsumerWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timerProvider);
    final notifier = ref.read(timerProvider.notifier);

    final minutes = (state.remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (state.remainingSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro Timer')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$minutes:$seconds',
              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Status: ${state.status.name.toUpperCase()}'),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.status == TimerStatus.initial || state.status == TimerStatus.paused)
                  ElevatedButton(
                    onPressed: notifier.start,
                    child: const Text('Start'),
                  ),
                if (state.status == TimerStatus.running)
                  ElevatedButton(
                    onPressed: notifier.pause,
                    child: const Text('Pause'),
                  ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: notifier.reset,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
