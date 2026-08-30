// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pomodoro_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PomodoroState {

 TimerStatus get status; int get remainingSeconds; DateTime? get lastResumeTime;
/// Create a copy of PomodoroState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PomodoroStateCopyWith<PomodoroState> get copyWith => _$PomodoroStateCopyWithImpl<PomodoroState>(this as PomodoroState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PomodoroState&&(identical(other.status, status) || other.status == status)&&(identical(other.remainingSeconds, remainingSeconds) || other.remainingSeconds == remainingSeconds)&&(identical(other.lastResumeTime, lastResumeTime) || other.lastResumeTime == lastResumeTime));
}


@override
int get hashCode => Object.hash(runtimeType,status,remainingSeconds,lastResumeTime);

@override
String toString() {
  return 'PomodoroState(status: $status, remainingSeconds: $remainingSeconds, lastResumeTime: $lastResumeTime)';
}


}

/// @nodoc
abstract mixin class $PomodoroStateCopyWith<$Res>  {
  factory $PomodoroStateCopyWith(PomodoroState value, $Res Function(PomodoroState) _then) = _$PomodoroStateCopyWithImpl;
@useResult
$Res call({
 TimerStatus status, int remainingSeconds, DateTime? lastResumeTime
});




}
/// @nodoc
class _$PomodoroStateCopyWithImpl<$Res>
    implements $PomodoroStateCopyWith<$Res> {
  _$PomodoroStateCopyWithImpl(this._self, this._then);

  final PomodoroState _self;
  final $Res Function(PomodoroState) _then;

/// Create a copy of PomodoroState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? remainingSeconds = null,Object? lastResumeTime = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TimerStatus,remainingSeconds: null == remainingSeconds ? _self.remainingSeconds : remainingSeconds // ignore: cast_nullable_to_non_nullable
as int,lastResumeTime: freezed == lastResumeTime ? _self.lastResumeTime : lastResumeTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PomodoroState].
extension PomodoroStatePatterns on PomodoroState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PomodoroState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PomodoroState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PomodoroState value)  $default,){
final _that = this;
switch (_that) {
case _PomodoroState():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PomodoroState value)?  $default,){
final _that = this;
switch (_that) {
case _PomodoroState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TimerStatus status,  int remainingSeconds,  DateTime? lastResumeTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PomodoroState() when $default != null:
return $default(_that.status,_that.remainingSeconds,_that.lastResumeTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TimerStatus status,  int remainingSeconds,  DateTime? lastResumeTime)  $default,) {final _that = this;
switch (_that) {
case _PomodoroState():
return $default(_that.status,_that.remainingSeconds,_that.lastResumeTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TimerStatus status,  int remainingSeconds,  DateTime? lastResumeTime)?  $default,) {final _that = this;
switch (_that) {
case _PomodoroState() when $default != null:
return $default(_that.status,_that.remainingSeconds,_that.lastResumeTime);case _:
  return null;

}
}

}

/// @nodoc


class _PomodoroState implements PomodoroState {
  const _PomodoroState({this.status = TimerStatus.initial, this.remainingSeconds = 1500, this.lastResumeTime});
  

@override@JsonKey() final  TimerStatus status;
@override@JsonKey() final  int remainingSeconds;
@override final  DateTime? lastResumeTime;

/// Create a copy of PomodoroState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PomodoroStateCopyWith<_PomodoroState> get copyWith => __$PomodoroStateCopyWithImpl<_PomodoroState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PomodoroState&&(identical(other.status, status) || other.status == status)&&(identical(other.remainingSeconds, remainingSeconds) || other.remainingSeconds == remainingSeconds)&&(identical(other.lastResumeTime, lastResumeTime) || other.lastResumeTime == lastResumeTime));
}


@override
int get hashCode => Object.hash(runtimeType,status,remainingSeconds,lastResumeTime);

@override
String toString() {
  return 'PomodoroState(status: $status, remainingSeconds: $remainingSeconds, lastResumeTime: $lastResumeTime)';
}


}

/// @nodoc
abstract mixin class _$PomodoroStateCopyWith<$Res> implements $PomodoroStateCopyWith<$Res> {
  factory _$PomodoroStateCopyWith(_PomodoroState value, $Res Function(_PomodoroState) _then) = __$PomodoroStateCopyWithImpl;
@override @useResult
$Res call({
 TimerStatus status, int remainingSeconds, DateTime? lastResumeTime
});




}
/// @nodoc
class __$PomodoroStateCopyWithImpl<$Res>
    implements _$PomodoroStateCopyWith<$Res> {
  __$PomodoroStateCopyWithImpl(this._self, this._then);

  final _PomodoroState _self;
  final $Res Function(_PomodoroState) _then;

/// Create a copy of PomodoroState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? remainingSeconds = null,Object? lastResumeTime = freezed,}) {
  return _then(_PomodoroState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TimerStatus,remainingSeconds: null == remainingSeconds ? _self.remainingSeconds : remainingSeconds // ignore: cast_nullable_to_non_nullable
as int,lastResumeTime: freezed == lastResumeTime ? _self.lastResumeTime : lastResumeTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
