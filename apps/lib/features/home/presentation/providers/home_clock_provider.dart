import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/features/habits/domain/streak_at_risk.dart';

/// The "now" the Home screen renders against, re-read at the streak cutoff.
///
/// Home is otherwise a pure function of its providers: nothing in it re-runs because time
/// passed, so a screen left open at 19:50 would never show the streak-at-risk card when
/// 20:00 arrived. This schedules one timer to the next
/// [AppConstants.streakAtRiskHour][StreakAtRisk.nextCutoffAfter] and invalidates itself
/// there, which rebuilds Home once.
///
/// One timer, not a ticking clock: the agenda's own minute-to-minute drift is already
/// handled by the events provider refreshing, and a per-second rebuild of the whole screen
/// would cost far more than it shows.
///
/// Reads `clock.now()` rather than `DateTime.now()` so the timer and the value it hands out
/// come from the same clock — which is what lets a test elapse to the cutoff instead of
/// waiting for it.
final homeClockProvider = Provider<DateTime>((ref) {
  final now = clock.now();

  final delay = StreakAtRisk.nextCutoffAfter(now).difference(now);
  final timer = Timer(delay, ref.invalidateSelf);

  ref.onDispose(timer.cancel);

  return now;
});
