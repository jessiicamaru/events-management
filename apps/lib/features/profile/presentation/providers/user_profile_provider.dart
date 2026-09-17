import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/profile/domain/models/user_profile_model.dart';

final userProfileProvider = AsyncNotifierProvider<UserProfileNotifier, UserProfileModel>(() => UserProfileNotifier());

class UserProfileNotifier extends AsyncNotifier<UserProfileModel> {
  @override
  Future<UserProfileModel> build() async {
    return _fetchProfile();
  }

  Future<UserProfileModel> _fetchProfile() async {
    final api = ref.read(apiServiceProvider);
    return await api.fetchMe();
  }

  Future<void> updateCosmetics({List<String>? unlockedEmojis, String? avatarBorderColor}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiServiceProvider);
      await api.updateCosmetics(unlockedEmojis: unlockedEmojis, avatarBorderColor: avatarBorderColor);
      return _fetchProfile();
    });
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    DateTime? dateOfBirth,
    String? gender,
    String? phoneNumber,
    String? avatar,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiServiceProvider);
      await api.updateProfile(
        displayName: displayName,
        bio: bio,
        dateOfBirth: dateOfBirth,
        gender: gender,
        phoneNumber: phoneNumber,
        avatar: avatar,
      );
      return _fetchProfile();
    });
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final api = ref.read(apiServiceProvider);
    await api.changePassword(currentPassword, newPassword);
  }
}
