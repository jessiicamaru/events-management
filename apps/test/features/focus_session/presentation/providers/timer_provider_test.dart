import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/features/focus_session/presentation/providers/timer_provider.dart';
import 'package:habit_tracker/features/focus_session/domain/models/timer_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Timer starts with initial state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(timerProvider);
    expect(state, const TimerState.initial());
  });

  test('Timer transitions to running on start', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(timerProvider.notifier);
    notifier.start(25); // 25 minutes

    final state = container.read(timerProvider);
    state.maybeMap(
      running: (s) {
        expect(s.targetDuration, 25 * 60);
        expect(s.remainingSeconds, 25 * 60);
      },
      orElse: () => fail('State should be running'),
    );
  });

  test('Timer transitions to paused on pause', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(timerProvider.notifier);
    notifier.start(25);
    notifier.pause();

    final state = container.read(timerProvider);
    state.maybeMap(
      paused: (s) {
        expect(s.targetDuration, 25 * 60);
        expect(s.remainingSeconds, 25 * 60);
      },
      orElse: () => fail('State should be paused'),
    );
  });

  test('Timer transitions to finished on finish', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(timerProvider.notifier);
    notifier.start(25);
    notifier.finish();

    final state = container.read(timerProvider);
    state.maybeMap(
      finished: (s) {
        expect(s.targetDurationSeconds, 25 * 60);
        expect(s.actualDurationSeconds, 0); // finished immediately
      },
      orElse: () => fail('State should be finished'),
    );
  });
}
