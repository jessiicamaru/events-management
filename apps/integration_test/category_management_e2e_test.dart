import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/main.dart' as app;
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E: Category Management - Create and Delete', (tester) async {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    app.main();
    await tester.pumpAndSettle();

    // 1. Login flow
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'user_$timestamp@test.com';
    final testPassword = 'Password123!';

    if (find.text('Create an account').evaluate().isNotEmpty) {
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
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    // 2. Open Calendar Settings
    // The calendar screen is the default, and it has a settings icon in the toolbar
    final settingsButton = find.byIcon(LucideIcons.settings).first;
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    // 3. Open Category Management
    expect(find.text('Manage Categories'), findsOneWidget);
    await tester.tap(find.text('Manage Categories'));
    await tester.pumpAndSettle();

    // Verify we are on Category Management Screen
    expect(find.text('Category Management'), findsOneWidget);

    // 4. Add a new category
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('New Category'), findsOneWidget);

    // Enter name
    await tester.enterText(find.byType(ShadInput).first, 'E2E Test Category');
    
    // Tap a color (we'll just use the default or tap the 2nd one)
    final colorWrap = find.byType(Wrap).first;
    final secondColor = find.descendant(of: colorWrap, matching: find.byType(GestureDetector)).at(1);
    await tester.tap(secondColor);
    await tester.pumpAndSettle();

    // Save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 5. Verify the category appears in the list
    expect(find.text('E2E Test Category'), findsOneWidget);

    // 6. Delete the category
    // Assuming the trailing icon is trash2
    final deleteButton = find.byIcon(LucideIcons.trash2).first;
    await tester.tap(deleteButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify it's gone
    expect(find.text('E2E Test Category'), findsNothing);
  });
}
