import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/features/pomodoro/presentation/pomodoro_screen.dart';

void main() {
  testWidgets('PomodoroScreen displays initial timer and status', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PomodoroScreen(),
        ),
      ),
    );

    // Initial state check
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Status: INITIAL'), findsOneWidget);
    
    // Start button should be visible
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Pause'), findsNothing);
  });

  testWidgets('PomodoroScreen changes to running status when started', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PomodoroScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Start'));
    await tester.pump(); // trigger rebuild

    expect(find.text('Status: RUNNING'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Start'), findsNothing);
  });
}
