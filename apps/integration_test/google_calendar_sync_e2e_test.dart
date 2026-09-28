import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/main.dart' as app;
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  testWidgets('E2E: Google Calendar Sync Screen Navigation and UI Verification', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'user_$timestamp@test.com';
    final testPassword = 'Password123!';

    // 1. Perform Registration/Login if on Login/Register screen
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

    // 2. Navigate to Settings Tab
    final bottomNav = find.byType(BottomNavigationBar);
    final settingsTab = find.descendant(of: bottomNav, matching: find.byIcon(LucideIcons.settings)).first;
    expect(settingsTab, findsOneWidget);
    await tester.tap(settingsTab);
    await tester.pumpAndSettle();

    // 3. Scroll down settings screen to show the Google Sync tile
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    // 4. Verify Google Calendar Sync tile exists
    final googleSyncTile = find.text('Google Calendar Sync');
    expect(googleSyncTile, findsOneWidget);
    await tester.tap(googleSyncTile);
    await tester.pumpAndSettle();

    // 5. Verify UI on Google Calendar Sync Screen
    expect(find.text('Not Connected'), findsOneWidget);
    expect(find.text('Connect Google Calendar'), findsOneWidget);

    // Go back
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);
  });
}
