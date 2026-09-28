import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/squads/domain/models/squad_model.dart';
import 'package:habit_tracker/features/auth/presentation/providers/auth_provider.dart';

// List of all squads the user belongs to
final squadsListProvider = AsyncNotifierProvider<SquadsListNotifier, List<MySquadSummaryModel>>(() => SquadsListNotifier());

class SquadsListNotifier extends AsyncNotifier<List<MySquadSummaryModel>> {
  @override
  Future<List<MySquadSummaryModel>> build() async {
    final authState = ref.watch(authProvider);
    final token = authState.value;
    if (token == null) {
      if (authState.isLoading) {
        return Completer<List<MySquadSummaryModel>>().future;
      }
      return [];
    }
    return _fetchList();
  }

  Future<List<MySquadSummaryModel>> _fetchList() async {
    final api = ref.read(apiServiceProvider);
    return await api.fetchMySquads();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchList());
  }
}

// Active/Selected Squad ID
class ActiveSquadIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(authProvider);
    return null;
  }

  @override
  set state(String? val) => super.state = val;
}

final activeSquadIdProvider = NotifierProvider<ActiveSquadIdNotifier, String?>(() => ActiveSquadIdNotifier());

// Details of the currently selected active squad
final activeSquadProvider = AsyncNotifierProvider<ActiveSquadNotifier, SquadModel?>(() => ActiveSquadNotifier());

class ActiveSquadNotifier extends AsyncNotifier<SquadModel?> {
  @override
  Future<SquadModel?> build() async {
    final authState = ref.watch(authProvider);
    final token = authState.value;
    if (token == null) {
      if (authState.isLoading) {
        return Completer<SquadModel?>().future;
      }
      return null;
    }

    final activeId = ref.watch(activeSquadIdProvider);
    if (activeId == null) {
      // Default to the first squad in the user's list if available
      final squadsList = ref.watch(squadsListProvider);
      return squadsList.when(
        data: (list) {
          if (list.isNotEmpty) {
            // Delay to avoid modifying state during build
            Future.microtask(() {
              ref.read(activeSquadIdProvider.notifier).state = list.first.id;
            });
          }
          return null;
        },
        loading: () => null,
        error: (err, stack) => null,
      );
    }
    return _fetchDetails(activeId);
  }

  Future<SquadModel?> _fetchDetails(String squadId) async {
    final api = ref.read(apiServiceProvider);
    return await api.fetchSquadDetails(squadId);
  }

  Future<void> createSquad(String name, int maxMembers, bool requireApproval) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiServiceProvider);
      final newSquad = await api.createSquad(name, maxMembers, requireApproval);
      
      // Refresh the list of squads
      await ref.read(squadsListProvider.notifier).refresh();
      
      // Set the newly created squad as active
      ref.read(activeSquadIdProvider.notifier).state = newSquad.id;
      
      return newSquad;
    });
  }

  Future<bool> joinSquad(String squadId) async {
    state = const AsyncValue.loading();
    bool isApproved = false;
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiServiceProvider);
      isApproved = await api.joinSquad(squadId);
      
      // Refresh squad list
      await ref.read(squadsListProvider.notifier).refresh();
      
      if (isApproved) {
        ref.read(activeSquadIdProvider.notifier).state = squadId;
        return _fetchDetails(squadId);
      } else {
        return null; // is pending approval
      }
    });
    return isApproved;
  }

  Future<void> leaveSquad(String squadId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiServiceProvider);
      await api.leaveSquad(squadId);
      
      await ref.read(squadsListProvider.notifier).refresh();
      ref.read(activeSquadIdProvider.notifier).state = null;
      return null;
    });
  }

  Future<void> approveMember(String squadId, String targetUserId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiServiceProvider);
      await api.approveMember(squadId, targetUserId);
      return _fetchDetails(squadId);
    });
  }

  Future<void> rejectMember(String squadId, String targetUserId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiServiceProvider);
      await api.rejectMember(squadId, targetUserId);
      return _fetchDetails(squadId);
    });
  }

  Future<void> updateSquadSettings(String squadId, String name, int maxMembers, bool requireApproval) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiServiceProvider);
      await api.updateSquadSettings(squadId, name, maxMembers, requireApproval);
      await ref.read(squadsListProvider.notifier).refresh();
      return _fetchDetails(squadId);
    });
  }

  Future<void> changeLeader(String squadId, String targetUserId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiServiceProvider);
      await api.changeLeader(squadId, targetUserId);
      return _fetchDetails(squadId);
    });
  }

  Future<void> updateMemberSettings(String squadId, {String? nickname, required bool isMuted, required bool xpContributionEnabled}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiServiceProvider);
      await api.updateMemberSettings(squadId, nickname: nickname, isMuted: isMuted, xpContributionEnabled: xpContributionEnabled);
      return _fetchDetails(squadId);
    });
  }

  Future<void> changeMemberNickname(String squadId, String targetUserId, String newNickname) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiServiceProvider);
      await api.changeMemberNickname(squadId, targetUserId, newNickname);
      return _fetchDetails(squadId);
    });
  }
}

// Redirect provider for backward compatibility
final squadProvider = Provider<AsyncValue<SquadModel?>>((ref) {
  return ref.watch(activeSquadProvider);
});
