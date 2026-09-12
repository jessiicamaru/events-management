// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'squad_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SquadModel _$SquadModelFromJson(Map<String, dynamic> json) => _SquadModel(
  id: json['id'] as String,
  name: json['name'] as String,
  isBuddyMode: json['isBuddyMode'] as bool,
  totalSquadXP: (json['totalSquadXP'] as num).toInt(),
  members:
      (json['members'] as List<dynamic>?)
          ?.map((e) => SquadMemberModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SquadModelToJson(_SquadModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isBuddyMode': instance.isBuddyMode,
      'totalSquadXP': instance.totalSquadXP,
      'members': instance.members,
    };

_SquadMemberModel _$SquadMemberModelFromJson(Map<String, dynamic> json) =>
    _SquadMemberModel(
      userId: json['userId'] as String,
      role: json['role'] as String,
      email: json['email'] as String,
      totalXP: (json['totalXP'] as num).toInt(),
      unlockedEmojis:
          (json['unlockedEmojis'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      avatarBorderColor: json['avatarBorderColor'] as String?,
    );

Map<String, dynamic> _$SquadMemberModelToJson(_SquadMemberModel instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'role': instance.role,
      'email': instance.email,
      'totalXP': instance.totalXP,
      'unlockedEmojis': instance.unlockedEmojis,
      'avatarBorderColor': instance.avatarBorderColor,
    };
