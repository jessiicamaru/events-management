import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/home/presentation/providers/home_clock_provider.dart';
import 'package:habit_tracker/features/habits/domain/streak_at_risk.dart';

/// The clock exists for one reason: Home is a pure function of its providers, so without
/// it a screen open at 19:50 never shows the streak-at-risk card when 20:00 arrives.
void main() {
  // fakeAsync starts at the real DateTime.now() unless told otherwise, and the test below
  // steps back a minute from the cutoff: between 19:59:00 and 19:59:59 local that step was
  // negative and threw out of the test body.
  final morning = DateTime(2026, 9, 12, 9, 0);

  test('re-reads itself at the streak cutoff, and not before', () {
    fakeAsync(initialTime: morning, (async) {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      var emissions = 0;
      container.listen(homeClockProvider, (_, _) => emissions++, fireImmediately: false);

      final first = container.read(homeClockProvider);
      final cutoff = StreakAtRisk.nextCutoffAfter(first);
      final untilCutoff = cutoff.difference(first);

      // One minute short of the cutoff: nothing yet.
      async.elapse(untilCutoff - const Duration(minutes: 1));
      expect(emissions, 0, reason: 'no ticking in between');

      async.elapse(const Duration(minutes: 1, seconds: 1));
      expect(emissions, 1, reason: 'the cutoff rebuilt Home exactly once');

      // And it re-arms: the next cutoff is a day later, not immediately.
      async.elapse(const Duration(hours: 23));
      expect(emissions, 1, reason: 'one wake-up per cutoff, not a loop');

      async.elapse(const Duration(hours: 2));
      expect(emissions, 2);

      container.dispose();
      async.flushTimers();
    });
  });

  test('cancels its timer on dispose', () {
    fakeAsync(initialTime: morning, (async) {
      final container = ProviderContainer();

      container.read(homeClockProvider);
      container.dispose();

      // A leaked periodic or pending timer would make this throw.
      expect(async.pendingTimers, isEmpty);
    });
  });
}
