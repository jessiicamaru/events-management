// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timer_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TimerState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimerState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TimerState()';
}


}

/// @nodoc
class $TimerStateCopyWith<$Res>  {
$TimerStateCopyWith(TimerState _, $Res Function(TimerState) __);
}


/// Adds pattern-matching-related methods to [TimerState].
extension TimerStatePatterns on TimerState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Running value)?  running,TResult Function( _Paused value)?  paused,TResult Function( _TargetReached value)?  targetReached,TResult Function( _Overtime value)?  overtime,TResult Function( _Finished value)?  finished,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Running() when running != null:
return running(_that);case _Paused() when paused != null:
return paused(_that);case _TargetReached() when targetReached != null:
return targetReached(_that);case _Overtime() when overtime != null:
return overtime(_that);case _Finished() when finished != null:
return finished(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Running value)  running,required TResult Function( _Paused value)  paused,required TResult Function( _TargetReached value)  targetReached,required TResult Function( _Overtime value)  overtime,required TResult Function( _Finished value)  finished,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Running():
return running(_that);case _Paused():
return paused(_that);case _TargetReached():
return targetReached(_that);case _Overtime():
return overtime(_that);case _Finished():
return finished(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Running value)?  running,TResult? Function( _Paused value)?  paused,TResult? Function( _TargetReached value)?  targetReached,TResult? Function( _Overtime value)?  overtime,TResult? Function( _Finished value)?  finished,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Running() when running != null:
return running(_that);case _Paused() when paused != null:
return paused(_that);case _TargetReached() when targetReached != null:
return targetReached(_that);case _Overtime() when overtime != null:
return overtime(_that);case _Finished() when finished != null:
return finished(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( int remainingSeconds,  int targetDuration)?  running,TResult Function( int remainingSeconds,  int targetDuration)?  paused,TResult Function()?  targetReached,TResult Function( int overtimeSeconds,  int targetDuration)?  overtime,TResult Function( int actualDurationSeconds,  int targetDurationSeconds)?  finished,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Running() when running != null:
return running(_that.remainingSeconds,_that.targetDuration);case _Paused() when paused != null:
return paused(_that.remainingSeconds,_that.targetDuration);case _TargetReached() when targetReached != null:
return targetReached();case _Overtime() when overtime != null:
return overtime(_that.overtimeSeconds,_that.targetDuration);case _Finished() when finished != null:
return finished(_that.actualDurationSeconds,_that.targetDurationSeconds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( int remainingSeconds,  int targetDuration)  running,required TResult Function( int remainingSeconds,  int targetDuration)  paused,required TResult Function()  targetReached,required TResult Function( int overtimeSeconds,  int targetDuration)  overtime,required TResult Function( int actualDurationSeconds,  int targetDurationSeconds)  finished,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Running():
return running(_that.remainingSeconds,_that.targetDuration);case _Paused():
return paused(_that.remainingSeconds,_that.targetDuration);case _TargetReached():
return targetReached();case _Overtime():
return overtime(_that.overtimeSeconds,_that.targetDuration);case _Finished():
return finished(_that.actualDurationSeconds,_that.targetDurationSeconds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( int remainingSeconds,  int targetDuration)?  running,TResult? Function( int remainingSeconds,  int targetDuration)?  paused,TResult? Function()?  targetReached,TResult? Function( int overtimeSeconds,  int targetDuration)?  overtime,TResult? Function( int actualDurationSeconds,  int targetDurationSeconds)?  finished,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Running() when running != null:
return running(_that.remainingSeconds,_that.targetDuration);case _Paused() when paused != null:
return paused(_that.remainingSeconds,_that.targetDuration);case _TargetReached() when targetReached != null:
return targetReached();case _Overtime() when overtime != null:
return overtime(_that.overtimeSeconds,_that.targetDuration);case _Finished() when finished != null:
return finished(_that.actualDurationSeconds,_that.targetDurationSeconds);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements TimerState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TimerState.initial()';
}


}




/// @nodoc


class _Running implements TimerState {
  const _Running({required this.remainingSeconds, required this.targetDuration});
  

 final  int remainingSeconds;
 final  int targetDuration;

/// Create a copy of TimerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RunningCopyWith<_Running> get copyWith => __$RunningCopyWithImpl<_Running>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Running&&(identical(other.remainingSeconds, remainingSeconds) || other.remainingSeconds == remainingSeconds)&&(identical(other.targetDuration, targetDuration) || other.targetDuration == targetDuration));
}


@override
int get hashCode => Object.hash(runtimeType,remainingSeconds,targetDuration);

@override
String toString() {
  return 'TimerState.running(remainingSeconds: $remainingSeconds, targetDuration: $targetDuration)';
}


}

/// @nodoc
abstract mixin class _$RunningCopyWith<$Res> implements $TimerStateCopyWith<$Res> {
  factory _$RunningCopyWith(_Running value, $Res Function(_Running) _then) = __$RunningCopyWithImpl;
@useResult
$Res call({
 int remainingSeconds, int targetDuration
});




}
/// @nodoc
class __$RunningCopyWithImpl<$Res>
    implements _$RunningCopyWith<$Res> {
  __$RunningCopyWithImpl(this._self, this._then);

  final _Running _self;
  final $Res Function(_Running) _then;

/// Create a copy of TimerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? remainingSeconds = null,Object? targetDuration = null,}) {
  return _then(_Running(
remainingSeconds: null == remainingSeconds ? _self.remainingSeconds : remainingSeconds // ignore: cast_nullable_to_non_nullable
as int,targetDuration: null == targetDuration ? _self.targetDuration : targetDuration // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _Paused implements TimerState {
  const _Paused({required this.remainingSeconds, required this.targetDuration});
  

 final  int remainingSeconds;
 final  int targetDuration;

/// Create a copy of TimerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PausedCopyWith<_Paused> get copyWith => __$PausedCopyWithImpl<_Paused>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Paused&&(identical(other.remainingSeconds, remainingSeconds) || other.remainingSeconds == remainingSeconds)&&(identical(other.targetDuration, targetDuration) || other.targetDuration == targetDuration));
}


@override
int get hashCode => Object.hash(runtimeType,remainingSeconds,targetDuration);

@override
String toString() {
  return 'TimerState.paused(remainingSeconds: $remainingSeconds, targetDuration: $targetDuration)';
}


}

/// @nodoc
abstract mixin class _$PausedCopyWith<$Res> implements $TimerStateCopyWith<$Res> {
  factory _$PausedCopyWith(_Paused value, $Res Function(_Paused) _then) = __$PausedCopyWithImpl;
@useResult
$Res call({
 int remainingSeconds, int targetDuration
});




}
/// @nodoc
class __$PausedCopyWithImpl<$Res>
    implements _$PausedCopyWith<$Res> {
  __$PausedCopyWithImpl(this._self, this._then);

  final _Paused _self;
  final $Res Function(_Paused) _then;

/// Create a copy of TimerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? remainingSeconds = null,Object? targetDuration = null,}) {
  return _then(_Paused(
remainingSeconds: null == remainingSeconds ? _self.remainingSeconds : remainingSeconds // ignore: cast_nullable_to_non_nullable
as int,targetDuration: null == targetDuration ? _self.targetDuration : targetDuration // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _TargetReached implements TimerState {
  const _TargetReached();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TargetReached);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TimerState.targetReached()';
}


}




/// @nodoc


class _Overtime implements TimerState {
  const _Overtime({required this.overtimeSeconds, required this.targetDuration});
  

 final  int overtimeSeconds;
 final  int targetDuration;

/// Create a copy of TimerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OvertimeCopyWith<_Overtime> get copyWith => __$OvertimeCopyWithImpl<_Overtime>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Overtime&&(identical(other.overtimeSeconds, overtimeSeconds) || other.overtimeSeconds == overtimeSeconds)&&(identical(other.targetDuration, targetDuration) || other.targetDuration == targetDuration));
}


@override
int get hashCode => Object.hash(runtimeType,overtimeSeconds,targetDuration);

@override
String toString() {
  return 'TimerState.overtime(overtimeSeconds: $overtimeSeconds, targetDuration: $targetDuration)';
}


}

/// @nodoc
abstract mixin class _$OvertimeCopyWith<$Res> implements $TimerStateCopyWith<$Res> {
  factory _$OvertimeCopyWith(_Overtime value, $Res Function(_Overtime) _then) = __$OvertimeCopyWithImpl;
@useResult
$Res call({
 int overtimeSeconds, int targetDuration
});




}
/// @nodoc
class __$OvertimeCopyWithImpl<$Res>
    implements _$OvertimeCopyWith<$Res> {
  __$OvertimeCopyWithImpl(this._self, this._then);

  final _Overtime _self;
  final $Res Function(_Overtime) _then;

/// Create a copy of TimerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? overtimeSeconds = null,Object? targetDuration = null,}) {
  return _then(_Overtime(
overtimeSeconds: null == overtimeSeconds ? _self.overtimeSeconds : overtimeSeconds // ignore: cast_nullable_to_non_nullable
as int,targetDuration: null == targetDuration ? _self.targetDuration : targetDuration // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _Finished implements TimerState {
  const _Finished({required this.actualDurationSeconds, required this.targetDurationSeconds});
  

 final  int actualDurationSeconds;
 final  int targetDurationSeconds;

/// Create a copy of TimerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinishedCopyWith<_Finished> get copyWith => __$FinishedCopyWithImpl<_Finished>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Finished&&(identical(other.actualDurationSeconds, actualDurationSeconds) || other.actualDurationSeconds == actualDurationSeconds)&&(identical(other.targetDurationSeconds, targetDurationSeconds) || other.targetDurationSeconds == targetDurationSeconds));
}


@override
int get hashCode => Object.hash(runtimeType,actualDurationSeconds,targetDurationSeconds);

@override
String toString() {
  return 'TimerState.finished(actualDurationSeconds: $actualDurationSeconds, targetDurationSeconds: $targetDurationSeconds)';
}


}

/// @nodoc
abstract mixin class _$FinishedCopyWith<$Res> implements $TimerStateCopyWith<$Res> {
  factory _$FinishedCopyWith(_Finished value, $Res Function(_Finished) _then) = __$FinishedCopyWithImpl;
@useResult
$Res call({
 int actualDurationSeconds, int targetDurationSeconds
});




}
/// @nodoc
class __$FinishedCopyWithImpl<$Res>
    implements _$FinishedCopyWith<$Res> {
  __$FinishedCopyWithImpl(this._self, this._then);

  final _Finished _self;
  final $Res Function(_Finished) _then;

/// Create a copy of TimerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? actualDurationSeconds = null,Object? targetDurationSeconds = null,}) {
  return _then(_Finished(
actualDurationSeconds: null == actualDurationSeconds ? _self.actualDurationSeconds : actualDurationSeconds // ignore: cast_nullable_to_non_nullable
as int,targetDurationSeconds: null == targetDurationSeconds ? _self.targetDurationSeconds : targetDurationSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
