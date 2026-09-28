// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'squad_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SquadModel _$SquadModelFromJson(Map<String, dynamic> json) => _SquadModel(
  id: json['id'] as String,
  name: json['name'] as String,
  maxMembers: (json['maxMembers'] as num).toInt(),
  requireApproval: json['requireApproval'] as bool,
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
      'maxMembers': instance.maxMembers,
      'requireApproval': instance.requireApproval,
      'totalSquadXP': instance.totalSquadXP,
      'members': instance.members,
    };

_SquadMemberModel _$SquadMemberModelFromJson(Map<String, dynamic> json) =>
    _SquadMemberModel(
      userId: json['userId'] as String,
      role: json['role'] as String,
      email: json['email'] as String,
      totalXP: (json['totalXP'] as num).toInt(),
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      unlockedEmojis:
          (json['unlockedEmojis'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      avatarBorderColor: json['avatarBorderColor'] as String?,
      nickname: json['nickname'] as String?,
      isMuted: json['isMuted'] as bool,
      xpContributionEnabled: json['xpContributionEnabled'] as bool,
      isApproved: json['isApproved'] as bool,
    );

Map<String, dynamic> _$SquadMemberModelToJson(_SquadMemberModel instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'role': instance.role,
      'email': instance.email,
      'totalXP': instance.totalXP,
      'currentStreak': instance.currentStreak,
      'unlockedEmojis': instance.unlockedEmojis,
      'avatarBorderColor': instance.avatarBorderColor,
      'nickname': instance.nickname,
      'isMuted': instance.isMuted,
      'xpContributionEnabled': instance.xpContributionEnabled,
      'isApproved': instance.isApproved,
    };

_MySquadSummaryModel _$MySquadSummaryModelFromJson(Map<String, dynamic> json) =>
    _MySquadSummaryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      memberCount: (json['memberCount'] as num).toInt(),
      maxMembers: (json['maxMembers'] as num).toInt(),
      totalSquadXP: (json['totalSquadXP'] as num).toInt(),
    );

Map<String, dynamic> _$MySquadSummaryModelToJson(
  _MySquadSummaryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'memberCount': instance.memberCount,
  'maxMembers': instance.maxMembers,
  'totalSquadXP': instance.totalSquadXP,
};

_SquadChatMessageModel _$SquadChatMessageModelFromJson(
  Map<String, dynamic> json,
) => _SquadChatMessageModel(
  id: json['id'] as String,
  squadId: json['squadId'] as String,
  senderUserId: json['senderUserId'] as String?,
  senderDisplayName: json['senderDisplayName'] as String,
  message: json['message'] as String,
  sentAt: DateTime.parse(json['sentAt'] as String),
  isSystemMessage: json['isSystemMessage'] as bool,
);

Map<String, dynamic> _$SquadChatMessageModelToJson(
  _SquadChatMessageModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'squadId': instance.squadId,
  'senderUserId': instance.senderUserId,
  'senderDisplayName': instance.senderDisplayName,
  'message': instance.message,
  'sentAt': instance.sentAt.toIso8601String(),
  'isSystemMessage': instance.isSystemMessage,
};
