import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/main.dart' as app;
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Clear SharedPreferences before each test
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  testWidgets('E2E: Settings - Change Theme and Color', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. Perform Login Flow if we are on Login Screen
    // We use a fixed email/password assuming it exists or we can register
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'user_$timestamp@test.com';
    final testPassword = 'Password123!';

    if (find.text('Create an account').evaluate().isNotEmpty) {
      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();
      
      // Register
      await tester.enterText(find.byType(ShadInput).at(0), testEmail);
      await tester.enterText(find.byType(ShadInput).at(1), testPassword);
      await tester.enterText(find.byType(ShadInput).at(2), testPassword);
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Login
      await tester.enterText(find.byType(ShadInput).at(0), testEmail);
      await tester.enterText(find.byType(ShadInput).at(1), testPassword);
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    // Navigate to Settings
    final bottomNav = find.byType(BottomNavigationBar);
    final settingsTab = find.descendant(of: bottomNav, matching: find.byIcon(LucideIcons.settings)).first;
    expect(settingsTab, findsOneWidget);
    await tester.tap(settingsTab);
    await tester.pumpAndSettle();

    // Verify Settings UI
    expect(find.text('Appearance'), findsOneWidget);
    
    // Tap on Theme Mode select
    final themeSelect = find.text('SYSTEM').last;
    expect(themeSelect, findsOneWidget);
    await tester.tap(themeSelect);
    await tester.pumpAndSettle();

    // Select Dark Mode
    final darkOption = find.text('Dark').last;
    expect(darkOption, findsOneWidget);
    await tester.tap(darkOption);
    await tester.pumpAndSettle();
    
    // Validate ThemeMode selection is updated in UI
    expect(find.text('DARK').last, findsOneWidget);

    // Validate Colors are present
    expect(find.text('Primary Color'), findsOneWidget);

    // Let's tap the second color circle (Blue)
    // We can't find them by text easily, so we use find.byType(GestureDetector) and take the second one.
    // However, there are multiple GestureDetectors. 
    // We can find Wrap, then find the second child.
    final wrap = find.byType(Wrap).first;
    expect(wrap, findsOneWidget);
    
    // The colored containers are inside GestureDetector.
    // We know there are 5 colors. Let's just tap the 3rd one (Green)
    final greenColorButton = find.descendant(
      of: wrap,
      matching: find.byType(GestureDetector),
    ).at(2);
    
    await tester.tap(greenColorButton);
    await tester.pumpAndSettle();

    // Ensure it saved to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('settings_theme_mode'), ThemeMode.dark.index);
    // Green is AppColorTheme.green which has index 2 (zinc 0, blue 1, green 2, rose 3, orange 4)
    expect(prefs.getInt('settings_primary_color'), 2);
  });
}
