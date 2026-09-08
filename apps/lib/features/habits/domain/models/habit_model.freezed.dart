// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'habit_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HabitModel {

 String get id; String get name; List<int> get targetDays; String? get category; int get streak; Map<DateTime, int> get heatmapData;
/// Create a copy of HabitModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HabitModelCopyWith<HabitModel> get copyWith => _$HabitModelCopyWithImpl<HabitModel>(this as HabitModel, _$identity);

  /// Serializes this HabitModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HabitModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.targetDays, targetDays)&&(identical(other.category, category) || other.category == category)&&(identical(other.streak, streak) || other.streak == streak)&&const DeepCollectionEquality().equals(other.heatmapData, heatmapData));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(targetDays),category,streak,const DeepCollectionEquality().hash(heatmapData));

@override
String toString() {
  return 'HabitModel(id: $id, name: $name, targetDays: $targetDays, category: $category, streak: $streak, heatmapData: $heatmapData)';
}


}

/// @nodoc
abstract mixin class $HabitModelCopyWith<$Res>  {
  factory $HabitModelCopyWith(HabitModel value, $Res Function(HabitModel) _then) = _$HabitModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, List<int> targetDays, String? category, int streak, Map<DateTime, int> heatmapData
});




}
/// @nodoc
class _$HabitModelCopyWithImpl<$Res>
    implements $HabitModelCopyWith<$Res> {
  _$HabitModelCopyWithImpl(this._self, this._then);

  final HabitModel _self;
  final $Res Function(HabitModel) _then;

/// Create a copy of HabitModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? targetDays = null,Object? category = freezed,Object? streak = null,Object? heatmapData = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,targetDays: null == targetDays ? _self.targetDays : targetDays // ignore: cast_nullable_to_non_nullable
as List<int>,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,streak: null == streak ? _self.streak : streak // ignore: cast_nullable_to_non_nullable
as int,heatmapData: null == heatmapData ? _self.heatmapData : heatmapData // ignore: cast_nullable_to_non_nullable
as Map<DateTime, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [HabitModel].
extension HabitModelPatterns on HabitModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HabitModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HabitModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HabitModel value)  $default,){
final _that = this;
switch (_that) {
case _HabitModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HabitModel value)?  $default,){
final _that = this;
switch (_that) {
case _HabitModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  List<int> targetDays,  String? category,  int streak,  Map<DateTime, int> heatmapData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HabitModel() when $default != null:
return $default(_that.id,_that.name,_that.targetDays,_that.category,_that.streak,_that.heatmapData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  List<int> targetDays,  String? category,  int streak,  Map<DateTime, int> heatmapData)  $default,) {final _that = this;
switch (_that) {
case _HabitModel():
return $default(_that.id,_that.name,_that.targetDays,_that.category,_that.streak,_that.heatmapData);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  List<int> targetDays,  String? category,  int streak,  Map<DateTime, int> heatmapData)?  $default,) {final _that = this;
switch (_that) {
case _HabitModel() when $default != null:
return $default(_that.id,_that.name,_that.targetDays,_that.category,_that.streak,_that.heatmapData);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HabitModel implements HabitModel {
  const _HabitModel({required this.id, required this.name, required final  List<int> targetDays, this.category, this.streak = 0, final  Map<DateTime, int> heatmapData = const {}}): _targetDays = targetDays,_heatmapData = heatmapData;
  factory _HabitModel.fromJson(Map<String, dynamic> json) => _$HabitModelFromJson(json);

@override final  String id;
@override final  String name;
 final  List<int> _targetDays;
@override List<int> get targetDays {
  if (_targetDays is EqualUnmodifiableListView) return _targetDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_targetDays);
}

@override final  String? category;
@override@JsonKey() final  int streak;
 final  Map<DateTime, int> _heatmapData;
@override@JsonKey() Map<DateTime, int> get heatmapData {
  if (_heatmapData is EqualUnmodifiableMapView) return _heatmapData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_heatmapData);
}


/// Create a copy of HabitModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HabitModelCopyWith<_HabitModel> get copyWith => __$HabitModelCopyWithImpl<_HabitModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HabitModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HabitModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._targetDays, _targetDays)&&(identical(other.category, category) || other.category == category)&&(identical(other.streak, streak) || other.streak == streak)&&const DeepCollectionEquality().equals(other._heatmapData, _heatmapData));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_targetDays),category,streak,const DeepCollectionEquality().hash(_heatmapData));

@override
String toString() {
  return 'HabitModel(id: $id, name: $name, targetDays: $targetDays, category: $category, streak: $streak, heatmapData: $heatmapData)';
}


}

/// @nodoc
abstract mixin class _$HabitModelCopyWith<$Res> implements $HabitModelCopyWith<$Res> {
  factory _$HabitModelCopyWith(_HabitModel value, $Res Function(_HabitModel) _then) = __$HabitModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, List<int> targetDays, String? category, int streak, Map<DateTime, int> heatmapData
});




}
/// @nodoc
class __$HabitModelCopyWithImpl<$Res>
    implements _$HabitModelCopyWith<$Res> {
  __$HabitModelCopyWithImpl(this._self, this._then);

  final _HabitModel _self;
  final $Res Function(_HabitModel) _then;

/// Create a copy of HabitModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? targetDays = null,Object? category = freezed,Object? streak = null,Object? heatmapData = null,}) {
  return _then(_HabitModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,targetDays: null == targetDays ? _self._targetDays : targetDays // ignore: cast_nullable_to_non_nullable
as List<int>,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,streak: null == streak ? _self.streak : streak // ignore: cast_nullable_to_non_nullable
as int,heatmapData: null == heatmapData ? _self._heatmapData : heatmapData // ignore: cast_nullable_to_non_nullable
as Map<DateTime, int>,
  ));
}


}

// dart format on
