import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_model.freezed.dart';
part 'event_model.g.dart';

class TimeSpanConverter implements JsonConverter<int?, String?> {
  const TimeSpanConverter();

  @override
  int? fromJson(String? json) {
    if (json == null || json.isEmpty) return null;
    final parts = json.split(':');
    if (parts.length >= 2) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      return hours * 60 + minutes;
    }
    return null;
  }

  @override
  String? toJson(int? object) {
    if (object == null) return null;
    final hours = object ~/ 60;
    final minutes = object % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:00';
  }
}

@freezed
abstract class EventModel with _$EventModel {
  const factory EventModel({
    required String id,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String habitId,
    @Default(false) bool isCompleted,
    @TimeSpanConverter() int? targetDuration, // Target duration in minutes
    @TimeSpanConverter() int? actualDuration, // Actual duration in minutes
    DateTime? createdAt,
  }) = _EventModel;

  factory EventModel.fromJson(Map<String, dynamic> json) => _$EventModelFromJson(json);
}
