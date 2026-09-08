import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../domain/pomodoro_state.dart';

part 'timer_notifier.g.dart';

@riverpod
class TimerNotifier extends _$TimerNotifier with WidgetsBindingObserver {
  StreamSubscription<int>? _tickerSubscription;
  static const int _defaultDuration = 25 * 60; // 25 mins

  @override
  PomodoroState build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _tickerSubscription?.cancel();
      WakelockPlus.disable().catchError((_) {});
    });
    return const PomodoroState(remainingSeconds: _defaultDuration);
  }

  void start() {
    WakelockPlus.enable().catchError((_) {});
    state = state.copyWith(
      status: TimerStatus.running,
      lastResumeTime: DateTime.now(),
    );
    _startTicker();
  }

  void pause() {
    WakelockPlus.disable().catchError((_) {});
    _tickerSubscription?.cancel();
    state = state.copyWith(status: TimerStatus.paused, lastResumeTime: null);
  }

  void reset() {
    WakelockPlus.disable().catchError((_) {});
    _tickerSubscription?.cancel();
    state = const PomodoroState(remainingSeconds: _defaultDuration);
  }

  void _startTicker() {
    _tickerSubscription?.cancel();
    _tickerSubscription = Stream.periodic(const Duration(seconds: 1), (x) => x).listen((_) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(
          remainingSeconds: state.remainingSeconds - 1,
          lastResumeTime: DateTime.now(),
        );
      } else {
        _completeTimer();
      }
    });
  }

  void _completeTimer() {
    WakelockPlus.disable().catchError((_) {});
    _tickerSubscription?.cancel();
    state = state.copyWith(status: TimerStatus.completed, remainingSeconds: 0, lastResumeTime: null);
    // TODO: update the attached EventModel status and update the local database.
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (state.status != TimerStatus.running) return;

    if (lifecycleState == AppLifecycleState.resumed) {
      if (state.lastResumeTime != null) {
        final elapsed = DateTime.now().difference(state.lastResumeTime!).inSeconds;
        final newRemaining = state.remainingSeconds - elapsed;
        
        if (newRemaining <= 0) {
          _completeTimer();
        } else {
          state = state.copyWith(
            remainingSeconds: newRemaining,
            lastResumeTime: DateTime.now(),
          );
          _startTicker();
        }
      }
    } else if (lifecycleState == AppLifecycleState.paused) {
      _tickerSubscription?.cancel();
    }
  }
}
