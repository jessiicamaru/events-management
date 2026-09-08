import 'package:freezed_annotation/freezed_annotation.dart';

part 'pomodoro_state.freezed.dart';

enum TimerStatus { initial, running, paused, completed }

@freezed
abstract class PomodoroState with _$PomodoroState {
  const factory PomodoroState({
    @Default(TimerStatus.initial) TimerStatus status,
    @Default(1500) int remainingSeconds,
    DateTime? lastResumeTime,
  }) = _PomodoroState;
}
