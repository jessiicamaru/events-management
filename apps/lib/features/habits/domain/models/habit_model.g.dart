// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HabitModel _$HabitModelFromJson(Map<String, dynamic> json) => _HabitModel(
  id: json['id'] as String,
  name: json['name'] as String,
  targetDays: (json['targetDays'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  category: json['category'] as String?,
  streak: (json['streak'] as num?)?.toInt() ?? 0,
  heatmapData:
      (json['heatmapData'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(DateTime.parse(k), (e as num).toInt()),
      ) ??
      const {},
);

Map<String, dynamic> _$HabitModelToJson(_HabitModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'targetDays': instance.targetDays,
      'category': instance.category,
      'streak': instance.streak,
      'heatmapData': instance.heatmapData.map(
        (k, e) => MapEntry(k.toIso8601String(), e),
      ),
    };
