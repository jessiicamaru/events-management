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
      ref.invalidate(habitsProvider);
      ref.invalidate(heatmapProvider);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> deleteEvent(String id) async {
    final apiService = ref.read(apiServiceProvider);
    
    final previousState = state;
    if (state.hasValue) {
      final updatedEvents = state.value!.where((e) => e.id != id).toList();
      state = AsyncData(updatedEvents);
    }

    try {
      await apiService.deleteEvent(id);
      ref.invalidate(habitsProvider);
      ref.invalidate(heatmapProvider);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> updateEvent(EventModel event) async {
    final apiService = ref.read(apiServiceProvider);
    
    final previousState = state;
    if (state.hasValue) {
      final updatedEvents = state.value!.map((e) {
        if (e.id == event.id) return event;
        return e;
      }).toList();
      state = AsyncData(updatedEvents);
    }

    try {
      await apiService.updateEvent(event.id, {
        'title': event.title,
        'startTime': event.startTime.toUtc().toIso8601String(),
        'endTime': event.endTime.toUtc().toIso8601String(),
        'habitId': event.habitId,
        'targetDuration': const TimeSpanConverter().toJson(event.targetDuration),
      });
      ref.invalidate(habitsProvider);
      ref.invalidate(heatmapProvider);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }
}
