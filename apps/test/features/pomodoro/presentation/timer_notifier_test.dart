import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/features/pomodoro/domain/pomodoro_state.dart';
import 'package:habit_tracker/features/pomodoro/presentation/timer_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  ProviderContainer makeProviderContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('TimerNotifier', () {
    test('initial state is correct', () {
      final container = makeProviderContainer();
      final state = container.read(timerProvider);

      expect(state.status, TimerStatus.initial);
      expect(state.remainingSeconds, 25 * 60);
      expect(state.lastResumeTime, isNull);
    });

    test('start() changes status to running and updates lastResumeTime', () {
      final container = makeProviderContainer();
      final notifier = container.read(timerProvider.notifier);

      notifier.start();
      final state = container.read(timerProvider);

      expect(state.status, TimerStatus.running);
      expect(state.lastResumeTime, isNotNull);
    });

    test('pause() changes status to paused and clears lastResumeTime', () {
      final container = makeProviderContainer();
      final notifier = container.read(timerProvider.notifier);

      notifier.start();
      notifier.pause();
      final state = container.read(timerProvider);

      expect(state.status, TimerStatus.paused);
      expect(state.lastResumeTime, isNull);
    });

    test('reset() restores initial state', () {
      final container = makeProviderContainer();
      final notifier = container.read(timerProvider.notifier);

      notifier.start();
      notifier.reset();
      final state = container.read(timerProvider);

      expect(state.status, TimerStatus.initial);
      expect(state.remainingSeconds, 25 * 60);
      expect(state.lastResumeTime, isNull);
    });
  });
}
