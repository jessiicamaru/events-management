import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habit_tracker/features/settings/presentation/providers/app_settings_provider.dart';

class AppTheme {
  static final ThemeData lightMaterialTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: Colors.blue,
    textTheme: GoogleFonts.interTextTheme(),
  );

  static final ThemeData darkMaterialTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: Colors.blue,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
  );

  static ShadThemeData lightTheme(AppColorTheme colorTheme) {
    ShadColorScheme colorScheme;
    switch (colorTheme) {
      case AppColorTheme.zinc:
        colorScheme = const ShadZincColorScheme.light();
        break;
      case AppColorTheme.blue:
        colorScheme = const ShadBlueColorScheme.light();
        break;
      case AppColorTheme.green:
        colorScheme = const ShadGreenColorScheme.light();
        break;
      case AppColorTheme.rose:
        colorScheme = const ShadRoseColorScheme.light();
        break;
      case AppColorTheme.orange:
        colorScheme = const ShadOrangeColorScheme.light();
        break;
    }

    return ShadThemeData(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: ShadTextTheme.fromGoogleFont(GoogleFonts.inter),
    );
  }

  static ShadThemeData darkTheme(AppColorTheme colorTheme) {
    ShadColorScheme colorScheme;
    switch (colorTheme) {
      case AppColorTheme.zinc:
        colorScheme = const ShadZincColorScheme.dark();
        break;
      case AppColorTheme.blue:
        colorScheme = const ShadBlueColorScheme.dark();
        break;
      case AppColorTheme.green:
        colorScheme = const ShadGreenColorScheme.dark();
        break;
      case AppColorTheme.rose:
        colorScheme = const ShadRoseColorScheme.dark();
        break;
      case AppColorTheme.orange:
        colorScheme = const ShadOrangeColorScheme.dark();
        break;
    }

    return ShadThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: ShadTextTheme.fromGoogleFont(GoogleFonts.inter),
    );
  }

  static Color getBrandColor(AppColorTheme colorTheme) {
    switch (colorTheme) {
      case AppColorTheme.zinc: return const Color(0xFF18181B); // zinc-900
      case AppColorTheme.blue: return const Color(0xFF3B82F6); // blue-500
      case AppColorTheme.green: return const Color(0xFF22C55E); // green-500
      case AppColorTheme.rose: return const Color(0xFFF43F5E); // rose-500
      case AppColorTheme.orange: return const Color(0xFFF97316); // orange-500
    }
  }

  // Tailwind-style color palette for Habit categories
  static const Color tailwindBlue = Color(0xFF3B82F6);
  static const Color tailwindGreen = Color(0xFF10B981); // emerald
  static const Color tailwindRed = Color(0xFFEF4444);
  static const Color tailwindAmber = Color(0xFFF59E0B);
  static const Color tailwindPurple = Color(0xFF8B5CF6);
  static const Color tailwindSlate = Color(0xFF64748B);

  static Color getHabitColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'health':
        return tailwindGreen;
      case 'learning':
        return tailwindBlue;
      case 'work':
        return tailwindPurple;
      case 'hobby':
        return tailwindAmber;
      case 'urgent':
        return tailwindRed;
      default:
        return tailwindSlate;
    }
  }
}
