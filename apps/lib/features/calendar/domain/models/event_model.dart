import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_model.freezed.dart';
part 'event_model.g.dart';

@freezed
abstract class EventModel with _$EventModel {
  const factory EventModel({
    required String id,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String habitId,
    @Default(false) bool isCompleted,
    DateTime? createdAt,
  }) = _EventModel;

  factory EventModel.fromJson(Map<String, dynamic> json) => _$EventModelFromJson(json);
}
