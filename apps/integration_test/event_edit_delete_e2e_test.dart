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

  testWidgets('E2E: Create, Edit, and Delete an Event', (tester) async {
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
    await tester.tap(find.text('Habits'));
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.plus), findsOneWidget);
    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(ShadInput).first, 'Test Edit Delete');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Navigate back to Calendar
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    // --- 2. CREATE EVENT VIA DRAG ---
    expect(find.byType(SfCalendar), findsOneWidget);
    final firstHabitFinder = find.byType(Draggable<HabitModel>).first;
    expect(firstHabitFinder, findsOneWidget);

    await tester.drag(firstHabitFinder, const Offset(0, -300)); 
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Schedule Event'), findsOneWidget);
    
    // Tap "Create Event" to save it
    await tester.tap(find.text('Create Event'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify it appeared on the calendar
    expect(find.text('Test Edit Delete'), findsWidgets); // Dock has it, and calendar has it

    // --- 3. EDIT EVENT ---
    // Tap the event on the calendar (we assume it's the second occurrence of the text, or we can just tap the calendar event specifically)
    // SfCalendar renders appointments inside a custom painter in some views, but we use an appointmentBuilder!
    // Since we use appointmentBuilder, our text should be a widget on screen.
    final eventWidget = find.text('Test Edit Delete').last;
    await tester.tap(eventWidget);
    await tester.pumpAndSettle();

    // Dialog should appear
    expect(find.text('Event Details'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);

    // Tap Edit
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    // Sheet should appear
    expect(find.text('Update Event'), findsOneWidget);
    
    // Change title
    await tester.enterText(find.byType(ShadInput).first, 'Updated Event Name');
    
    // Tap Update
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify update
    expect(find.text('Updated Event Name'), findsOneWidget);

    // --- 4. DELETE EVENT ---
    await tester.tap(find.text('Updated Event Name'));
    await tester.pumpAndSettle();

    expect(find.text('Event Details'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Confirmation dialog
    expect(find.text('Delete Event'), findsOneWidget);
    expect(find.text('Are you sure you want to delete this event?'), findsOneWidget);

    // Confirm delete (second Delete button in the dialog)
    // We can use find.byType(ShadButton.destructive).last
    final confirmDeleteButton = find.text('Delete').last;
    await tester.tap(confirmDeleteButton);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify it's deleted
    expect(find.text('Updated Event Name'), findsNothing);
  });
}
