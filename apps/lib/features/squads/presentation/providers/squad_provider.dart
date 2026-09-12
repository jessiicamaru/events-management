import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/squads/domain/models/squad_model.dart';

final squadProvider = AsyncNotifierProvider<SquadNotifier, SquadModel?>(() => SquadNotifier());

class SquadNotifier extends AsyncNotifier<SquadModel?> {
  @override
  Future<SquadModel?> build() async {
    return _fetchSquad();
  }

  Future<SquadModel?> _fetchSquad() async {
    final api = ref.read(apiServiceProvider);
    return await api.fetchMySquad();
  }

  Future<void> createSquad(String name, bool isBuddyMode) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiServiceProvider);
      await api.createSquad(name, isBuddyMode);
      return _fetchSquad();
    });
  }

  Future<void> joinSquad(String squadId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiServiceProvider);
      await api.joinSquad(squadId);
      return _fetchSquad();
    });
  }
}
