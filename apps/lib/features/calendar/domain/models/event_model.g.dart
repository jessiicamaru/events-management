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
  categoryId: json['categoryId'] as String?,
  targetDuration: const TimeSpanConverter().fromJson(
    json['targetDuration'] as String?,
  ),
  actualDuration: const TimeSpanConverter().fromJson(
    json['actualDuration'] as String?,
  ),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  userId: json['userId'] as String?,
  tasks: (json['tasks'] as List<dynamic>?)
      ?.map((e) => EventTaskModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  recurrenceRule: json['recurrenceRule'] as String?,
  recurrenceExceptionDates: json['recurrenceExceptionDates'] as String?,
  parentEventId: json['parentEventId'] as String?,
  exceptionDate: json['exceptionDate'] == null
      ? null
      : DateTime.parse(json['exceptionDate'] as String),
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
  'categoryId': instance.categoryId,
  'targetDuration': const TimeSpanConverter().toJson(instance.targetDuration),
  'actualDuration': const TimeSpanConverter().toJson(instance.actualDuration),
  'createdAt': instance.createdAt?.toIso8601String(),
  'userId': instance.userId,
  'tasks': ?instance.tasks,
  'recurrenceRule': instance.recurrenceRule,
  'recurrenceExceptionDates': instance.recurrenceExceptionDates,
  'parentEventId': instance.parentEventId,
  'exceptionDate': instance.exceptionDate?.toIso8601String(),
};
