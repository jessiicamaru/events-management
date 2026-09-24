import '../../../../core/network/api_service.dart';
import '../../domain/models/habit_task_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'habit_tasks_provider.g.dart';

@riverpod
class HabitTasks extends _$HabitTasks {
  @override
  Future<List<HabitTaskModel>> build(String habitId) async {
    final api = ref.watch(apiServiceProvider);
    return await api.fetchHabitTasks(habitId);
  }

  Future<void> addTask(HabitTaskModel task) async {
    final api = ref.read(apiServiceProvider);
    await api.createHabitTask(habitId, task);
    ref.invalidateSelf();
  }

  Future<void> updateTask(HabitTaskModel task) async {
    final api = ref.read(apiServiceProvider);
    await api.updateHabitTask(habitId, task);
    ref.invalidateSelf();
  }

  Future<void> deleteTask(String taskId) async {
    final api = ref.read(apiServiceProvider);
    await api.deleteHabitTask(habitId, taskId);
    ref.invalidateSelf();
  }

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    final currentTasks = state.value;
    if (currentTasks == null) return;

    final tasksList = List<HabitTaskModel>.from(currentTasks);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = tasksList.removeAt(oldIndex);
    tasksList.insert(newIndex, item);

    // Optimistically update UI
    state = AsyncData(tasksList);

    final api = ref.read(apiServiceProvider);
    final orders = tasksList.asMap().entries.map((e) => {
      'id': e.value.id,
      'order': e.key
    }).toList();

    try {
      await api.reorderHabitTasks(habitId, orders);
      ref.invalidateSelf();
    } catch (e) {
      // Revert if failed
      ref.invalidateSelf();
    }
  }
}
