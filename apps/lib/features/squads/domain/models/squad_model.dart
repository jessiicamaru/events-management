import 'package:freezed_annotation/freezed_annotation.dart';

part 'squad_model.freezed.dart';
part 'squad_model.g.dart';

@freezed
abstract class SquadModel with _$SquadModel {
  const factory SquadModel({
    required String id,
    required String name,
    required int maxMembers,
    required bool requireApproval,
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
    @Default(0) int currentStreak,
    @Default([]) List<String> unlockedEmojis,
    String? avatarBorderColor,
    String? nickname,
    required bool isMuted,
    required bool xpContributionEnabled,
    required bool isApproved,
  }) = _SquadMemberModel;

  factory SquadMemberModel.fromJson(Map<String, dynamic> json) => _$SquadMemberModelFromJson(json);
}

@freezed
abstract class MySquadSummaryModel with _$MySquadSummaryModel {
  const factory MySquadSummaryModel({
    required String id,
    required String name,
    required int memberCount,
    required int maxMembers,
    required int totalSquadXP,
  }) = _MySquadSummaryModel;

  factory MySquadSummaryModel.fromJson(Map<String, dynamic> json) => _$MySquadSummaryModelFromJson(json);
}

@freezed
abstract class SquadChatMessageModel with _$SquadChatMessageModel {
  const factory SquadChatMessageModel({
    required String id,
    required String squadId,
    String? senderUserId,
    required String senderDisplayName,
    required String message,
    required DateTime sentAt,
    required bool isSystemMessage,
  }) = _SquadChatMessageModel;

  factory SquadChatMessageModel.fromJson(Map<String, dynamic> json) => _$SquadChatMessageModelFromJson(json);
}
