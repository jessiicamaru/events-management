import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/habit_dock.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import '../../test_utils.dart';

class MockApiService implements ApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value([]);
}

void main() {
  testWidgets('HabitDock renders draggable habits', (
    WidgetTester tester,
  ) async {
    final habits = [
      HabitModel(
        id: '1',
        name: 'Test Habit 1',
        categoryId: 'cat1',
        targetDays: [1],
      ),
      HabitModel(
        id: '2',
        name: 'Test Habit 2',
        categoryId: 'cat2',
        targetDays: [2],
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...commonTestOverrides,
          apiServiceProvider.overrideWithValue(MockApiService()),
        ],
        child: ShadApp(
          home: Scaffold(body: HabitDock(habits: habits)),
        ),
      ),
    );

    // Verify both habits are rendered
    expect(find.text('Test Habit 1'), findsOneWidget);
    expect(find.text('Test Habit 2'), findsOneWidget);

    // Verify they are Draggable
    expect(find.byType(Draggable<HabitModel>), findsNWidgets(2));
  });

  testWidgets('DragTarget accepts HabitModel', (WidgetTester tester) async {
    HabitModel? droppedHabit;

    final habit = HabitModel(
      id: '1',
      name: 'Test Habit 1',
      categoryId: 'cat1',
      targetDays: [1],
    );

    await tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: DragTarget<HabitModel>(
                  onAcceptWithDetails: (details) {
                    droppedHabit = details.data;
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      color: Colors.blue,
                      child: const Text('Drop Here'),
                    );
                  },
                ),
              ),
              Draggable<HabitModel>(
                data: habit,
                feedback: const Text('Dragging'),
                child: const Text('Drag Me'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Drop Here'), findsOneWidget);
    expect(find.text('Drag Me'), findsOneWidget);

    // Perform Drag
    await tester.drag(find.text('Drag Me'), const Offset(0, -300));
    await tester.pumpAndSettle();

    // Verify Drop
    expect(droppedHabit, isNotNull);
    expect(droppedHabit?.name, 'Test Habit 1');
  });
}
