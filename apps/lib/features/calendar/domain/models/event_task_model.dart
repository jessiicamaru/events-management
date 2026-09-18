import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../habits/domain/models/habit_task_model.dart';

part 'event_task_model.freezed.dart';
part 'event_task_model.g.dart';

@freezed
abstract class EventTaskModel with _$EventTaskModel {
  const factory EventTaskModel({
    required String id,
    required String eventId,
    required String title,
    String? description,
    required int order,
    @Default(TaskPriority.medium) TaskPriority priority,
    int? estimatedMinutes,
    @Default(false) bool isCompleted,
  }) = _EventTaskModel;

  factory EventTaskModel.fromJson(Map<String, dynamic> json) => _$EventTaskModelFromJson(json);
}
