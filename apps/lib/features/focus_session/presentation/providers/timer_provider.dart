import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../domain/models/timer_state.dart';

class TimerNotifier extends Notifier<TimerState> with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _lastBackgroundTime;
  int _targetDurationSeconds = 0;
  
  @override
  TimerState build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _timer?.cancel();
      WakelockPlus.disable();
    });
    return const TimerState.initial();
  }

  void start(int targetDurationMinutes) {
    _targetDurationSeconds = targetDurationMinutes * 60;
    state = TimerState.running(
      remainingSeconds: _targetDurationSeconds,
      targetDuration: _targetDurationSeconds,
    );
    WakelockPlus.enable();
    _startTicker();
  }

  void pause() {
    _timer?.cancel();
    WakelockPlus.disable();
    state.maybeMap(
      running: (s) => state = TimerState.paused(
        remainingSeconds: s.remainingSeconds,
        targetDuration: s.targetDuration,
      ),
      orElse: () {},
    );
  }

  void resume() {
    state.maybeMap(
      paused: (s) {
        state = TimerState.running(
          remainingSeconds: s.remainingSeconds,
          targetDuration: s.targetDuration,
        );
        WakelockPlus.enable();
        _startTicker();
      },
      orElse: () {},
    );
  }

  void startOvertime() {
    state = TimerState.overtime(
      overtimeSeconds: 0,
      targetDuration: _targetDurationSeconds,
    );
    WakelockPlus.enable();
    _startTicker();
  }

  void finish() {
    _timer?.cancel();
    WakelockPlus.disable();
    
    int actualSeconds = 0;
    state.maybeMap(
      running: (s) {
        actualSeconds = _targetDurationSeconds - s.remainingSeconds;
      },
      paused: (s) {
        actualSeconds = _targetDurationSeconds - s.remainingSeconds;
      },
      targetReached: (_) {
        actualSeconds = _targetDurationSeconds;
      },
      overtime: (s) {
        actualSeconds = _targetDurationSeconds + s.overtimeSeconds;
      },
      orElse: () {},
    );

    state = TimerState.finished(
      actualDurationSeconds: actualSeconds,
      targetDurationSeconds: _targetDurationSeconds,
    );
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state.maybeMap(
        running: (s) {
          if (s.remainingSeconds > 0) {
            state = s.copyWith(remainingSeconds: s.remainingSeconds - 1);
          } else {
            timer.cancel();
            WakelockPlus.disable();
            state = const TimerState.targetReached();
          }
        },
        overtime: (s) {
          state = s.copyWith(overtimeSeconds: s.overtimeSeconds + 1);
        },
        orElse: () => timer.cancel(),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.paused) {
      _lastBackgroundTime = DateTime.now();
    } else if (appState == AppLifecycleState.resumed && _lastBackgroundTime != null) {
      final elapsedSeconds = DateTime.now().difference(_lastBackgroundTime!).inSeconds;
      _lastBackgroundTime = null;

      state.maybeMap(
        running: (s) {
          final newRemaining = s.remainingSeconds - elapsedSeconds;
          if (newRemaining <= 0) {
            _timer?.cancel();
            WakelockPlus.disable();
            state = const TimerState.targetReached();
          } else {
            state = s.copyWith(remainingSeconds: newRemaining);
          }
        },
        overtime: (s) {
          state = s.copyWith(overtimeSeconds: s.overtimeSeconds + elapsedSeconds);
        },
        orElse: () {},
      );
    }
  }
}

final timerProvider = NotifierProvider<TimerNotifier, TimerState>(() {
  return TimerNotifier();
});
