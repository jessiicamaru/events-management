import '../../../../core/network/api_service.dart';
import '../../domain/models/event_task_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_tasks_provider.g.dart';

@riverpod
class EventTasks extends _$EventTasks {
  @override
  Future<List<EventTaskModel>> build(String eventId) async {
    final api = ref.watch(apiServiceProvider);
    return await api.fetchEventTasks(eventId);
  }

  Future<void> addTask(EventTaskModel task) async {
    final api = ref.read(apiServiceProvider);
    await api.createEventTask(eventId, task);
    ref.invalidateSelf();
  }

  Future<void> updateTask(EventTaskModel task) async {
    final api = ref.read(apiServiceProvider);
    await api.updateEventTask(eventId, task);
    ref.invalidateSelf();
  }

  Future<void> deleteTask(String taskId) async {
    final api = ref.read(apiServiceProvider);
    await api.deleteEventTask(eventId, taskId);
    ref.invalidateSelf();
  }

  Future<void> toggleTask(String taskId, bool isCompleted) async {
    // Optimistic update
    final currentTasks = state.value;
    if (currentTasks != null) {
      final updatedTasks = currentTasks.map((t) {
        if (t.id == taskId) {
          return t.copyWith(isCompleted: isCompleted);
        }
        return t;
      }).toList();
      state = AsyncData(updatedTasks);
    }

    final api = ref.read(apiServiceProvider);
    try {
      await api.toggleEventTask(eventId, taskId, isCompleted);
    } catch (e) {
      ref.invalidateSelf();
    }
  }

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    final currentTasks = state.value;
    if (currentTasks == null) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final newTasks = List<EventTaskModel>.from(currentTasks);
    final task = newTasks.removeAt(oldIndex);
    newTasks.insert(newIndex, task);

    // Optimistic update
    final updatedTasks = <EventTaskModel>[];
    for (int i = 0; i < newTasks.length; i++) {
      updatedTasks.add(newTasks[i].copyWith(order: i));
    }
    state = AsyncData(updatedTasks);

    final api = ref.read(apiServiceProvider);
    try {
      await Future.wait(
        updatedTasks.map((t) => api.updateEventTask(eventId, t))
      );
    } catch (e) {
      ref.invalidateSelf();
    }
  }
}
