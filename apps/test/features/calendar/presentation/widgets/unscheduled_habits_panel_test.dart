import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import '../../../../test_utils.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/unscheduled_habits_panel.dart';
import 'package:habit_tracker/core/network/api_service.dart';

class MockApiService implements ApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value([]);
}

void main() {
  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        ...commonTestOverrides,
        apiServiceProvider.overrideWithValue(MockApiService()),
      ],
      child: ShadApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('UnscheduledHabitsPanel', () {
    testWidgets('shows loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const UnscheduledHabitsPanel(
          habitsAsync: AsyncLoading(),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const UnscheduledHabitsPanel(
          habitsAsync: AsyncData([]),
        ),
      ));

      expect(find.text('No habits yet. Go to Habits tab to create one.'), findsOneWidget);
    });

    testWidgets('shows habits list', (WidgetTester tester) async {
      final habits = [
        HabitModel(id: '1', name: 'Exercise', categoryId: 'cat1', targetDays: []),
        HabitModel(id: '2', name: 'Reading', categoryId: 'cat2', targetDays: []),
      ];

      await tester.pumpWidget(buildTestableWidget(
        UnscheduledHabitsPanel(
          habitsAsync: AsyncData(habits),
        ),
      ));

      expect(find.text('Exercise'), findsOneWidget);
      expect(find.text('Reading'), findsOneWidget);
      expect(find.text('Uncategorized'), findsNWidgets(2));
    });

    testWidgets('triggers onHabitTapped when a habit is tapped', (WidgetTester tester) async {
      final habits = [
        HabitModel(id: '1', name: 'Exercise', categoryId: 'cat1', targetDays: []),
      ];

      HabitModel? tappedHabit;

      await tester.pumpWidget(buildTestableWidget(
        UnscheduledHabitsPanel(
          habitsAsync: AsyncData(habits),
          onHabitTapped: (habit) {
            tappedHabit = habit;
          },
        ),
      ));

      await tester.tap(find.text('Exercise'));
      await tester.pumpAndSettle();

      expect(tappedHabit, isNotNull);
      expect(tappedHabit!.id, equals('1'));
      expect(tappedHabit!.name, equals('Exercise'));
    });
  });
}
