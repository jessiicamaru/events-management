import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';

part 'habits_provider.g.dart';

@riverpod
class HabitsNotifier extends _$HabitsNotifier {
  @override
  Future<List<HabitModel>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.fetchHabits();
  }

  Future<void> addHabit(HabitModel habit) async {
    final apiService = ref.read(apiServiceProvider);
    
    // Optimistic update
    final previousState = state;
    if (state.hasValue) {
      state = AsyncData([...state.value!, habit]);
    }

    try {
      await apiService.syncHabit(habit);
      // Re-fetch to get the assigned ID/Category from backend
      ref.invalidateSelf();
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> editHabit(HabitModel habit) async {
    final apiService = ref.read(apiServiceProvider);
    
    // Optimistic update
    final previousState = state;
    if (state.hasValue) {
      state = AsyncData(state.value!.map((h) => h.id == habit.id ? habit : h).toList());
    }

    try {
      await apiService.updateHabit(habit);
      ref.invalidateSelf();
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> deleteHabit(String habitId) async {
    final apiService = ref.read(apiServiceProvider);
    
    // Optimistic update
    final previousState = state;
    if (state.hasValue) {
      state = AsyncData(state.value!.where((h) => h.id != habitId).toList());
    }

    try {
      await apiService.deleteHabit(habitId);
      ref.invalidateSelf();
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }
}
