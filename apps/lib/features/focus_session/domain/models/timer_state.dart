import 'package:freezed_annotation/freezed_annotation.dart';

part 'timer_state.freezed.dart';

@freezed
class TimerState with _$TimerState {
  const factory TimerState.initial() = _Initial;
  const factory TimerState.running({required int remainingSeconds, required int targetDuration}) = _Running;
  const factory TimerState.paused({required int remainingSeconds, required int targetDuration}) = _Paused;
  const factory TimerState.targetReached() = _TargetReached;
  const factory TimerState.overtime({required int overtimeSeconds, required int targetDuration}) = _Overtime;
  const factory TimerState.finished({required int actualDurationSeconds, required int targetDurationSeconds}) = _Finished;
}
