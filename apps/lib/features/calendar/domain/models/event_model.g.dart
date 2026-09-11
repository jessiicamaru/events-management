// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EventModel _$EventModelFromJson(Map<String, dynamic> json) => _EventModel(
  id: json['id'] as String,
  title: json['title'] as String,
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: DateTime.parse(json['endTime'] as String),
  habitId: json['habitId'] as String,
  isCompleted: json['isCompleted'] as bool? ?? false,
  targetDuration: const TimeSpanConverter().fromJson(
    json['targetDuration'] as String?,
  ),
  actualDuration: const TimeSpanConverter().fromJson(
    json['actualDuration'] as String?,
  ),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$EventModelToJson(
  _EventModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'startTime': instance.startTime.toIso8601String(),
  'endTime': instance.endTime.toIso8601String(),
  'habitId': instance.habitId,
  'isCompleted': instance.isCompleted,
  'targetDuration': const TimeSpanConverter().toJson(instance.targetDuration),
  'actualDuration': const TimeSpanConverter().toJson(instance.actualDuration),
  'createdAt': instance.createdAt?.toIso8601String(),
};
