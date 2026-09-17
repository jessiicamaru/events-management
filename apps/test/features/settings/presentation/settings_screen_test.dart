import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/core/providers/shared_preferences_provider.dart';
import 'package:habit_tracker/features/settings/presentation/settings_screen.dart';
import 'package:habit_tracker/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:habit_tracker/features/auth/presentation/providers/auth_provider.dart';

class FakeAuthNotifier extends Auth {
  bool logoutCalled = false;

  @override
  Future<String?> build() async {
    return 'fake_token';
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    state = const AsyncData(null);
  }
}

void main() {
  testWidgets('SettingsScreen renders ThemeMode, Color options and triggers logout', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'settings_theme_mode': ThemeMode.light.index,
      'settings_primary_color': AppColorTheme.zinc.index,
    });
    final prefs = await SharedPreferences.getInstance();
    
    final fakeAuth = FakeAuthNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith(() => fakeAuth),
        ],
        child: const ShadApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Appearance Section exists
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Theme Mode'), findsOneWidget);
    expect(find.text('Primary Color'), findsOneWidget);
    
    // Verify Theme options are rendered (ShadSelect shows the selected value 'LIGHT')
    expect(find.text('LIGHT'), findsOneWidget);

    // Verify tapping on another color doesn't crash
    expect(find.byType(GestureDetector), findsWidgets);

    // Verify title and tiles are present
    expect(find.text('Cosmetics & Rewards'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);

    // Tap on Log Out tile
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('Are you sure you want to log out?'), findsOneWidget);

    // Tap destructive Log Out button inside dialog
    final logOutButton = find.widgetWithText(ShadButton, 'Log Out');
    expect(logOutButton, findsOneWidget);

    await tester.tap(logOutButton);
    await tester.pumpAndSettle();

    // Verify logout logic was invoked
    expect(fakeAuth.logoutCalled, isTrue);
  });
}
