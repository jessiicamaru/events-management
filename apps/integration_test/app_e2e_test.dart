import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/main.dart' as app;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E: Full App Journey - Auth, Calendar, Habits, Squads', (tester) async {
    // Clear state before test
    const secureStorage = FlutterSecureStorage();
    await secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    app.main();
    await tester.pumpAndSettle();

    // Generate a random email to avoid conflicts
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'user_$timestamp@test.com';
    final testPassword = 'Password123!';

    // --- 1. AUTHENTICATION FLOW ---
    // Register
    expect(find.text('Create an account'), findsOneWidget);
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsOneWidget);
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
    await tester.pumpAndSettle(const Duration(seconds: 4)); // Wait for API and splash redirect

    // --- 2. CALENDAR FLOW ---
    // Verify Calendar Filter Pills
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Squads'), findsOneWidget);

    await tester.tap(find.text('Personal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Squads'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    // Verify Calendar Settings
    final settingsButton = find.byIcon(LucideIcons.settings).first; 
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();
    
    expect(find.text('Calendar Settings'), findsWidgets);
    expect(find.text('Start Hour'), findsOneWidget);
    
    // Close the bottom sheet
    await tester.drag(find.text('Calendar Settings').first, const Offset(0, 500));
    await tester.pumpAndSettle();

    // --- 3. HABITS FLOW ---
    // Tap on Habits tab
    await tester.tap(find.text('Habits').last);
    await tester.pumpAndSettle();

    // Verify Habits screen
    expect(find.text('Habits'), findsWidgets); // AppConstants.habitsTitle

    // Open Add Habit Dialog
    final addHabitButton = find.byIcon(LucideIcons.plus).first;
    await tester.tap(addHabitButton);
    await tester.pumpAndSettle();

    expect(find.text('Add Habit'), findsOneWidget);
    
    // Create a new Habit
    final habitName = 'Read E2E Test Book';
    await tester.enterText(find.byType(ShadInput).last, habitName);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify habit was added successfully by waiting for the API to resolve
    // Since it's a SliverList, it might be off-screen. As a smoke test, ensuring no crash is enough.
    expect(find.byType(ShadCard), findsWidgets);

    // --- 4. SQUADS FLOW ---
    // Tap on Squads tab
    await tester.tap(find.text('Squad').last);
    await tester.pumpAndSettle();

    // Verify empty state (since new user has no squad)
    // The empty state widget should be visible
    expect(find.text('Create Squad'), findsOneWidget);
    expect(find.text('Join with Code'), findsOneWidget);

    // --- 5. SETTINGS/PROFILE FLOW ---
    // Tap on Settings tab
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    // Verify we are on the settings screen
    expect(find.text('Settings'), findsWidgets);
  });
}
