import 'package:freezed_annotation/freezed_annotation.dart';

part 'habit_task_model.freezed.dart';
part 'habit_task_model.g.dart';

enum TaskPriority {
  @JsonValue(0) low,
  @JsonValue(1) medium,
  @JsonValue(2) high
}

@freezed
abstract class HabitTaskModel with _$HabitTaskModel {
  const factory HabitTaskModel({
    required String id,
    required String habitId,
    required String title,
    String? description,
    required int order,
    @Default(TaskPriority.medium) TaskPriority priority,
    int? estimatedMinutes,
  }) = _HabitTaskModel;

  factory HabitTaskModel.fromJson(Map<String, dynamic> json) => _$HabitTaskModelFromJson(json);
}
