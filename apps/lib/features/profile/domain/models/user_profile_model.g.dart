// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfileModel _$UserProfileModelFromJson(Map<String, dynamic> json) =>
    _UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      totalXP: (json['totalXP'] as num).toInt(),
      unlockedEmojis:
          (json['unlockedEmojis'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      avatarBorderColor: json['avatarBorderColor'] as String?,
      displayName: json['displayName'] as String?,
      bio: json['bio'] as String?,
      dateOfBirth: json['dateOfBirth'] == null
          ? null
          : DateTime.parse(json['dateOfBirth'] as String),
      gender: json['gender'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      avatar: json['avatar'] as String?,
    );

Map<String, dynamic> _$UserProfileModelToJson(_UserProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'totalXP': instance.totalXP,
      'unlockedEmojis': instance.unlockedEmojis,
      'avatarBorderColor': instance.avatarBorderColor,
      'displayName': instance.displayName,
      'bio': instance.bio,
      'dateOfBirth': instance.dateOfBirth?.toIso8601String(),
      'gender': instance.gender,
      'phoneNumber': instance.phoneNumber,
      'avatar': instance.avatar,
    };
