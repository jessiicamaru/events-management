import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/profile/presentation/screens/cosmetics_screen.dart' as habit_tracker_cosmetics;
import 'package:habit_tracker/features/settings/presentation/providers/app_settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final appSettings = ref.watch(appSettingsProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Settings',
                style: theme.textTheme.h3,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Appearance Section
                  Text('Appearance', style: theme.textTheme.large),
                  const SizedBox(height: 16),
                  
                  // Theme Mode
                  Text('Theme Mode', style: theme.textTheme.small),
                  const SizedBox(height: 8),
                  ShadSelect<ThemeMode>(
                    placeholder: const Text('Select Theme Mode'),
                    initialValue: appSettings.themeMode,
                    options: [
                      ShadOption(value: ThemeMode.system, child: const Text('System')),
                      ShadOption(value: ThemeMode.light, child: const Text('Light')),
                      ShadOption(value: ThemeMode.dark, child: const Text('Dark')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(appSettingsProvider.notifier).updateThemeMode(val);
                      }
                    },
                    selectedOptionBuilder: (context, value) => Text(value.name.toUpperCase()),
                  ),
                  const SizedBox(height: 24),
                  
                  // Color Theme
                  Text('Primary Color', style: theme.textTheme.small),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: AppColorTheme.values.map((colorTheme) {
                      final isSelected = appSettings.primaryColor == colorTheme;
                      final colorValue = _getColorValue(colorTheme);
                      
                      return GestureDetector(
                        onTap: () {
                          ref.read(appSettingsProvider.notifier).updatePrimaryColor(colorTheme);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorValue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected 
                              ? Icon(LucideIcons.check, color: theme.colorScheme.primaryForeground, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  Text('Account', style: theme.textTheme.large),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(LucideIcons.sparkles),
                    title: const Text('Cosmetics & Rewards'),
                    subtitle: const Text('View your level and unlock emojis/colors'),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const habit_tracker_cosmetics.CosmeticsScreen()),
                      );
                    },
                  ),
                ],
              ),
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
