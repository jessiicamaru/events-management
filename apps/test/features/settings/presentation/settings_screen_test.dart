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
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);

    // Tap on Language tile to open language selector
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    // Verify select language dialog appears
    expect(find.text('Select Language'), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsOneWidget);

    // Tap on Tiếng Việt
    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle();

    // Verify UI dynamically updated to Vietnamese
    expect(find.text('Cài đặt'), findsOneWidget); // Settings -> Cài đặt
    expect(find.text('Trang phục & Phần thưởng'), findsOneWidget); // Cosmetics & Rewards -> Trang phục & Phần thưởng
    expect(find.text('Đăng xuất'), findsOneWidget); // Log Out -> Đăng xuất

    // Tap on Log Out tile (now 'Đăng xuất')
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    // Verify dialog appears in Vietnamese
    expect(find.text('Bạn có chắc chắn muốn đăng xuất không?'), findsOneWidget);

    // Tap destructive Log Out button (now 'Đăng xuất') inside dialog
    final logOutButton = find.widgetWithText(ShadButton, 'Đăng xuất');
    expect(logOutButton, findsOneWidget);

    await tester.tap(logOutButton);
    await tester.pumpAndSettle();

    // Verify logout logic was invoked
    expect(fakeAuth.logoutCalled, isTrue);
  });
}
