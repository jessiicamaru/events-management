import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_category.freezed.dart';
part 'event_category.g.dart';

@freezed
abstract class EventCategory with _$EventCategory {
  const EventCategory._();

  const factory EventCategory({
    required String id,
    required String name,
    required String colorPreset,
    String? userId,
    String? squadId,
    DateTime? createdAt,
  }) = _EventCategory;

  factory EventCategory.fromJson(Map<String, dynamic> json) =>
      _$EventCategoryFromJson(json);
}
