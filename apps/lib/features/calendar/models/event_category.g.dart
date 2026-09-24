// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EventCategory _$EventCategoryFromJson(Map<String, dynamic> json) =>
    _EventCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      colorPreset: json['colorPreset'] as String,
      userId: json['userId'] as String?,
      squadId: json['squadId'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$EventCategoryToJson(_EventCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'colorPreset': instance.colorPreset,
      'userId': instance.userId,
      'squadId': instance.squadId,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
