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

 String get id; String get name; int get maxMembers; bool get requireApproval; int get totalSquadXP; List<SquadMemberModel> get members;
/// Create a copy of SquadModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SquadModelCopyWith<SquadModel> get copyWith => _$SquadModelCopyWithImpl<SquadModel>(this as SquadModel, _$identity);

  /// Serializes this SquadModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SquadModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&(identical(other.requireApproval, requireApproval) || other.requireApproval == requireApproval)&&(identical(other.totalSquadXP, totalSquadXP) || other.totalSquadXP == totalSquadXP)&&const DeepCollectionEquality().equals(other.members, members));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,maxMembers,requireApproval,totalSquadXP,const DeepCollectionEquality().hash(members));

@override
String toString() {
  return 'SquadModel(id: $id, name: $name, maxMembers: $maxMembers, requireApproval: $requireApproval, totalSquadXP: $totalSquadXP, members: $members)';
}


}

/// @nodoc
abstract mixin class $SquadModelCopyWith<$Res>  {
  factory $SquadModelCopyWith(SquadModel value, $Res Function(SquadModel) _then) = _$SquadModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, int maxMembers, bool requireApproval, int totalSquadXP, List<SquadMemberModel> members
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? maxMembers = null,Object? requireApproval = null,Object? totalSquadXP = null,Object? members = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,maxMembers: null == maxMembers ? _self.maxMembers : maxMembers // ignore: cast_nullable_to_non_nullable
as int,requireApproval: null == requireApproval ? _self.requireApproval : requireApproval // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int maxMembers,  bool requireApproval,  int totalSquadXP,  List<SquadMemberModel> members)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SquadModel() when $default != null:
return $default(_that.id,_that.name,_that.maxMembers,_that.requireApproval,_that.totalSquadXP,_that.members);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int maxMembers,  bool requireApproval,  int totalSquadXP,  List<SquadMemberModel> members)  $default,) {final _that = this;
switch (_that) {
case _SquadModel():
return $default(_that.id,_that.name,_that.maxMembers,_that.requireApproval,_that.totalSquadXP,_that.members);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int maxMembers,  bool requireApproval,  int totalSquadXP,  List<SquadMemberModel> members)?  $default,) {final _that = this;
switch (_that) {
case _SquadModel() when $default != null:
return $default(_that.id,_that.name,_that.maxMembers,_that.requireApproval,_that.totalSquadXP,_that.members);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SquadModel implements SquadModel {
  const _SquadModel({required this.id, required this.name, required this.maxMembers, required this.requireApproval, required this.totalSquadXP, final  List<SquadMemberModel> members = const []}): _members = members;
  factory _SquadModel.fromJson(Map<String, dynamic> json) => _$SquadModelFromJson(json);

@override final  String id;
@override final  String name;
@override final  int maxMembers;
@override final  bool requireApproval;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SquadModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&(identical(other.requireApproval, requireApproval) || other.requireApproval == requireApproval)&&(identical(other.totalSquadXP, totalSquadXP) || other.totalSquadXP == totalSquadXP)&&const DeepCollectionEquality().equals(other._members, _members));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,maxMembers,requireApproval,totalSquadXP,const DeepCollectionEquality().hash(_members));

@override
String toString() {
  return 'SquadModel(id: $id, name: $name, maxMembers: $maxMembers, requireApproval: $requireApproval, totalSquadXP: $totalSquadXP, members: $members)';
}


}

/// @nodoc
abstract mixin class _$SquadModelCopyWith<$Res> implements $SquadModelCopyWith<$Res> {
  factory _$SquadModelCopyWith(_SquadModel value, $Res Function(_SquadModel) _then) = __$SquadModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int maxMembers, bool requireApproval, int totalSquadXP, List<SquadMemberModel> members
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? maxMembers = null,Object? requireApproval = null,Object? totalSquadXP = null,Object? members = null,}) {
  return _then(_SquadModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,maxMembers: null == maxMembers ? _self.maxMembers : maxMembers // ignore: cast_nullable_to_non_nullable
as int,requireApproval: null == requireApproval ? _self.requireApproval : requireApproval // ignore: cast_nullable_to_non_nullable
as bool,totalSquadXP: null == totalSquadXP ? _self.totalSquadXP : totalSquadXP // ignore: cast_nullable_to_non_nullable
as int,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<SquadMemberModel>,
  ));
}


}


/// @nodoc
mixin _$SquadMemberModel {

 String get userId; String get role; String get email; int get totalXP; int get currentStreak; List<String> get unlockedEmojis; String? get avatarBorderColor; String? get nickname; bool get isMuted; bool get xpContributionEnabled; bool get isApproved;
/// Create a copy of SquadMemberModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SquadMemberModelCopyWith<SquadMemberModel> get copyWith => _$SquadMemberModelCopyWithImpl<SquadMemberModel>(this as SquadMemberModel, _$identity);

  /// Serializes this SquadMemberModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SquadMemberModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.role, role) || other.role == role)&&(identical(other.email, email) || other.email == email)&&(identical(other.totalXP, totalXP) || other.totalXP == totalXP)&&(identical(other.currentStreak, currentStreak) || other.currentStreak == currentStreak)&&const DeepCollectionEquality().equals(other.unlockedEmojis, unlockedEmojis)&&(identical(other.avatarBorderColor, avatarBorderColor) || other.avatarBorderColor == avatarBorderColor)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.xpContributionEnabled, xpContributionEnabled) || other.xpContributionEnabled == xpContributionEnabled)&&(identical(other.isApproved, isApproved) || other.isApproved == isApproved));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,role,email,totalXP,currentStreak,const DeepCollectionEquality().hash(unlockedEmojis),avatarBorderColor,nickname,isMuted,xpContributionEnabled,isApproved);

@override
String toString() {
  return 'SquadMemberModel(userId: $userId, role: $role, email: $email, totalXP: $totalXP, currentStreak: $currentStreak, unlockedEmojis: $unlockedEmojis, avatarBorderColor: $avatarBorderColor, nickname: $nickname, isMuted: $isMuted, xpContributionEnabled: $xpContributionEnabled, isApproved: $isApproved)';
}


}

/// @nodoc
abstract mixin class $SquadMemberModelCopyWith<$Res>  {
  factory $SquadMemberModelCopyWith(SquadMemberModel value, $Res Function(SquadMemberModel) _then) = _$SquadMemberModelCopyWithImpl;
@useResult
$Res call({
 String userId, String role, String email, int totalXP, int currentStreak, List<String> unlockedEmojis, String? avatarBorderColor, String? nickname, bool isMuted, bool xpContributionEnabled, bool isApproved
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
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? role = null,Object? email = null,Object? totalXP = null,Object? currentStreak = null,Object? unlockedEmojis = null,Object? avatarBorderColor = freezed,Object? nickname = freezed,Object? isMuted = null,Object? xpContributionEnabled = null,Object? isApproved = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,totalXP: null == totalXP ? _self.totalXP : totalXP // ignore: cast_nullable_to_non_nullable
as int,currentStreak: null == currentStreak ? _self.currentStreak : currentStreak // ignore: cast_nullable_to_non_nullable
as int,unlockedEmojis: null == unlockedEmojis ? _self.unlockedEmojis : unlockedEmojis // ignore: cast_nullable_to_non_nullable
as List<String>,avatarBorderColor: freezed == avatarBorderColor ? _self.avatarBorderColor : avatarBorderColor // ignore: cast_nullable_to_non_nullable
as String?,nickname: freezed == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String?,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,xpContributionEnabled: null == xpContributionEnabled ? _self.xpContributionEnabled : xpContributionEnabled // ignore: cast_nullable_to_non_nullable
as bool,isApproved: null == isApproved ? _self.isApproved : isApproved // ignore: cast_nullable_to_non_nullable
as bool,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String role,  String email,  int totalXP,  int currentStreak,  List<String> unlockedEmojis,  String? avatarBorderColor,  String? nickname,  bool isMuted,  bool xpContributionEnabled,  bool isApproved)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SquadMemberModel() when $default != null:
return $default(_that.userId,_that.role,_that.email,_that.totalXP,_that.currentStreak,_that.unlockedEmojis,_that.avatarBorderColor,_that.nickname,_that.isMuted,_that.xpContributionEnabled,_that.isApproved);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String role,  String email,  int totalXP,  int currentStreak,  List<String> unlockedEmojis,  String? avatarBorderColor,  String? nickname,  bool isMuted,  bool xpContributionEnabled,  bool isApproved)  $default,) {final _that = this;
switch (_that) {
case _SquadMemberModel():
return $default(_that.userId,_that.role,_that.email,_that.totalXP,_that.currentStreak,_that.unlockedEmojis,_that.avatarBorderColor,_that.nickname,_that.isMuted,_that.xpContributionEnabled,_that.isApproved);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String role,  String email,  int totalXP,  int currentStreak,  List<String> unlockedEmojis,  String? avatarBorderColor,  String? nickname,  bool isMuted,  bool xpContributionEnabled,  bool isApproved)?  $default,) {final _that = this;
switch (_that) {
case _SquadMemberModel() when $default != null:
return $default(_that.userId,_that.role,_that.email,_that.totalXP,_that.currentStreak,_that.unlockedEmojis,_that.avatarBorderColor,_that.nickname,_that.isMuted,_that.xpContributionEnabled,_that.isApproved);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SquadMemberModel implements SquadMemberModel {
  const _SquadMemberModel({required this.userId, required this.role, required this.email, required this.totalXP, this.currentStreak = 0, final  List<String> unlockedEmojis = const [], this.avatarBorderColor, this.nickname, required this.isMuted, required this.xpContributionEnabled, required this.isApproved}): _unlockedEmojis = unlockedEmojis;
  factory _SquadMemberModel.fromJson(Map<String, dynamic> json) => _$SquadMemberModelFromJson(json);

@override final  String userId;
@override final  String role;
@override final  String email;
@override final  int totalXP;
@override@JsonKey() final  int currentStreak;
 final  List<String> _unlockedEmojis;
@override@JsonKey() List<String> get unlockedEmojis {
  if (_unlockedEmojis is EqualUnmodifiableListView) return _unlockedEmojis;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_unlockedEmojis);
}

@override final  String? avatarBorderColor;
@override final  String? nickname;
@override final  bool isMuted;
@override final  bool xpContributionEnabled;
@override final  bool isApproved;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SquadMemberModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.role, role) || other.role == role)&&(identical(other.email, email) || other.email == email)&&(identical(other.totalXP, totalXP) || other.totalXP == totalXP)&&(identical(other.currentStreak, currentStreak) || other.currentStreak == currentStreak)&&const DeepCollectionEquality().equals(other._unlockedEmojis, _unlockedEmojis)&&(identical(other.avatarBorderColor, avatarBorderColor) || other.avatarBorderColor == avatarBorderColor)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.xpContributionEnabled, xpContributionEnabled) || other.xpContributionEnabled == xpContributionEnabled)&&(identical(other.isApproved, isApproved) || other.isApproved == isApproved));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,role,email,totalXP,currentStreak,const DeepCollectionEquality().hash(_unlockedEmojis),avatarBorderColor,nickname,isMuted,xpContributionEnabled,isApproved);

@override
String toString() {
  return 'SquadMemberModel(userId: $userId, role: $role, email: $email, totalXP: $totalXP, currentStreak: $currentStreak, unlockedEmojis: $unlockedEmojis, avatarBorderColor: $avatarBorderColor, nickname: $nickname, isMuted: $isMuted, xpContributionEnabled: $xpContributionEnabled, isApproved: $isApproved)';
}


}

/// @nodoc
abstract mixin class _$SquadMemberModelCopyWith<$Res> implements $SquadMemberModelCopyWith<$Res> {
  factory _$SquadMemberModelCopyWith(_SquadMemberModel value, $Res Function(_SquadMemberModel) _then) = __$SquadMemberModelCopyWithImpl;
@override @useResult
$Res call({
 String userId, String role, String email, int totalXP, int currentStreak, List<String> unlockedEmojis, String? avatarBorderColor, String? nickname, bool isMuted, bool xpContributionEnabled, bool isApproved
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
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? role = null,Object? email = null,Object? totalXP = null,Object? currentStreak = null,Object? unlockedEmojis = null,Object? avatarBorderColor = freezed,Object? nickname = freezed,Object? isMuted = null,Object? xpContributionEnabled = null,Object? isApproved = null,}) {
  return _then(_SquadMemberModel(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,totalXP: null == totalXP ? _self.totalXP : totalXP // ignore: cast_nullable_to_non_nullable
as int,currentStreak: null == currentStreak ? _self.currentStreak : currentStreak // ignore: cast_nullable_to_non_nullable
as int,unlockedEmojis: null == unlockedEmojis ? _self._unlockedEmojis : unlockedEmojis // ignore: cast_nullable_to_non_nullable
as List<String>,avatarBorderColor: freezed == avatarBorderColor ? _self.avatarBorderColor : avatarBorderColor // ignore: cast_nullable_to_non_nullable
as String?,nickname: freezed == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String?,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,xpContributionEnabled: null == xpContributionEnabled ? _self.xpContributionEnabled : xpContributionEnabled // ignore: cast_nullable_to_non_nullable
as bool,isApproved: null == isApproved ? _self.isApproved : isApproved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$MySquadSummaryModel {

 String get id; String get name; int get memberCount; int get maxMembers; int get totalSquadXP;
/// Create a copy of MySquadSummaryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MySquadSummaryModelCopyWith<MySquadSummaryModel> get copyWith => _$MySquadSummaryModelCopyWithImpl<MySquadSummaryModel>(this as MySquadSummaryModel, _$identity);

  /// Serializes this MySquadSummaryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MySquadSummaryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&(identical(other.totalSquadXP, totalSquadXP) || other.totalSquadXP == totalSquadXP));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,memberCount,maxMembers,totalSquadXP);

@override
String toString() {
  return 'MySquadSummaryModel(id: $id, name: $name, memberCount: $memberCount, maxMembers: $maxMembers, totalSquadXP: $totalSquadXP)';
}


}

/// @nodoc
abstract mixin class $MySquadSummaryModelCopyWith<$Res>  {
  factory $MySquadSummaryModelCopyWith(MySquadSummaryModel value, $Res Function(MySquadSummaryModel) _then) = _$MySquadSummaryModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, int memberCount, int maxMembers, int totalSquadXP
});




}
/// @nodoc
class _$MySquadSummaryModelCopyWithImpl<$Res>
    implements $MySquadSummaryModelCopyWith<$Res> {
  _$MySquadSummaryModelCopyWithImpl(this._self, this._then);

  final MySquadSummaryModel _self;
  final $Res Function(MySquadSummaryModel) _then;

/// Create a copy of MySquadSummaryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? memberCount = null,Object? maxMembers = null,Object? totalSquadXP = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,maxMembers: null == maxMembers ? _self.maxMembers : maxMembers // ignore: cast_nullable_to_non_nullable
as int,totalSquadXP: null == totalSquadXP ? _self.totalSquadXP : totalSquadXP // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MySquadSummaryModel].
extension MySquadSummaryModelPatterns on MySquadSummaryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MySquadSummaryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MySquadSummaryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MySquadSummaryModel value)  $default,){
final _that = this;
switch (_that) {
case _MySquadSummaryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MySquadSummaryModel value)?  $default,){
final _that = this;
switch (_that) {
case _MySquadSummaryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int memberCount,  int maxMembers,  int totalSquadXP)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MySquadSummaryModel() when $default != null:
return $default(_that.id,_that.name,_that.memberCount,_that.maxMembers,_that.totalSquadXP);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int memberCount,  int maxMembers,  int totalSquadXP)  $default,) {final _that = this;
switch (_that) {
case _MySquadSummaryModel():
return $default(_that.id,_that.name,_that.memberCount,_that.maxMembers,_that.totalSquadXP);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int memberCount,  int maxMembers,  int totalSquadXP)?  $default,) {final _that = this;
switch (_that) {
case _MySquadSummaryModel() when $default != null:
return $default(_that.id,_that.name,_that.memberCount,_that.maxMembers,_that.totalSquadXP);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MySquadSummaryModel implements MySquadSummaryModel {
  const _MySquadSummaryModel({required this.id, required this.name, required this.memberCount, required this.maxMembers, required this.totalSquadXP});
  factory _MySquadSummaryModel.fromJson(Map<String, dynamic> json) => _$MySquadSummaryModelFromJson(json);

@override final  String id;
@override final  String name;
@override final  int memberCount;
@override final  int maxMembers;
@override final  int totalSquadXP;

/// Create a copy of MySquadSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MySquadSummaryModelCopyWith<_MySquadSummaryModel> get copyWith => __$MySquadSummaryModelCopyWithImpl<_MySquadSummaryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MySquadSummaryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MySquadSummaryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&(identical(other.totalSquadXP, totalSquadXP) || other.totalSquadXP == totalSquadXP));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,memberCount,maxMembers,totalSquadXP);

@override
String toString() {
  return 'MySquadSummaryModel(id: $id, name: $name, memberCount: $memberCount, maxMembers: $maxMembers, totalSquadXP: $totalSquadXP)';
}


}

/// @nodoc
abstract mixin class _$MySquadSummaryModelCopyWith<$Res> implements $MySquadSummaryModelCopyWith<$Res> {
  factory _$MySquadSummaryModelCopyWith(_MySquadSummaryModel value, $Res Function(_MySquadSummaryModel) _then) = __$MySquadSummaryModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int memberCount, int maxMembers, int totalSquadXP
});




}
/// @nodoc
class __$MySquadSummaryModelCopyWithImpl<$Res>
    implements _$MySquadSummaryModelCopyWith<$Res> {
  __$MySquadSummaryModelCopyWithImpl(this._self, this._then);

  final _MySquadSummaryModel _self;
  final $Res Function(_MySquadSummaryModel) _then;

/// Create a copy of MySquadSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? memberCount = null,Object? maxMembers = null,Object? totalSquadXP = null,}) {
  return _then(_MySquadSummaryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,maxMembers: null == maxMembers ? _self.maxMembers : maxMembers // ignore: cast_nullable_to_non_nullable
as int,totalSquadXP: null == totalSquadXP ? _self.totalSquadXP : totalSquadXP // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SquadChatMessageModel {

 String get id; String get squadId; String? get senderUserId; String get senderDisplayName; String get message; DateTime get sentAt; bool get isSystemMessage;
/// Create a copy of SquadChatMessageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SquadChatMessageModelCopyWith<SquadChatMessageModel> get copyWith => _$SquadChatMessageModelCopyWithImpl<SquadChatMessageModel>(this as SquadChatMessageModel, _$identity);

  /// Serializes this SquadChatMessageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SquadChatMessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.squadId, squadId) || other.squadId == squadId)&&(identical(other.senderUserId, senderUserId) || other.senderUserId == senderUserId)&&(identical(other.senderDisplayName, senderDisplayName) || other.senderDisplayName == senderDisplayName)&&(identical(other.message, message) || other.message == message)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.isSystemMessage, isSystemMessage) || other.isSystemMessage == isSystemMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,squadId,senderUserId,senderDisplayName,message,sentAt,isSystemMessage);

@override
String toString() {
  return 'SquadChatMessageModel(id: $id, squadId: $squadId, senderUserId: $senderUserId, senderDisplayName: $senderDisplayName, message: $message, sentAt: $sentAt, isSystemMessage: $isSystemMessage)';
}


}

/// @nodoc
abstract mixin class $SquadChatMessageModelCopyWith<$Res>  {
  factory $SquadChatMessageModelCopyWith(SquadChatMessageModel value, $Res Function(SquadChatMessageModel) _then) = _$SquadChatMessageModelCopyWithImpl;
@useResult
$Res call({
 String id, String squadId, String? senderUserId, String senderDisplayName, String message, DateTime sentAt, bool isSystemMessage
});




}
/// @nodoc
class _$SquadChatMessageModelCopyWithImpl<$Res>
    implements $SquadChatMessageModelCopyWith<$Res> {
  _$SquadChatMessageModelCopyWithImpl(this._self, this._then);

  final SquadChatMessageModel _self;
  final $Res Function(SquadChatMessageModel) _then;

/// Create a copy of SquadChatMessageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? squadId = null,Object? senderUserId = freezed,Object? senderDisplayName = null,Object? message = null,Object? sentAt = null,Object? isSystemMessage = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,squadId: null == squadId ? _self.squadId : squadId // ignore: cast_nullable_to_non_nullable
as String,senderUserId: freezed == senderUserId ? _self.senderUserId : senderUserId // ignore: cast_nullable_to_non_nullable
as String?,senderDisplayName: null == senderDisplayName ? _self.senderDisplayName : senderDisplayName // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime,isSystemMessage: null == isSystemMessage ? _self.isSystemMessage : isSystemMessage // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SquadChatMessageModel].
extension SquadChatMessageModelPatterns on SquadChatMessageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SquadChatMessageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SquadChatMessageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SquadChatMessageModel value)  $default,){
final _that = this;
switch (_that) {
case _SquadChatMessageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SquadChatMessageModel value)?  $default,){
final _that = this;
switch (_that) {
case _SquadChatMessageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String squadId,  String? senderUserId,  String senderDisplayName,  String message,  DateTime sentAt,  bool isSystemMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SquadChatMessageModel() when $default != null:
return $default(_that.id,_that.squadId,_that.senderUserId,_that.senderDisplayName,_that.message,_that.sentAt,_that.isSystemMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String squadId,  String? senderUserId,  String senderDisplayName,  String message,  DateTime sentAt,  bool isSystemMessage)  $default,) {final _that = this;
switch (_that) {
case _SquadChatMessageModel():
return $default(_that.id,_that.squadId,_that.senderUserId,_that.senderDisplayName,_that.message,_that.sentAt,_that.isSystemMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String squadId,  String? senderUserId,  String senderDisplayName,  String message,  DateTime sentAt,  bool isSystemMessage)?  $default,) {final _that = this;
switch (_that) {
case _SquadChatMessageModel() when $default != null:
return $default(_that.id,_that.squadId,_that.senderUserId,_that.senderDisplayName,_that.message,_that.sentAt,_that.isSystemMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SquadChatMessageModel implements SquadChatMessageModel {
  const _SquadChatMessageModel({required this.id, required this.squadId, this.senderUserId, required this.senderDisplayName, required this.message, required this.sentAt, required this.isSystemMessage});
  factory _SquadChatMessageModel.fromJson(Map<String, dynamic> json) => _$SquadChatMessageModelFromJson(json);

@override final  String id;
@override final  String squadId;
@override final  String? senderUserId;
@override final  String senderDisplayName;
@override final  String message;
@override final  DateTime sentAt;
@override final  bool isSystemMessage;

/// Create a copy of SquadChatMessageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SquadChatMessageModelCopyWith<_SquadChatMessageModel> get copyWith => __$SquadChatMessageModelCopyWithImpl<_SquadChatMessageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SquadChatMessageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SquadChatMessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.squadId, squadId) || other.squadId == squadId)&&(identical(other.senderUserId, senderUserId) || other.senderUserId == senderUserId)&&(identical(other.senderDisplayName, senderDisplayName) || other.senderDisplayName == senderDisplayName)&&(identical(other.message, message) || other.message == message)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.isSystemMessage, isSystemMessage) || other.isSystemMessage == isSystemMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,squadId,senderUserId,senderDisplayName,message,sentAt,isSystemMessage);

@override
String toString() {
  return 'SquadChatMessageModel(id: $id, squadId: $squadId, senderUserId: $senderUserId, senderDisplayName: $senderDisplayName, message: $message, sentAt: $sentAt, isSystemMessage: $isSystemMessage)';
}


}

/// @nodoc
abstract mixin class _$SquadChatMessageModelCopyWith<$Res> implements $SquadChatMessageModelCopyWith<$Res> {
  factory _$SquadChatMessageModelCopyWith(_SquadChatMessageModel value, $Res Function(_SquadChatMessageModel) _then) = __$SquadChatMessageModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String squadId, String? senderUserId, String senderDisplayName, String message, DateTime sentAt, bool isSystemMessage
});




}
/// @nodoc
class __$SquadChatMessageModelCopyWithImpl<$Res>
    implements _$SquadChatMessageModelCopyWith<$Res> {
  __$SquadChatMessageModelCopyWithImpl(this._self, this._then);

  final _SquadChatMessageModel _self;
  final $Res Function(_SquadChatMessageModel) _then;

/// Create a copy of SquadChatMessageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? squadId = null,Object? senderUserId = freezed,Object? senderDisplayName = null,Object? message = null,Object? sentAt = null,Object? isSystemMessage = null,}) {
  return _then(_SquadChatMessageModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,squadId: null == squadId ? _self.squadId : squadId // ignore: cast_nullable_to_non_nullable
as String,senderUserId: freezed == senderUserId ? _self.senderUserId : senderUserId // ignore: cast_nullable_to_non_nullable
as String?,senderDisplayName: null == senderDisplayName ? _self.senderDisplayName : senderDisplayName // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime,isSystemMessage: null == isSystemMessage ? _self.isSystemMessage : isSystemMessage // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
