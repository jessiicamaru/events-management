import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/habits/presentation/habits_provider.dart';
import 'package:habit_tracker/features/habits/presentation/providers/heatmap_provider.dart';

part 'events_provider.g.dart';

@riverpod
class EventsNotifier extends _$EventsNotifier {
  @override
  Future<List<EventModel>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.fetchEvents();
  }

  Future<void> addEvent(EventModel event) async {
    final apiService = ref.read(apiServiceProvider);
    
    final previousState = state;
    if (state.hasValue) {
      state = AsyncData([...state.value!, event]);
    }

    try {
      await apiService.syncEvent(event);
      ref.invalidateSelf();
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> toggleEvent(String id, bool isCompleted) async {
    final apiService = ref.read(apiServiceProvider);
    
    // Optimistic update
    final previousState = state;
    if (state.hasValue) {
      final updatedEvents = state.value!.map((e) {
        if (e.id == id) {
          return e.copyWith(isCompleted: isCompleted);
        }
        return e;
      }).toList();
      state = AsyncData(updatedEvents);
    }

    try {
      await apiService.toggleEvent(id, isCompleted);
      // Invalidate to refresh streaks and heatmap
      ref.invalidate(habitsProvider);
      ref.invalidate(heatmapProvider);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }
}
