// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EventCategory {

 String get id; String get name; String get colorPreset; String? get userId; String? get squadId; DateTime? get createdAt;
/// Create a copy of EventCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventCategoryCopyWith<EventCategory> get copyWith => _$EventCategoryCopyWithImpl<EventCategory>(this as EventCategory, _$identity);

  /// Serializes this EventCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.colorPreset, colorPreset) || other.colorPreset == colorPreset)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.squadId, squadId) || other.squadId == squadId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,colorPreset,userId,squadId,createdAt);

@override
String toString() {
  return 'EventCategory(id: $id, name: $name, colorPreset: $colorPreset, userId: $userId, squadId: $squadId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $EventCategoryCopyWith<$Res>  {
  factory $EventCategoryCopyWith(EventCategory value, $Res Function(EventCategory) _then) = _$EventCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String colorPreset, String? userId, String? squadId, DateTime? createdAt
});




}
/// @nodoc
class _$EventCategoryCopyWithImpl<$Res>
    implements $EventCategoryCopyWith<$Res> {
  _$EventCategoryCopyWithImpl(this._self, this._then);

  final EventCategory _self;
  final $Res Function(EventCategory) _then;

/// Create a copy of EventCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? colorPreset = null,Object? userId = freezed,Object? squadId = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,colorPreset: null == colorPreset ? _self.colorPreset : colorPreset // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,squadId: freezed == squadId ? _self.squadId : squadId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [EventCategory].
extension EventCategoryPatterns on EventCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventCategory value)  $default,){
final _that = this;
switch (_that) {
case _EventCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventCategory value)?  $default,){
final _that = this;
switch (_that) {
case _EventCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String colorPreset,  String? userId,  String? squadId,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventCategory() when $default != null:
return $default(_that.id,_that.name,_that.colorPreset,_that.userId,_that.squadId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String colorPreset,  String? userId,  String? squadId,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _EventCategory():
return $default(_that.id,_that.name,_that.colorPreset,_that.userId,_that.squadId,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String colorPreset,  String? userId,  String? squadId,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _EventCategory() when $default != null:
return $default(_that.id,_that.name,_that.colorPreset,_that.userId,_that.squadId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventCategory extends EventCategory {
  const _EventCategory({required this.id, required this.name, required this.colorPreset, this.userId, this.squadId, this.createdAt}): super._();
  factory _EventCategory.fromJson(Map<String, dynamic> json) => _$EventCategoryFromJson(json);

@override final  String id;
@override final  String name;
@override final  String colorPreset;
@override final  String? userId;
@override final  String? squadId;
@override final  DateTime? createdAt;

/// Create a copy of EventCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventCategoryCopyWith<_EventCategory> get copyWith => __$EventCategoryCopyWithImpl<_EventCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.colorPreset, colorPreset) || other.colorPreset == colorPreset)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.squadId, squadId) || other.squadId == squadId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,colorPreset,userId,squadId,createdAt);

@override
String toString() {
  return 'EventCategory(id: $id, name: $name, colorPreset: $colorPreset, userId: $userId, squadId: $squadId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$EventCategoryCopyWith<$Res> implements $EventCategoryCopyWith<$Res> {
  factory _$EventCategoryCopyWith(_EventCategory value, $Res Function(_EventCategory) _then) = __$EventCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String colorPreset, String? userId, String? squadId, DateTime? createdAt
});




}
/// @nodoc
class __$EventCategoryCopyWithImpl<$Res>
    implements _$EventCategoryCopyWith<$Res> {
  __$EventCategoryCopyWithImpl(this._self, this._then);

  final _EventCategory _self;
  final $Res Function(_EventCategory) _then;

/// Create a copy of EventCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? colorPreset = null,Object? userId = freezed,Object? squadId = freezed,Object? createdAt = freezed,}) {
  return _then(_EventCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,colorPreset: null == colorPreset ? _self.colorPreset : colorPreset // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,squadId: freezed == squadId ? _self.squadId : squadId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
