import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'features/settings/presentation/providers/app_settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const HabitTrackerApp(),
    ),
  );
}

class HabitTrackerApp extends ConsumerWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final appSettings = ref.watch(appSettingsProvider);

    return ShadApp.router(
      title: 'Habit Tracker',
      theme: AppTheme.lightTheme(appSettings.primaryColor),
      darkTheme: AppTheme.darkTheme(appSettings.primaryColor),
      themeMode: appSettings.themeMode,
      materialThemeBuilder: (context, theme) {
        return theme.brightness == Brightness.light 
          ? AppTheme.lightMaterialTheme 
          : AppTheme.darkMaterialTheme;
      },
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
