// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'squad_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SquadModel {

 String get id; String get name; bool get isBuddyMode; int get totalSquadXP; List<SquadMemberModel> get members;
/// Create a copy of SquadModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SquadModelCopyWith<SquadModel> get copyWith => _$SquadModelCopyWithImpl<SquadModel>(this as SquadModel, _$identity);

  /// Serializes this SquadModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SquadModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isBuddyMode, isBuddyMode) || other.isBuddyMode == isBuddyMode)&&(identical(other.totalSquadXP, totalSquadXP) || other.totalSquadXP == totalSquadXP)&&const DeepCollectionEquality().equals(other.members, members));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isBuddyMode,totalSquadXP,const DeepCollectionEquality().hash(members));

@override
String toString() {
  return 'SquadModel(id: $id, name: $name, isBuddyMode: $isBuddyMode, totalSquadXP: $totalSquadXP, members: $members)';
}


}

/// @nodoc
abstract mixin class $SquadModelCopyWith<$Res>  {
  factory $SquadModelCopyWith(SquadModel value, $Res Function(SquadModel) _then) = _$SquadModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, bool isBuddyMode, int totalSquadXP, List<SquadMemberModel> members
});




}
/// @nodoc
class _$SquadModelCopyWithImpl<$Res>
    implements $SquadModelCopyWith<$Res> {
  _$SquadModelCopyWithImpl(this._self, this._then);

  final SquadModel _self;
  final $Res Function(SquadModel) _then;

/// Create a copy of SquadModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? isBuddyMode = null,Object? totalSquadXP = null,Object? members = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isBuddyMode: null == isBuddyMode ? _self.isBuddyMode : isBuddyMode // ignore: cast_nullable_to_non_nullable
as bool,totalSquadXP: null == totalSquadXP ? _self.totalSquadXP : totalSquadXP // ignore: cast_nullable_to_non_nullable
as int,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<SquadMemberModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [SquadModel].
extension SquadModelPatterns on SquadModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SquadModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SquadModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SquadModel value)  $default,){
final _that = this;
switch (_that) {
case _SquadModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SquadModel value)?  $default,){
final _that = this;
switch (_that) {
case _SquadModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  bool isBuddyMode,  int totalSquadXP,  List<SquadMemberModel> members)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SquadModel() when $default != null:
return $default(_that.id,_that.name,_that.isBuddyMode,_that.totalSquadXP,_that.members);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  bool isBuddyMode,  int totalSquadXP,  List<SquadMemberModel> members)  $default,) {final _that = this;
switch (_that) {
case _SquadModel():
return $default(_that.id,_that.name,_that.isBuddyMode,_that.totalSquadXP,_that.members);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  bool isBuddyMode,  int totalSquadXP,  List<SquadMemberModel> members)?  $default,) {final _that = this;
switch (_that) {
case _SquadModel() when $default != null:
return $default(_that.id,_that.name,_that.isBuddyMode,_that.totalSquadXP,_that.members);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SquadModel implements SquadModel {
  const _SquadModel({required this.id, required this.name, required this.isBuddyMode, required this.totalSquadXP, final  List<SquadMemberModel> members = const []}): _members = members;
  factory _SquadModel.fromJson(Map<String, dynamic> json) => _$SquadModelFromJson(json);

@override final  String id;
@override final  String name;
@override final  bool isBuddyMode;
@override final  int totalSquadXP;
 final  List<SquadMemberModel> _members;
@override@JsonKey() List<SquadMemberModel> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}


/// Create a copy of SquadModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SquadModelCopyWith<_SquadModel> get copyWith => __$SquadModelCopyWithImpl<_SquadModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SquadModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SquadModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isBuddyMode, isBuddyMode) || other.isBuddyMode == isBuddyMode)&&(identical(other.totalSquadXP, totalSquadXP) || other.totalSquadXP == totalSquadXP)&&const DeepCollectionEquality().equals(other._members, _members));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isBuddyMode,totalSquadXP,const DeepCollectionEquality().hash(_members));

@override
String toString() {
  return 'SquadModel(id: $id, name: $name, isBuddyMode: $isBuddyMode, totalSquadXP: $totalSquadXP, members: $members)';
}


}

/// @nodoc
abstract mixin class _$SquadModelCopyWith<$Res> implements $SquadModelCopyWith<$Res> {
  factory _$SquadModelCopyWith(_SquadModel value, $Res Function(_SquadModel) _then) = __$SquadModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, bool isBuddyMode, int totalSquadXP, List<SquadMemberModel> members
});




}
/// @nodoc
class __$SquadModelCopyWithImpl<$Res>
    implements _$SquadModelCopyWith<$Res> {
  __$SquadModelCopyWithImpl(this._self, this._then);

  final _SquadModel _self;
  final $Res Function(_SquadModel) _then;

/// Create a copy of SquadModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isBuddyMode = null,Object? totalSquadXP = null,Object? members = null,}) {
  return _then(_SquadModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isBuddyMode: null == isBuddyMode ? _self.isBuddyMode : isBuddyMode // ignore: cast_nullable_to_non_nullable
as bool,totalSquadXP: null == totalSquadXP ? _self.totalSquadXP : totalSquadXP // ignore: cast_nullable_to_non_nullable
as int,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<SquadMemberModel>,
  ));
}


}


/// @nodoc
mixin _$SquadMemberModel {

 String get userId; String get role; String get email; int get totalXP; List<String> get unlockedEmojis; String? get avatarBorderColor;
/// Create a copy of SquadMemberModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SquadMemberModelCopyWith<SquadMemberModel> get copyWith => _$SquadMemberModelCopyWithImpl<SquadMemberModel>(this as SquadMemberModel, _$identity);

  /// Serializes this SquadMemberModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SquadMemberModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.role, role) || other.role == role)&&(identical(other.email, email) || other.email == email)&&(identical(other.totalXP, totalXP) || other.totalXP == totalXP)&&const DeepCollectionEquality().equals(other.unlockedEmojis, unlockedEmojis)&&(identical(other.avatarBorderColor, avatarBorderColor) || other.avatarBorderColor == avatarBorderColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,role,email,totalXP,const DeepCollectionEquality().hash(unlockedEmojis),avatarBorderColor);

@override
String toString() {
  return 'SquadMemberModel(userId: $userId, role: $role, email: $email, totalXP: $totalXP, unlockedEmojis: $unlockedEmojis, avatarBorderColor: $avatarBorderColor)';
}


}

/// @nodoc
abstract mixin class $SquadMemberModelCopyWith<$Res>  {
  factory $SquadMemberModelCopyWith(SquadMemberModel value, $Res Function(SquadMemberModel) _then) = _$SquadMemberModelCopyWithImpl;
@useResult
$Res call({
 String userId, String role, String email, int totalXP, List<String> unlockedEmojis, String? avatarBorderColor
});




}
/// @nodoc
class _$SquadMemberModelCopyWithImpl<$Res>
    implements $SquadMemberModelCopyWith<$Res> {
  _$SquadMemberModelCopyWithImpl(this._self, this._then);

  final SquadMemberModel _self;
  final $Res Function(SquadMemberModel) _then;

/// Create a copy of SquadMemberModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? role = null,Object? email = null,Object? totalXP = null,Object? unlockedEmojis = null,Object? avatarBorderColor = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,totalXP: null == totalXP ? _self.totalXP : totalXP // ignore: cast_nullable_to_non_nullable
as int,unlockedEmojis: null == unlockedEmojis ? _self.unlockedEmojis : unlockedEmojis // ignore: cast_nullable_to_non_nullable
as List<String>,avatarBorderColor: freezed == avatarBorderColor ? _self.avatarBorderColor : avatarBorderColor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SquadMemberModel].
extension SquadMemberModelPatterns on SquadMemberModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SquadMemberModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SquadMemberModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SquadMemberModel value)  $default,){
final _that = this;
switch (_that) {
case _SquadMemberModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SquadMemberModel value)?  $default,){
final _that = this;
switch (_that) {
case _SquadMemberModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String role,  String email,  int totalXP,  List<String> unlockedEmojis,  String? avatarBorderColor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SquadMemberModel() when $default != null:
return $default(_that.userId,_that.role,_that.email,_that.totalXP,_that.unlockedEmojis,_that.avatarBorderColor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String role,  String email,  int totalXP,  List<String> unlockedEmojis,  String? avatarBorderColor)  $default,) {final _that = this;
switch (_that) {
case _SquadMemberModel():
return $default(_that.userId,_that.role,_that.email,_that.totalXP,_that.unlockedEmojis,_that.avatarBorderColor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String role,  String email,  int totalXP,  List<String> unlockedEmojis,  String? avatarBorderColor)?  $default,) {final _that = this;
switch (_that) {
case _SquadMemberModel() when $default != null:
return $default(_that.userId,_that.role,_that.email,_that.totalXP,_that.unlockedEmojis,_that.avatarBorderColor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SquadMemberModel implements SquadMemberModel {
  const _SquadMemberModel({required this.userId, required this.role, required this.email, required this.totalXP, final  List<String> unlockedEmojis = const [], this.avatarBorderColor}): _unlockedEmojis = unlockedEmojis;
  factory _SquadMemberModel.fromJson(Map<String, dynamic> json) => _$SquadMemberModelFromJson(json);

@override final  String userId;
@override final  String role;
@override final  String email;
@override final  int totalXP;
 final  List<String> _unlockedEmojis;
@override@JsonKey() List<String> get unlockedEmojis {
  if (_unlockedEmojis is EqualUnmodifiableListView) return _unlockedEmojis;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_unlockedEmojis);
}

@override final  String? avatarBorderColor;

/// Create a copy of SquadMemberModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SquadMemberModelCopyWith<_SquadMemberModel> get copyWith => __$SquadMemberModelCopyWithImpl<_SquadMemberModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SquadMemberModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SquadMemberModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.role, role) || other.role == role)&&(identical(other.email, email) || other.email == email)&&(identical(other.totalXP, totalXP) || other.totalXP == totalXP)&&const DeepCollectionEquality().equals(other._unlockedEmojis, _unlockedEmojis)&&(identical(other.avatarBorderColor, avatarBorderColor) || other.avatarBorderColor == avatarBorderColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,role,email,totalXP,const DeepCollectionEquality().hash(_unlockedEmojis),avatarBorderColor);

@override
String toString() {
  return 'SquadMemberModel(userId: $userId, role: $role, email: $email, totalXP: $totalXP, unlockedEmojis: $unlockedEmojis, avatarBorderColor: $avatarBorderColor)';
}


}

/// @nodoc
abstract mixin class _$SquadMemberModelCopyWith<$Res> implements $SquadMemberModelCopyWith<$Res> {
  factory _$SquadMemberModelCopyWith(_SquadMemberModel value, $Res Function(_SquadMemberModel) _then) = __$SquadMemberModelCopyWithImpl;
@override @useResult
$Res call({
 String userId, String role, String email, int totalXP, List<String> unlockedEmojis, String? avatarBorderColor
});




}
/// @nodoc
class __$SquadMemberModelCopyWithImpl<$Res>
    implements _$SquadMemberModelCopyWith<$Res> {
  __$SquadMemberModelCopyWithImpl(this._self, this._then);

  final _SquadMemberModel _self;
  final $Res Function(_SquadMemberModel) _then;

/// Create a copy of SquadMemberModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? role = null,Object? email = null,Object? totalXP = null,Object? unlockedEmojis = null,Object? avatarBorderColor = freezed,}) {
  return _then(_SquadMemberModel(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,totalXP: null == totalXP ? _self.totalXP : totalXP // ignore: cast_nullable_to_non_nullable
as int,unlockedEmojis: null == unlockedEmojis ? _self._unlockedEmojis : unlockedEmojis // ignore: cast_nullable_to_non_nullable
as List<String>,avatarBorderColor: freezed == avatarBorderColor ? _self.avatarBorderColor : avatarBorderColor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
