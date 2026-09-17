import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/settings/presentation/providers/app_settings_provider.dart';
import '../../../../core/localization/locale_provider.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final appSettings = ref.watch(appSettingsProvider);
    final translations = ref.watch(translationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(translations.translate('appearance_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.foreground,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Theme Mode Selection
            Text(translations.translate('theme_mode_title'), style: theme.textTheme.large),
            const SizedBox(height: 12),
            ShadSelect<ThemeMode>(
              placeholder: Text(translations.translate('theme_mode_title')),
              initialValue: appSettings.themeMode,
              options: [
                ShadOption(value: ThemeMode.system, child: Text(translations.translate('theme_mode_system'))),
                ShadOption(value: ThemeMode.light, child: Text(translations.translate('theme_mode_light'))),
                ShadOption(value: ThemeMode.dark, child: Text(translations.translate('theme_mode_dark'))),
              ],
              onChanged: (val) {
                if (val != null) {
                  ref.read(appSettingsProvider.notifier).updateThemeMode(val);
                }
              },
              selectedOptionBuilder: (context, value) {
                if (value == ThemeMode.system) return Text(translations.translate('theme_mode_system').toUpperCase());
                if (value == ThemeMode.light) return Text(translations.translate('theme_mode_light').toUpperCase());
                if (value == ThemeMode.dark) return Text(translations.translate('theme_mode_dark').toUpperCase());
                return Text(value.name.toUpperCase());
              },
            ),
            const SizedBox(height: 32),

            // Color Theme Selection
            Text(translations.translate('primary_color_title'), style: theme.textTheme.large),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppColorTheme.values.map((colorTheme) {
                final isSelected = appSettings.primaryColor == colorTheme;
                final colorValue = _getColorValue(colorTheme);

                return GestureDetector(
                  onTap: () {
                    ref.read(appSettingsProvider.notifier).updatePrimaryColor(colorTheme);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorValue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? Icon(LucideIcons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorValue(AppColorTheme colorTheme) {
    switch (colorTheme) {
      case AppColorTheme.zinc: return const Color(0xFF71717A);
      case AppColorTheme.blue: return const Color(0xFF3B82F6);
      case AppColorTheme.green: return const Color(0xFF22C55E);
      case AppColorTheme.rose: return const Color(0xFFF43F5E);
      case AppColorTheme.orange: return const Color(0xFFF97316);
    }
  }
}
