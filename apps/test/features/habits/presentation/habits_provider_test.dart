import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/habits/presentation/habits_provider.dart';

class MockApiService implements ApiService {
  List<HabitModel> habitsToReturn = [];
  bool syncHabitCalled = false;
  bool updateHabitCalled = false;
  bool deleteHabitCalled = false;

  @override
  Future<List<HabitModel>> fetchHabits() async => habitsToReturn;

  @override
  Future<void> syncHabit(HabitModel habit) async {
    syncHabitCalled = true;
  }

  @override
  Future<void> updateHabit(HabitModel habit) async {
    updateHabitCalled = true;
  }

  @override
  Future<void> deleteHabit(String id) async {
    deleteHabitCalled = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProviderContainer container;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(mockApiService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('HabitsNotifier fetches initial data', () async {
    final mockHabits = [const HabitModel(id: '1', name: 'Test Habit', targetDays: [1, 2])];
    mockApiService.habitsToReturn = mockHabits;

    final habits = await container.read(habitsProvider.future);

    expect(habits, mockHabits);
  });

  test('HabitsNotifier adds habit optimistically and calls api', () async {
    final mockHabits = [const HabitModel(id: '1', name: 'Test Habit', targetDays: [1, 2])];
    mockApiService.habitsToReturn = mockHabits;

    await container.read(habitsProvider.future);

    final newHabit = const HabitModel(id: '2', name: 'New Habit', targetDays: [1]);

    await container.read(habitsProvider.notifier).addHabit(newHabit);

    // Verify it called API
    expect(mockApiService.syncHabitCalled, true);
  });

  test('HabitsNotifier edits habit optimistically and calls api', () async {
    final mockHabits = [const HabitModel(id: '1', name: 'Test Habit', targetDays: [1, 2])];
    mockApiService.habitsToReturn = mockHabits;

    await container.read(habitsProvider.future);

    final updatedHabit = const HabitModel(id: '1', name: 'Updated Habit', targetDays: [1, 2, 3]);

    await container.read(habitsProvider.notifier).editHabit(updatedHabit);

    expect(mockApiService.updateHabitCalled, true);
  });

  test('HabitsNotifier deletes habit optimistically and calls api', () async {
    final mockHabits = [const HabitModel(id: '1', name: 'Test Habit', targetDays: [1, 2])];
    mockApiService.habitsToReturn = mockHabits;

    await container.read(habitsProvider.future);

    await container.read(habitsProvider.notifier).deleteHabit('1');

    expect(mockApiService.deleteHabitCalled, true);
  });
}
