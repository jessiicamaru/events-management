import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/core/providers/shared_preferences_provider.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/settings/presentation/settings_screen.dart';
import 'package:habit_tracker/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:habit_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:habit_tracker/features/profile/domain/models/user_profile_model.dart';

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

class MockApiService implements ApiService {
  @override
  Future<UserProfileModel> fetchMe() async {
    return const UserProfileModel(
      id: 'user-123',
      email: 'test@example.com',
      totalXP: 100,
      displayName: 'Test User',
      avatar: '🐱',
    );
  }

  @override
  Future<void> updateProfile({
    String? displayName,
    String? bio,
    DateTime? dateOfBirth,
    String? gender,
    String? phoneNumber,
    String? avatar,
  }) async {}

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('SettingsScreen, AppearanceScreen, and ProfileScreen render and function correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'settings_theme_mode': ThemeMode.light.index,
      'settings_primary_color': AppColorTheme.zinc.index,
    });
    final prefs = await SharedPreferences.getInstance();
    
    final fakeAuth = FakeAuthNotifier();
    final mockApi = MockApiService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith(() => fakeAuth),
          apiServiceProvider.overrideWithValue(mockApi),
        ],
        child: const ShadApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify profile section displays user details
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);

    // Tap on Profile tile to navigate to ProfileScreen
    await tester.tap(find.text('Test User'));
    await tester.pumpAndSettle();

    // Verify ProfileScreen components
    expect(find.text('Display Name'), findsWidgets);
    expect(find.text('Bio'), findsWidgets);
    expect(find.text('Date of Birth'), findsWidgets);
    expect(find.text('Gender'), findsWidgets);
    expect(find.text('Phone Number'), findsWidgets);
    expect(find.text('Change Password'), findsWidgets);

    // Pop back to SettingsScreen
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Verify Settings page has Appearance tile
    expect(find.text('Appearance'), findsOneWidget);

    // Tap on Appearance tile to navigate to AppearanceScreen
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();

    // Verify Theme and Color options exist on AppearanceScreen
    expect(find.text('Theme Mode'), findsOneWidget);
    expect(find.text('Primary Color'), findsOneWidget);
    expect(find.text('LIGHT'), findsOneWidget);

    // Pop back to SettingsScreen
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Verify language change dialog
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    expect(find.text('Select Language'), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsOneWidget);

    // Tap Tiếng Việt
    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle();

    // Verify translation works
    expect(find.text('Cài đặt'), findsWidgets); // Settings -> Cài đặt
    expect(find.text('Đăng xuất'), findsOneWidget); // Log Out -> Đăng xuất

    // Tap Log Out (Đăng xuất)
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    // Tap final destructive logout button inside confirmation dialog
    final logOutButton = find.widgetWithText(ShadButton, 'Đăng xuất');
    expect(logOutButton, findsOneWidget);
    await tester.tap(logOutButton);
    await tester.pumpAndSettle();

    expect(fakeAuth.logoutCalled, isTrue);
  });
}
