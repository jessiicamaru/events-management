// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserProfileModel {

 String get id; String get email; int get totalXP; List<String> get unlockedEmojis; String? get avatarBorderColor; String? get displayName; String? get bio; DateTime? get dateOfBirth; String? get gender; String? get phoneNumber; String? get avatar;
/// Create a copy of UserProfileModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileModelCopyWith<UserProfileModel> get copyWith => _$UserProfileModelCopyWithImpl<UserProfileModel>(this as UserProfileModel, _$identity);

  /// Serializes this UserProfileModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfileModel&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.totalXP, totalXP) || other.totalXP == totalXP)&&const DeepCollectionEquality().equals(other.unlockedEmojis, unlockedEmojis)&&(identical(other.avatarBorderColor, avatarBorderColor) || other.avatarBorderColor == avatarBorderColor)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.avatar, avatar) || other.avatar == avatar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,totalXP,const DeepCollectionEquality().hash(unlockedEmojis),avatarBorderColor,displayName,bio,dateOfBirth,gender,phoneNumber,avatar);

@override
String toString() {
  return 'UserProfileModel(id: $id, email: $email, totalXP: $totalXP, unlockedEmojis: $unlockedEmojis, avatarBorderColor: $avatarBorderColor, displayName: $displayName, bio: $bio, dateOfBirth: $dateOfBirth, gender: $gender, phoneNumber: $phoneNumber, avatar: $avatar)';
}


}

/// @nodoc
abstract mixin class $UserProfileModelCopyWith<$Res>  {
  factory $UserProfileModelCopyWith(UserProfileModel value, $Res Function(UserProfileModel) _then) = _$UserProfileModelCopyWithImpl;
@useResult
$Res call({
 String id, String email, int totalXP, List<String> unlockedEmojis, String? avatarBorderColor, String? displayName, String? bio, DateTime? dateOfBirth, String? gender, String? phoneNumber, String? avatar
});




}
/// @nodoc
class _$UserProfileModelCopyWithImpl<$Res>
    implements $UserProfileModelCopyWith<$Res> {
  _$UserProfileModelCopyWithImpl(this._self, this._then);

  final UserProfileModel _self;
  final $Res Function(UserProfileModel) _then;

/// Create a copy of UserProfileModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? email = null,Object? totalXP = null,Object? unlockedEmojis = null,Object? avatarBorderColor = freezed,Object? displayName = freezed,Object? bio = freezed,Object? dateOfBirth = freezed,Object? gender = freezed,Object? phoneNumber = freezed,Object? avatar = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,totalXP: null == totalXP ? _self.totalXP : totalXP // ignore: cast_nullable_to_non_nullable
as int,unlockedEmojis: null == unlockedEmojis ? _self.unlockedEmojis : unlockedEmojis // ignore: cast_nullable_to_non_nullable
as List<String>,avatarBorderColor: freezed == avatarBorderColor ? _self.avatarBorderColor : avatarBorderColor // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfileModel].
extension UserProfileModelPatterns on UserProfileModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfileModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfileModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfileModel value)  $default,){
final _that = this;
switch (_that) {
case _UserProfileModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfileModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfileModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String email,  int totalXP,  List<String> unlockedEmojis,  String? avatarBorderColor,  String? displayName,  String? bio,  DateTime? dateOfBirth,  String? gender,  String? phoneNumber,  String? avatar)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfileModel() when $default != null:
return $default(_that.id,_that.email,_that.totalXP,_that.unlockedEmojis,_that.avatarBorderColor,_that.displayName,_that.bio,_that.dateOfBirth,_that.gender,_that.phoneNumber,_that.avatar);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String email,  int totalXP,  List<String> unlockedEmojis,  String? avatarBorderColor,  String? displayName,  String? bio,  DateTime? dateOfBirth,  String? gender,  String? phoneNumber,  String? avatar)  $default,) {final _that = this;
switch (_that) {
case _UserProfileModel():
return $default(_that.id,_that.email,_that.totalXP,_that.unlockedEmojis,_that.avatarBorderColor,_that.displayName,_that.bio,_that.dateOfBirth,_that.gender,_that.phoneNumber,_that.avatar);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String email,  int totalXP,  List<String> unlockedEmojis,  String? avatarBorderColor,  String? displayName,  String? bio,  DateTime? dateOfBirth,  String? gender,  String? phoneNumber,  String? avatar)?  $default,) {final _that = this;
switch (_that) {
case _UserProfileModel() when $default != null:
return $default(_that.id,_that.email,_that.totalXP,_that.unlockedEmojis,_that.avatarBorderColor,_that.displayName,_that.bio,_that.dateOfBirth,_that.gender,_that.phoneNumber,_that.avatar);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserProfileModel implements UserProfileModel {
  const _UserProfileModel({required this.id, required this.email, required this.totalXP, final  List<String> unlockedEmojis = const [], this.avatarBorderColor, this.displayName, this.bio, this.dateOfBirth, this.gender, this.phoneNumber, this.avatar}): _unlockedEmojis = unlockedEmojis;
  factory _UserProfileModel.fromJson(Map<String, dynamic> json) => _$UserProfileModelFromJson(json);

@override final  String id;
@override final  String email;
@override final  int totalXP;
 final  List<String> _unlockedEmojis;
@override@JsonKey() List<String> get unlockedEmojis {
  if (_unlockedEmojis is EqualUnmodifiableListView) return _unlockedEmojis;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_unlockedEmojis);
}

@override final  String? avatarBorderColor;
@override final  String? displayName;
@override final  String? bio;
@override final  DateTime? dateOfBirth;
@override final  String? gender;
@override final  String? phoneNumber;
@override final  String? avatar;

/// Create a copy of UserProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileModelCopyWith<_UserProfileModel> get copyWith => __$UserProfileModelCopyWithImpl<_UserProfileModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserProfileModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfileModel&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.totalXP, totalXP) || other.totalXP == totalXP)&&const DeepCollectionEquality().equals(other._unlockedEmojis, _unlockedEmojis)&&(identical(other.avatarBorderColor, avatarBorderColor) || other.avatarBorderColor == avatarBorderColor)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.avatar, avatar) || other.avatar == avatar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,totalXP,const DeepCollectionEquality().hash(_unlockedEmojis),avatarBorderColor,displayName,bio,dateOfBirth,gender,phoneNumber,avatar);

@override
String toString() {
  return 'UserProfileModel(id: $id, email: $email, totalXP: $totalXP, unlockedEmojis: $unlockedEmojis, avatarBorderColor: $avatarBorderColor, displayName: $displayName, bio: $bio, dateOfBirth: $dateOfBirth, gender: $gender, phoneNumber: $phoneNumber, avatar: $avatar)';
}


}

/// @nodoc
abstract mixin class _$UserProfileModelCopyWith<$Res> implements $UserProfileModelCopyWith<$Res> {
  factory _$UserProfileModelCopyWith(_UserProfileModel value, $Res Function(_UserProfileModel) _then) = __$UserProfileModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String email, int totalXP, List<String> unlockedEmojis, String? avatarBorderColor, String? displayName, String? bio, DateTime? dateOfBirth, String? gender, String? phoneNumber, String? avatar
});




}
/// @nodoc
class __$UserProfileModelCopyWithImpl<$Res>
    implements _$UserProfileModelCopyWith<$Res> {
  __$UserProfileModelCopyWithImpl(this._self, this._then);

  final _UserProfileModel _self;
  final $Res Function(_UserProfileModel) _then;

/// Create a copy of UserProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? email = null,Object? totalXP = null,Object? unlockedEmojis = null,Object? avatarBorderColor = freezed,Object? displayName = freezed,Object? bio = freezed,Object? dateOfBirth = freezed,Object? gender = freezed,Object? phoneNumber = freezed,Object? avatar = freezed,}) {
  return _then(_UserProfileModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,totalXP: null == totalXP ? _self.totalXP : totalXP // ignore: cast_nullable_to_non_nullable
as int,unlockedEmojis: null == unlockedEmojis ? _self._unlockedEmojis : unlockedEmojis // ignore: cast_nullable_to_non_nullable
as List<String>,avatarBorderColor: freezed == avatarBorderColor ? _self.avatarBorderColor : avatarBorderColor // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
