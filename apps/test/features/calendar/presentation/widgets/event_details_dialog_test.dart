import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/event_details_dialog.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  Widget createWidgetUnderTest(EventModel event, HabitModel habit) {
    return ProviderScope(
      child: ShadApp(
        home: Scaffold(
          body: EventDetailsDialog(
            event: event,
            habit: habit,
          ),
        ),
      ),
    );
  }

  testWidgets('EventDetailsDialog renders correctly for pending event', (WidgetTester tester) async {
    final event = EventModel(
      id: 'event-1',
      title: 'Morning Run',
      startTime: DateTime(2023, 1, 1, 6, 0),
      endTime: DateTime(2023, 1, 1, 7, 0),
      habitId: 'habit-1',
      isCompleted: false,
    );
    
    final habit = HabitModel(
      id: 'habit-1',
      name: 'Running',
      category: 'Health',
      targetDays: [1, 2, 3],
    );

    await tester.pumpWidget(createWidgetUnderTest(event, habit));

    expect(find.text('Morning Run'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Start Focus Session'), findsOneWidget);
  });

  testWidgets('EventDetailsDialog renders correctly for completed event', (WidgetTester tester) async {
    final event = EventModel(
      id: 'event-1',
      title: 'Morning Run',
      startTime: DateTime(2023, 1, 1, 6, 0),
      endTime: DateTime(2023, 1, 1, 7, 0),
      habitId: 'habit-1',
      isCompleted: true,
    );
    
    final habit = HabitModel(
      id: 'habit-1',
      name: 'Running',
      category: 'Health',
      targetDays: [1, 2, 3],
    );

    await tester.pumpWidget(createWidgetUnderTest(event, habit));

    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Mark as Pending'), findsOneWidget);
  });
}
