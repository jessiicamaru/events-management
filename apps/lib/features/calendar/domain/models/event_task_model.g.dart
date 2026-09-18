// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EventTaskModel _$EventTaskModelFromJson(Map<String, dynamic> json) =>
    _EventTaskModel(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      order: (json['order'] as num).toInt(),
      priority:
          $enumDecodeNullable(_$TaskPriorityEnumMap, json['priority']) ??
          TaskPriority.medium,
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt(),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );

Map<String, dynamic> _$EventTaskModelToJson(_EventTaskModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'title': instance.title,
      'description': instance.description,
      'order': instance.order,
      'priority': _$TaskPriorityEnumMap[instance.priority]!,
      'estimatedMinutes': instance.estimatedMinutes,
      'isCompleted': instance.isCompleted,
    };

const _$TaskPriorityEnumMap = {
  TaskPriority.low: 0,
  TaskPriority.medium: 1,
  TaskPriority.high: 2,
};
