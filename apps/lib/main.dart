import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/routing/app_router.dart';
import 'package:habit_tracker/core/theme/app_theme.dart';

import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/core/providers/shared_preferences_provider.dart';
import 'package:habit_tracker/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:habit_tracker/features/home_widget/home_widget_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await initializeDateFormatting('vi', null);
  await initializeDateFormatting('en_US', null);
  
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
    ref.watch(homeWidgetSyncProvider);
    final router = ref.watch(routerProvider);
    final appSettings = ref.watch(appSettingsProvider);
    final appLocale = ref.watch(localeProvider);
    final locale = appLocale == AppLocale.vi ? const Locale('vi', 'VN') : const Locale('en', 'US');

    return ShadApp.router(
      title: 'Habit Tracker',
      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('vi', 'VN'),
      ],
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
