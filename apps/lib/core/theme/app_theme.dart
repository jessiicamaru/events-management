import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:google_fonts/google_fonts.dart';

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

  static final ShadThemeData lightTheme = ShadThemeData(
    brightness: Brightness.light,
    colorScheme: const ShadZincColorScheme.light(),
    textTheme: ShadTextTheme.fromGoogleFont(GoogleFonts.inter),
  );

  static final ShadThemeData darkTheme = ShadThemeData(
    brightness: Brightness.dark,
    colorScheme: const ShadZincColorScheme.dark(),
    textTheme: ShadTextTheme.fromGoogleFont(GoogleFonts.inter),
  );

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
