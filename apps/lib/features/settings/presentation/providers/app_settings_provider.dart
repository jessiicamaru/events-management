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

  const AppSettings({
    required this.themeMode,
    required this.primaryColor,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppColorTheme? primaryColor,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      primaryColor: primaryColor ?? this.primaryColor,
    );
  }
}

@riverpod
class AppSettingsNotifier extends _$AppSettingsNotifier {
  static const _themeModeKey = 'settings_theme_mode';
  static const _primaryColorKey = 'settings_primary_color';

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

    return AppSettings(themeMode: themeMode, primaryColor: primaryColor);
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
}
