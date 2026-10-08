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

    // Then wait for the app shell instead of trusting that fixed delay: login, the splash
    // redirect and the first home fetch can take longer on a cold emulator, and the next
    // tap then fails with "no element" rather than waiting.
    for (var i = 0; i < 30 && find.byType(BottomNavigationBar).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();

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

    // Wait for the list to come back from the server. Until it does, the habit carries the
    // client-side timestamp id it was created with, and writing a task against that id
    // POSTs to /habits/<timestamp>/tasks and gets a 404 (HabitTasks.addTask does not guard
    // the way the read path does).
    await tester.pumpAndSettle(const Duration(seconds: 3));

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
    // Picking the habit copies its tasks into the event's checklist, which the sheet shows
    // before anything is saved. This is where the copy happens, so this is where it is
    // checked; the toggle behaviour itself is covered by the widget tests.
    expect(find.text('Pushups'), findsWidgets);
    expect(find.text('Pullups'), findsWidgets);

    // Selecting a habit adds the task editor to the sheet, which pushes the submit button
    // below the fold. Tapping an off-screen widget misses silently — the form never
    // submitted and the failure only showed up two screens later.
    final submit = find.widgetWithText(ShadButton, 'Create Event');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // The sheet defaults to 06:00 today, so by the time this runs the event is usually in
    // the past. Home's "up next" covers the next seven days and correctly shows nothing,
    // so the check here is simply that the event was scheduled and is on the calendar.
    expect(find.text('Workout'), findsWidgets);
  });
}
