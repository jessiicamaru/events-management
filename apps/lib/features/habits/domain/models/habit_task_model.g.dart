// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HabitTaskModel _$HabitTaskModelFromJson(Map<String, dynamic> json) =>
    _HabitTaskModel(
      id: json['id'] as String,
      habitId: json['habitId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      order: (json['order'] as num).toInt(),
      priority:
          $enumDecodeNullable(_$TaskPriorityEnumMap, json['priority']) ??
          TaskPriority.medium,
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$HabitTaskModelToJson(_HabitTaskModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'habitId': instance.habitId,
      'title': instance.title,
      'description': instance.description,
      'order': instance.order,
      'priority': _$TaskPriorityEnumMap[instance.priority]!,
      'estimatedMinutes': instance.estimatedMinutes,
    };

const _$TaskPriorityEnumMap = {
  TaskPriority.low: 0,
  TaskPriority.medium: 1,
  TaskPriority.high: 2,
};
