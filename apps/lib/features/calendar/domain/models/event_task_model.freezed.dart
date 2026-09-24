// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_task_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EventTaskModel {

 String get id; String get eventId; String get title; String? get description; int get order; TaskPriority get priority; int? get estimatedMinutes; bool get isCompleted;
/// Create a copy of EventTaskModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventTaskModelCopyWith<EventTaskModel> get copyWith => _$EventTaskModelCopyWithImpl<EventTaskModel>(this as EventTaskModel, _$identity);

  /// Serializes this EventTaskModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventTaskModel&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.order, order) || other.order == order)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.estimatedMinutes, estimatedMinutes) || other.estimatedMinutes == estimatedMinutes)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,title,description,order,priority,estimatedMinutes,isCompleted);

@override
String toString() {
  return 'EventTaskModel(id: $id, eventId: $eventId, title: $title, description: $description, order: $order, priority: $priority, estimatedMinutes: $estimatedMinutes, isCompleted: $isCompleted)';
}


}

/// @nodoc
abstract mixin class $EventTaskModelCopyWith<$Res>  {
  factory $EventTaskModelCopyWith(EventTaskModel value, $Res Function(EventTaskModel) _then) = _$EventTaskModelCopyWithImpl;
@useResult
$Res call({
 String id, String eventId, String title, String? description, int order, TaskPriority priority, int? estimatedMinutes, bool isCompleted
});




}
/// @nodoc
class _$EventTaskModelCopyWithImpl<$Res>
    implements $EventTaskModelCopyWith<$Res> {
  _$EventTaskModelCopyWithImpl(this._self, this._then);

  final EventTaskModel _self;
  final $Res Function(EventTaskModel) _then;

/// Create a copy of EventTaskModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventId = null,Object? title = null,Object? description = freezed,Object? order = null,Object? priority = null,Object? estimatedMinutes = freezed,Object? isCompleted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as TaskPriority,estimatedMinutes: freezed == estimatedMinutes ? _self.estimatedMinutes : estimatedMinutes // ignore: cast_nullable_to_non_nullable
as int?,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [EventTaskModel].
extension EventTaskModelPatterns on EventTaskModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventTaskModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventTaskModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventTaskModel value)  $default,){
final _that = this;
switch (_that) {
case _EventTaskModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventTaskModel value)?  $default,){
final _that = this;
switch (_that) {
case _EventTaskModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String eventId,  String title,  String? description,  int order,  TaskPriority priority,  int? estimatedMinutes,  bool isCompleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventTaskModel() when $default != null:
return $default(_that.id,_that.eventId,_that.title,_that.description,_that.order,_that.priority,_that.estimatedMinutes,_that.isCompleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String eventId,  String title,  String? description,  int order,  TaskPriority priority,  int? estimatedMinutes,  bool isCompleted)  $default,) {final _that = this;
switch (_that) {
case _EventTaskModel():
return $default(_that.id,_that.eventId,_that.title,_that.description,_that.order,_that.priority,_that.estimatedMinutes,_that.isCompleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String eventId,  String title,  String? description,  int order,  TaskPriority priority,  int? estimatedMinutes,  bool isCompleted)?  $default,) {final _that = this;
switch (_that) {
case _EventTaskModel() when $default != null:
return $default(_that.id,_that.eventId,_that.title,_that.description,_that.order,_that.priority,_that.estimatedMinutes,_that.isCompleted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventTaskModel implements EventTaskModel {
  const _EventTaskModel({required this.id, required this.eventId, required this.title, this.description, required this.order, this.priority = TaskPriority.medium, this.estimatedMinutes, this.isCompleted = false});
  factory _EventTaskModel.fromJson(Map<String, dynamic> json) => _$EventTaskModelFromJson(json);

@override final  String id;
@override final  String eventId;
@override final  String title;
@override final  String? description;
@override final  int order;
@override@JsonKey() final  TaskPriority priority;
@override final  int? estimatedMinutes;
@override@JsonKey() final  bool isCompleted;

/// Create a copy of EventTaskModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventTaskModelCopyWith<_EventTaskModel> get copyWith => __$EventTaskModelCopyWithImpl<_EventTaskModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventTaskModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventTaskModel&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.order, order) || other.order == order)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.estimatedMinutes, estimatedMinutes) || other.estimatedMinutes == estimatedMinutes)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,title,description,order,priority,estimatedMinutes,isCompleted);

@override
String toString() {
  return 'EventTaskModel(id: $id, eventId: $eventId, title: $title, description: $description, order: $order, priority: $priority, estimatedMinutes: $estimatedMinutes, isCompleted: $isCompleted)';
}


}

/// @nodoc
abstract mixin class _$EventTaskModelCopyWith<$Res> implements $EventTaskModelCopyWith<$Res> {
  factory _$EventTaskModelCopyWith(_EventTaskModel value, $Res Function(_EventTaskModel) _then) = __$EventTaskModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String eventId, String title, String? description, int order, TaskPriority priority, int? estimatedMinutes, bool isCompleted
});




}
/// @nodoc
class __$EventTaskModelCopyWithImpl<$Res>
    implements _$EventTaskModelCopyWith<$Res> {
  __$EventTaskModelCopyWithImpl(this._self, this._then);

  final _EventTaskModel _self;
  final $Res Function(_EventTaskModel) _then;

/// Create a copy of EventTaskModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = null,Object? title = null,Object? description = freezed,Object? order = null,Object? priority = null,Object? estimatedMinutes = freezed,Object? isCompleted = null,}) {
  return _then(_EventTaskModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as TaskPriority,estimatedMinutes: freezed == estimatedMinutes ? _self.estimatedMinutes : estimatedMinutes // ignore: cast_nullable_to_non_nullable
as int?,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
