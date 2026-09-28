import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile_model.freezed.dart';
part 'user_profile_model.g.dart';

@freezed
abstract class UserProfileModel with _$UserProfileModel {
  const factory UserProfileModel({
    required String id,
    required String email,
    required int totalXP,
    @Default(0) int currentStreak,
    @Default([]) List<String> unlockedEmojis,
    String? avatarBorderColor,
    String? displayName,
    String? bio,
    DateTime? dateOfBirth,
    String? gender,
    String? phoneNumber,
    String? avatar,
    String? googleEmail,
  }) = _UserProfileModel;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) => _$UserProfileModelFromJson(json);
}
