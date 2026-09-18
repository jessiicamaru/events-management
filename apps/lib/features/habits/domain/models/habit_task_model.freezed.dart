// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'habit_task_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HabitTaskModel {

 String get id; String get habitId; String get title; String? get description; int get order; TaskPriority get priority; int? get estimatedMinutes;
/// Create a copy of HabitTaskModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HabitTaskModelCopyWith<HabitTaskModel> get copyWith => _$HabitTaskModelCopyWithImpl<HabitTaskModel>(this as HabitTaskModel, _$identity);

  /// Serializes this HabitTaskModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HabitTaskModel&&(identical(other.id, id) || other.id == id)&&(identical(other.habitId, habitId) || other.habitId == habitId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.order, order) || other.order == order)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.estimatedMinutes, estimatedMinutes) || other.estimatedMinutes == estimatedMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,habitId,title,description,order,priority,estimatedMinutes);

@override
String toString() {
  return 'HabitTaskModel(id: $id, habitId: $habitId, title: $title, description: $description, order: $order, priority: $priority, estimatedMinutes: $estimatedMinutes)';
}


}

/// @nodoc
abstract mixin class $HabitTaskModelCopyWith<$Res>  {
  factory $HabitTaskModelCopyWith(HabitTaskModel value, $Res Function(HabitTaskModel) _then) = _$HabitTaskModelCopyWithImpl;
@useResult
$Res call({
 String id, String habitId, String title, String? description, int order, TaskPriority priority, int? estimatedMinutes
});




}
/// @nodoc
class _$HabitTaskModelCopyWithImpl<$Res>
    implements $HabitTaskModelCopyWith<$Res> {
  _$HabitTaskModelCopyWithImpl(this._self, this._then);

  final HabitTaskModel _self;
  final $Res Function(HabitTaskModel) _then;

/// Create a copy of HabitTaskModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? habitId = null,Object? title = null,Object? description = freezed,Object? order = null,Object? priority = null,Object? estimatedMinutes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,habitId: null == habitId ? _self.habitId : habitId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as TaskPriority,estimatedMinutes: freezed == estimatedMinutes ? _self.estimatedMinutes : estimatedMinutes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [HabitTaskModel].
extension HabitTaskModelPatterns on HabitTaskModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HabitTaskModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HabitTaskModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HabitTaskModel value)  $default,){
final _that = this;
switch (_that) {
case _HabitTaskModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HabitTaskModel value)?  $default,){
final _that = this;
switch (_that) {
case _HabitTaskModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String habitId,  String title,  String? description,  int order,  TaskPriority priority,  int? estimatedMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HabitTaskModel() when $default != null:
return $default(_that.id,_that.habitId,_that.title,_that.description,_that.order,_that.priority,_that.estimatedMinutes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String habitId,  String title,  String? description,  int order,  TaskPriority priority,  int? estimatedMinutes)  $default,) {final _that = this;
switch (_that) {
case _HabitTaskModel():
return $default(_that.id,_that.habitId,_that.title,_that.description,_that.order,_that.priority,_that.estimatedMinutes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String habitId,  String title,  String? description,  int order,  TaskPriority priority,  int? estimatedMinutes)?  $default,) {final _that = this;
switch (_that) {
case _HabitTaskModel() when $default != null:
return $default(_that.id,_that.habitId,_that.title,_that.description,_that.order,_that.priority,_that.estimatedMinutes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HabitTaskModel implements HabitTaskModel {
  const _HabitTaskModel({required this.id, required this.habitId, required this.title, this.description, required this.order, this.priority = TaskPriority.medium, this.estimatedMinutes});
  factory _HabitTaskModel.fromJson(Map<String, dynamic> json) => _$HabitTaskModelFromJson(json);

@override final  String id;
@override final  String habitId;
@override final  String title;
@override final  String? description;
@override final  int order;
@override@JsonKey() final  TaskPriority priority;
@override final  int? estimatedMinutes;

/// Create a copy of HabitTaskModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HabitTaskModelCopyWith<_HabitTaskModel> get copyWith => __$HabitTaskModelCopyWithImpl<_HabitTaskModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HabitTaskModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HabitTaskModel&&(identical(other.id, id) || other.id == id)&&(identical(other.habitId, habitId) || other.habitId == habitId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.order, order) || other.order == order)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.estimatedMinutes, estimatedMinutes) || other.estimatedMinutes == estimatedMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,habitId,title,description,order,priority,estimatedMinutes);

@override
String toString() {
  return 'HabitTaskModel(id: $id, habitId: $habitId, title: $title, description: $description, order: $order, priority: $priority, estimatedMinutes: $estimatedMinutes)';
}


}

/// @nodoc
abstract mixin class _$HabitTaskModelCopyWith<$Res> implements $HabitTaskModelCopyWith<$Res> {
  factory _$HabitTaskModelCopyWith(_HabitTaskModel value, $Res Function(_HabitTaskModel) _then) = __$HabitTaskModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String habitId, String title, String? description, int order, TaskPriority priority, int? estimatedMinutes
});




}
/// @nodoc
class __$HabitTaskModelCopyWithImpl<$Res>
    implements _$HabitTaskModelCopyWith<$Res> {
  __$HabitTaskModelCopyWithImpl(this._self, this._then);

  final _HabitTaskModel _self;
  final $Res Function(_HabitTaskModel) _then;

/// Create a copy of HabitTaskModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? habitId = null,Object? title = null,Object? description = freezed,Object? order = null,Object? priority = null,Object? estimatedMinutes = freezed,}) {
  return _then(_HabitTaskModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,habitId: null == habitId ? _self.habitId : habitId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as TaskPriority,estimatedMinutes: freezed == estimatedMinutes ? _self.estimatedMinutes : estimatedMinutes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
