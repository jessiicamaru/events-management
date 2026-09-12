import 'package:freezed_annotation/freezed_annotation.dart';

part 'squad_model.freezed.dart';
part 'squad_model.g.dart';

@freezed
abstract class SquadModel with _$SquadModel {
  const factory SquadModel({
    required String id,
    required String name,
    required bool isBuddyMode,
    required int totalSquadXP,
    @Default([]) List<SquadMemberModel> members,
  }) = _SquadModel;

  factory SquadModel.fromJson(Map<String, dynamic> json) => _$SquadModelFromJson(json);
}

@freezed
abstract class SquadMemberModel with _$SquadMemberModel {
  const factory SquadMemberModel({
    required String userId,
    required String role,
    required String email,
    required int totalXP,
    @Default([]) List<String> unlockedEmojis,
    String? avatarBorderColor,
  }) = _SquadMemberModel;

  factory SquadMemberModel.fromJson(Map<String, dynamic> json) => _$SquadMemberModelFromJson(json);
}
