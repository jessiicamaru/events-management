import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:habit_tracker/core/providers/shared_preferences_provider.dart';

part 'app_settings_provider.g.dart';

enum AppColorTheme {
  zinc,
  blue,
  green,
  rose,
  orange,
}

class AppSettings {
  final ThemeMode themeMode;
  final AppColorTheme primaryColor;

  /// Whether the evening "your streak is about to break" notification is wanted.
  /// On by default: a nudge nobody asked for is the point of the feature, and it is one
  /// notification a day at most, only when something is actually at risk.
  final bool streakNudges;

  const AppSettings({
    required this.themeMode,
    required this.primaryColor,
    this.streakNudges = true,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppColorTheme? primaryColor,
    bool? streakNudges,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      primaryColor: primaryColor ?? this.primaryColor,
      streakNudges: streakNudges ?? this.streakNudges,
    );
  }

  // Value equality so that watchers only rebuild on a change they care about. Without it
  // every copyWith looks new to Riverpod, and changing the accent colour would make
  // reminderSyncProvider cancel and re-register every pending notification.
  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.primaryColor == primaryColor &&
      other.streakNudges == streakNudges;

  @override
  int get hashCode => Object.hash(themeMode, primaryColor, streakNudges);
}

@riverpod
class AppSettingsNotifier extends _$AppSettingsNotifier {
  static const _themeModeKey = 'settings_theme_mode';
  static const _primaryColorKey = 'settings_primary_color';
  static const _streakNudgesKey = 'settings_streak_nudges';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    
    // Parse ThemeMode
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.index == themeModeIndex,
      orElse: () => ThemeMode.system,
    );

    // Parse PrimaryColor
    final colorIndex = prefs.getInt(_primaryColorKey) ?? AppColorTheme.zinc.index;
    final primaryColor = AppColorTheme.values.firstWhere(
      (e) => e.index == colorIndex,
      orElse: () => AppColorTheme.zinc,
    );

    return AppSettings(
      themeMode: themeMode,
      primaryColor: primaryColor,
      streakNudges: prefs.getBool(_streakNudgesKey) ?? true,
    );
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_themeModeKey, mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> updatePrimaryColor(AppColorTheme color) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_primaryColorKey, color.index);
    state = state.copyWith(primaryColor: color);
  }

  Future<void> updateStreakNudges(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_streakNudgesKey, enabled);
    state = state.copyWith(streakNudges: enabled);
  }
}
