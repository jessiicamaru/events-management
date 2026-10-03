import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/core/providers/shared_preferences_provider.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:habit_tracker/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:habit_tracker/features/settings/presentation/settings_screen.dart';
import 'settings_screen_test.dart' show FakeAuthNotifier, MockApiService;

/// The streak-nudge switch: its stored value, its default, and what tapping it writes.
void main() {
  Future<ProviderContainer> containerWith(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final instance = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(instance)],
    );
    addTearDown(container.dispose);

    return container;
  }

  group('AppSettings.streakNudges', () {
    test('defaults to on when nothing has been stored', () async {
      final container = await containerWith({});

      expect(container.read(appSettingsProvider).streakNudges, isTrue);
    });

    test('reads back a stored false', () async {
      final container = await containerWith({'settings_streak_nudges': false});

      expect(container.read(appSettingsProvider).streakNudges, isFalse);
    });

    test('reads back a stored true', () async {
      final container = await containerWith({'settings_streak_nudges': true});

      expect(container.read(appSettingsProvider).streakNudges, isTrue);
    });

    test('updateStreakNudges persists and updates the state', () async {
      final container = await containerWith({});

      await container.read(appSettingsProvider.notifier).updateStreakNudges(false);

      expect(container.read(appSettingsProvider).streakNudges, isFalse);
      expect(
        container.read(sharedPreferencesProvider).getBool('settings_streak_nudges'),
        isFalse,
        reason: 'the switch must survive a restart',
      );
    });

    test('does not disturb the other settings', () async {
      final container = await containerWith({
        'settings_theme_mode': ThemeMode.dark.index,
        'settings_primary_color': AppColorTheme.rose.index,
      });

      await container.read(appSettingsProvider.notifier).updateStreakNudges(false);

      final settings = container.read(appSettingsProvider);
      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.primaryColor, AppColorTheme.rose);
    });
  });

  group('AppSettings equality', () {
    // Without this, every copyWith looks like a change to Riverpod and an unrelated theme
    // tap makes reminderSyncProvider cancel and re-register every pending notification.
    const base = AppSettings(
      themeMode: ThemeMode.light,
      primaryColor: AppColorTheme.zinc,
      streakNudges: true,
    );

    test('two settings with the same values are equal', () {
      expect(base.copyWith(), base);
      expect(base.copyWith().hashCode, base.hashCode);
    });

    test('a changed field is not equal', () {
      expect(base.copyWith(streakNudges: false), isNot(base));
      expect(base.copyWith(themeMode: ThemeMode.dark), isNot(base));
      expect(base.copyWith(primaryColor: AppColorTheme.blue), isNot(base));
    });

    test('a whole-object watcher ignores a write that changed nothing', () {
      // This is the half that needs ==. Without it every copyWith is a new identity and
      // any watcher of the whole AppSettings rebuilds on a no-op write.
      final container = ProviderContainer(overrides: [
        appSettingsProvider.overrideWith(_FixedSettings.new),
      ]);
      addTearDown(container.dispose);

      var notifications = 0;
      container.listen(appSettingsProvider, (_, _) => notifications++);

      container.read(appSettingsProvider.notifier).state = base.copyWith();
      expect(notifications, 0, reason: 'nothing about the value changed');

      container.read(appSettingsProvider.notifier).state =
          base.copyWith(themeMode: ThemeMode.dark);
      expect(notifications, 1, reason: 'a real change still gets through');
    });

    test('a selected watcher ignores a change to another field', () {
      // This is the half that `select` gives, independently of ==: it compares the
      // extracted bool, which is why reminderSyncProvider narrows its watch rather than
      // relying on AppSettings equality alone.
      final container = ProviderContainer(overrides: [
        appSettingsProvider.overrideWith(_FixedSettings.new),
      ]);
      addTearDown(container.dispose);

      var notifications = 0;
      container.listen(
        appSettingsProvider.select((s) => s.streakNudges),
        (_, _) => notifications++,
      );

      container.read(appSettingsProvider.notifier).state =
          base.copyWith(themeMode: ThemeMode.dark);
      expect(notifications, 0, reason: 'the watched field did not change');

      container.read(appSettingsProvider.notifier).state =
          base.copyWith(themeMode: ThemeMode.dark, streakNudges: false);
      expect(notifications, 1);
    });
  });

  group('the Settings switch, on the real SettingsScreen', () {
    testWidgets('reflects the stored value and writes the new one', (tester) async {
      SharedPreferences.setMockInitialValues({
        'settings_theme_mode': ThemeMode.light.index,
        'settings_primary_color': AppColorTheme.zinc.index,
        'settings_streak_nudges': true,
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith(FakeAuthNotifier.new),
          apiServiceProvider.overrideWithValue(MockApiService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ShadApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final tile = find.text('Evening streak nudge');
      expect(tile, findsOneWidget, reason: 'the switch is reachable in Settings');

      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();

      final theSwitch = find.descendant(
        of: find.ancestor(of: tile, matching: find.byType(ListTile)),
        matching: find.byType(ShadSwitch),
      );
      expect(tester.widget<ShadSwitch>(theSwitch).value, isTrue,
          reason: 'starts from what was stored');

      await tester.tap(theSwitch);
      await tester.pumpAndSettle();

      expect(container.read(appSettingsProvider).streakNudges, isFalse);
      expect(prefs.getBool('settings_streak_nudges'), isFalse,
          reason: 'the switch must survive a restart');
      expect(tester.widget<ShadSwitch>(theSwitch).value, isFalse);
    });
  });
}

class _FixedSettings extends AppSettingsNotifier {
  @override
  AppSettings build() => const AppSettings(
        themeMode: ThemeMode.light,
        primaryColor: AppColorTheme.zinc,
      );
}
