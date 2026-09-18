import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/main.dart' as app;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E: Drag and Drop Habit to Calendar', (tester) async {
    // Clear state before test
    const secureStorage = FlutterSecureStorage();
    await secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    app.main();
    await tester.pumpAndSettle();

    // Generate a random email
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'user_$timestamp@test.com';
    final testPassword = 'Password123!';

    // --- 1. AUTHENTICATION ---
    expect(find.text('Create an account'), findsOneWidget);
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(ShadInput).at(0), testEmail);
    await tester.enterText(find.byType(ShadInput).at(1), testPassword);
    await tester.enterText(find.byType(ShadInput).at(2), testPassword);
    
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.enterText(find.byType(ShadInput).at(0), testEmail);
    await tester.enterText(find.byType(ShadInput).at(1), testPassword);
    
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // --- 1.5 CREATE HABIT ---
    // Navigate to Habits tab (index 1)
    await tester.tap(find.text('Habits'));
    await tester.pumpAndSettle();

    // Tap Fab to create habit
    expect(find.byIcon(LucideIcons.plus), findsOneWidget);
    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();

    // Enter habit details
    await tester.enterText(find.byType(ShadInput).first, 'Read E2E Test Book');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Navigate back to Calendar tab (index 0)
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    // --- 2. DRAG AND DROP FLOW ---
    // Wait for the calendar to render and fetch default habits
    expect(find.byType(SfCalendar), findsOneWidget);
    
    // Check if HabitDock is rendered (it should show 'Drag habits to calendar')
    expect(find.text('Drag habits to calendar'), findsOneWidget);

    // Find the first Draggable habit in the dock
    final firstHabitFinder = find.byType(Draggable<HabitModel>).first;
    expect(firstHabitFinder, findsOneWidget);

    // Perform drag from the dock to the center of the calendar
    final centerOfCalendar = tester.getCenter(find.byType(SfCalendar));
    await tester.drag(firstHabitFinder, Offset(0, -300)); // Drag upwards to the calendar
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // After dropping, CreateEventSheet should appear
    expect(find.text('Schedule Event'), findsOneWidget);
    
    // The title field should be pre-filled. We can check if any input has text.
    // We'll just verify the CreateEventSheet rendered successfully and the submit button is there
    expect(find.text('Create Event'), findsOneWidget);

    // Close the sheet
    await tester.tap(find.byIcon(LucideIcons.x).first);
    await tester.pumpAndSettle();

    // Verify it closed
    expect(find.text('Schedule Event'), findsNothing);
  });
}
