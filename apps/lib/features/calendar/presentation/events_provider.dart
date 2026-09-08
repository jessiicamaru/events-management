import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';

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
}
