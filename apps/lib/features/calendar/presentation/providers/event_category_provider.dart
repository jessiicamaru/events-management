import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/calendar/models/event_category.dart';

part 'event_category_provider.g.dart';

@riverpod
class EventCategoriesNotifier extends _$EventCategoriesNotifier {
  @override
  Future<List<EventCategory>> build({String? squadId}) async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.fetchEventCategories(squadId: squadId);
  }

  Future<void> addCategory(String name, String colorPreset) async {
    final apiService = ref.read(apiServiceProvider);
    
    final newCategory = EventCategory(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID until backend responds
      name: name,
      colorPreset: colorPreset,
      squadId: squadId,
    );

    final previousState = state;
    if (state.hasValue) {
      state = AsyncData([...state.value!, newCategory]);
    }

    try {
      await apiService.createEventCategory(newCategory);
      ref.invalidateSelf();
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> updateCategory(EventCategory category) async {
    final apiService = ref.read(apiServiceProvider);
    
    final previousState = state;
    if (state.hasValue) {
      final updatedCategories = state.value!.map((c) {
        if (c.id == category.id) return category;
        return c;
      }).toList();
      state = AsyncData(updatedCategories);
    }

    try {
      await apiService.updateEventCategory(category);
      ref.invalidateSelf();
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> deleteCategory(String id, {String? replacementCategoryId}) async {
    final apiService = ref.read(apiServiceProvider);
    
    final previousState = state;
    if (state.hasValue) {
      final updatedCategories = state.value!.where((c) => c.id != id).toList();
      state = AsyncData(updatedCategories);
    }

    try {
      await apiService.deleteEventCategory(id, replacementCategoryId: replacementCategoryId);
      ref.invalidateSelf();
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }
}
