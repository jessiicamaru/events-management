import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/core/providers/shared_preferences_provider.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/habits/presentation/habits_screen.dart';

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
  late MockApiService mockApiService;
  late SharedPreferences prefs;

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        apiServiceProvider.overrideWithValue(mockApiService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: ShadApp(
        home: child,
      ),
    );
  }

  setUp(() async {
    mockApiService = MockApiService();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('HabitsScreen renders habits list, opens Edit dialog and updates', (WidgetTester tester) async {
    final mockHabits = [
      const HabitModel(
        id: '1',
        name: 'Morning Run',
        category: 'Health',
        targetDays: [1, 2, 3],
      ),
    ];
    mockApiService.habitsToReturn = mockHabits;

    await tester.pumpWidget(buildTestableWidget(const HabitsScreen()));
    await tester.pumpAndSettle();

    // Verify habit renders
    expect(find.text('Morning Run'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);

    // Find pencil icon button and tap it
    final editButton = find.byIcon(LucideIcons.pencil);
    expect(editButton, findsOneWidget);
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    // Verify Edit Dialog is shown
    expect(find.text('Edit Habit'), findsOneWidget);

    // Edit Name
    await tester.enterText(find.byType(ShadInput), 'Morning Run Expanded');
    await tester.pumpAndSettle();

    // Save changes
    final saveButton = find.widgetWithText(ShadButton, 'Save');
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify updateHabit was called
    expect(mockApiService.updateHabitCalled, isTrue);
  });

  testWidgets('HabitsScreen deletes habit from Edit dialog', (WidgetTester tester) async {
    final mockHabits = [
      const HabitModel(
        id: '1',
        name: 'Morning Run',
        category: 'Health',
        targetDays: [1, 2, 3],
      ),
    ];
    mockApiService.habitsToReturn = mockHabits;

    await tester.pumpWidget(buildTestableWidget(const HabitsScreen()));
    await tester.pumpAndSettle();

    // Tap edit button to open dialog
    await tester.tap(find.byIcon(LucideIcons.pencil));
    await tester.pumpAndSettle();

    // Tap Delete button inside dialog
    final deleteButton = find.widgetWithText(ShadButton, 'Delete');
    expect(deleteButton, findsOneWidget);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Verify delete confirmation dialog is shown
    expect(find.text('Are you sure you want to delete this habit?'), findsOneWidget);

    // Tap confirm delete
    final confirmDeleteButton = find.widgetWithText(ShadButton, 'Delete');
    await tester.tap(confirmDeleteButton);
    await tester.pumpAndSettle();

    // Verify deleteHabit was called
    expect(mockApiService.deleteHabitCalled, isTrue);
  });
}
