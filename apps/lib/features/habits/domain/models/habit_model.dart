import 'package:freezed_annotation/freezed_annotation.dart';

part 'habit_model.freezed.dart';
part 'habit_model.g.dart';

@freezed
abstract class HabitModel with _$HabitModel {
  const factory HabitModel({
    required String id,
    required String name,
    required List<int> targetDays,
    String? category,
    @Default(0) int streak,
    @Default({}) Map<DateTime, int> heatmapData,
  }) = _HabitModel;

  factory HabitModel.fromJson(Map<String, dynamic> json) => _$HabitModelFromJson(json);
}
