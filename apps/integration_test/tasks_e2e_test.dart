import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/main.dart' as app;
import 'package:habit_tracker/features/calendar/presentation/widgets/unscheduled_habits_selector.dart';
/// One tab of the bottom bar, by its icon.
///
/// Scoped to the [BottomNavigationBar] because some of these icons appear in the
/// screens too — `calendarDays` is also the calendar toolbar's month-view button.
Finder navTab(IconData icon) => find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.byIcon(icon),
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E: habit tasks reach the home screen up-next card', (tester) async {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    app.main();
    await tester.pumpAndSettle();

    // Generate a random email
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'user_$timestamp@test.com';
    final testPassword = 'Password123!';

    // Register
    expect(find.text('Create an account'), findsOneWidget);
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    
    await tester.enterText(find.byType(ShadInput).at(0), testEmail);
    await tester.enterText(find.byType(ShadInput).at(1), testPassword);
    await tester.enterText(find.byType(ShadInput).at(2), testPassword);
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Login
    expect(find.text('Welcome Back'), findsOneWidget);
    await tester.enterText(find.byType(ShadInput).at(0), testEmail);
    await tester.enterText(find.byType(ShadInput).at(1), testPassword);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // We land on Home. Go to Habits to create a habit.
    //
    // Found by icon rather than by position: tab order has changed once already
    // (Home was added in front of Calendar), and a positional finder fails
    // silently by tapping the wrong tab instead of reporting a missing one.
    await tester.tap(navTab(LucideIcons.listTodo));
    await tester.pumpAndSettle();

    // Open create habit dialog
    await tester.tap(find.byIcon(LucideIcons.plus).first); 
    await tester.pumpAndSettle();

    // Fill habit name
    await tester.enterText(find.byType(ShadInput).first, 'Workout');
    // Save habit (Button text is 'Add' for new habit)
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // After creating a habit, the Habit Tasks Editor is available on Edit mode.
    // Let's edit the habit we just created.
    await tester.tap(find.byIcon(LucideIcons.pencil).first);
    await tester.pumpAndSettle();

    // Find the Add Task button in the HabitTasksEditor
    final addTaskButton = find.text('Add Task');
    expect(addTaskButton, findsOneWidget);
    await tester.tap(addTaskButton);
    await tester.pumpAndSettle();

    // In the task dialog, enter task details
    await tester.enterText(find.byType(ShadInput).at(1), 'Pushups');
    await tester.enterText(find.byType(ShadInput).at(2), 'Do 50 pushups');
    await tester.enterText(find.byType(ShadInput).at(3), '10'); // est minutes
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Add another task
    await tester.tap(addTaskButton);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(ShadInput).at(1), 'Pullups');
    await tester.enterText(find.byType(ShadInput).at(3), '15'); // est minutes
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify tasks are listed
    expect(find.text('Pushups'), findsOneWidget);
    expect(find.text('Pullups'), findsOneWidget);

    // Save habit
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
    // ShadToast appears after saving - must advance time for it to auto-dismiss
    // before trying to tap the BottomNavigationBar (toast blocks the nav bar)
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // We are on Habits screen after saving the habit. Go to Calendar.
    await tester.tap(navTab(LucideIcons.calendarDays));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Since the Calendar view is complex for drag and drop in testing, 
    // we just use the manual add button to schedule it for today
    await tester.tap(find.byIcon(LucideIcons.plus).last);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Select the "Workout" habit in the UnscheduledHabitsSelector
    final habitSelector = find.byType(UnscheduledHabitsSelector);
    expect(habitSelector, findsOneWidget);
    await tester.tap(find.descendant(of: habitSelector, matching: find.text('Workout')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.widgetWithText(ShadButton, 'Create Event'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // The up-next card now lives on Home, not under the calendar grid.
    await tester.tap(navTab(LucideIcons.house));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Either label is correct depending on whether the event has already started:
    // it is created for the current time, so the card may well say "happening now".
    expect(
      find.text('Up Next').evaluate().isNotEmpty ||
          find.text('Happening now').evaluate().isNotEmpty,
      isTrue,
      reason: 'the home screen should surface the event that was just created',
    );
    expect(find.text('Workout'), findsWidgets);

    // Verify the tasks were copied over in the checklist
    expect(find.text('Pushups'), findsOneWidget);
    expect(find.text('Pullups'), findsOneWidget);

    // Toggle a task in the checklist
    final checkbox = find.byType(ShadCheckbox).first;
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    // Verify it updates correctly
    // The visual check is hard in E2E, but we can tap to ensure it works
    expect(find.text('1/2'), findsOneWidget); // Progress should be updated
  });
}
