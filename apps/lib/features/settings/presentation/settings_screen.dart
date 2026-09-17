import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/profile/presentation/screens/cosmetics_screen.dart' as habit_tracker_cosmetics;
import 'package:habit_tracker/features/profile/presentation/screens/profile_screen.dart';
import 'package:habit_tracker/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:habit_tracker/features/settings/presentation/appearance_screen.dart';
import 'package:habit_tracker/features/auth/presentation/providers/auth_provider.dart';
import '../../../core/localization/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final currentLocale = ref.watch(localeProvider);
    final translations = ref.watch(translationsProvider);
    final profileAsync = ref.watch(userProfileProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                translations.translate('settings_title'),
                style: theme.textTheme.h3,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Profile / Account Section
                  Text(translations.translate('profile_title'), style: theme.textTheme.large),
                  const SizedBox(height: 16),
                  profileAsync.when(
                    data: (profile) {
                      final displayName = profile.displayName ?? translations.translate('profile_title');
                      final email = profile.email;
                      final avatar = profile.avatar ?? '👤';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.muted,
                          child: Text(avatar, style: const TextStyle(fontSize: 20)),
                        ),
                        title: Text(displayName),
                        subtitle: Text(email),
                        trailing: const Icon(LucideIcons.chevronRight),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const ProfileScreen()),
                          );
                        },
                      );
                    },
                    loading: () => const ListTile(
                      title: Text('Loading profile...'),
                    ),
                    error: (err, stack) => ListTile(
                      title: const Text('Profile Error'),
                      subtitle: Text(err.toString()),
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  // App Settings Section
                  Text(translations.translate('settings_title'), style: theme.textTheme.large),
                  const SizedBox(height: 16),
                  
                  // Appearance Settings Page Tile
                  ListTile(
                    leading: const Icon(LucideIcons.palette),
                    title: Text(translations.translate('appearance_title')),
                    subtitle: Text(translations.translate('appearance_desc')),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const AppearanceScreen()),
                      );
                    },
                  ),
                  const Divider(),

                  // Cosmetics Page Tile
                  ListTile(
                    leading: const Icon(LucideIcons.sparkles),
                    title: Text(translations.translate('cosmetics_title')),
                    subtitle: Text(translations.translate('cosmetics_subtitle')),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const habit_tracker_cosmetics.CosmeticsScreen()),
                      );
                    },
                  ),
                  const Divider(),

                  // Language Dialog Selector
                  ListTile(
                    leading: const Icon(LucideIcons.languages),
                    title: Text(translations.translate('language_title')),
                    subtitle: Text(currentLocale == AppLocale.en ? 'English' : 'Tiếng Việt'),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => ShadDialog(
                          title: Text(translations.translate('select_language_title')),
                          description: Text(translations.translate('select_language_desc')),
                          actions: [
                            ShadButton.secondary(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: Text(translations.translate('close')),
                            ),
                          ],
                          child: Material(
                            type: MaterialType.transparency,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('English'),
                                  trailing: currentLocale == AppLocale.en
                                      ? const Icon(LucideIcons.check, color: Colors.green)
                                      : null,
                                  onTap: () {
                                    ref.read(localeProvider.notifier).setLocale(AppLocale.en);
                                    Navigator.of(ctx).pop();
                                  },
                                ),
                                ListTile(
                                  title: const Text('Tiếng Việt'),
                                  trailing: currentLocale == AppLocale.vi
                                      ? const Icon(LucideIcons.check, color: Colors.green)
                                      : null,
                                  onTap: () {
                                    ref.read(localeProvider.notifier).setLocale(AppLocale.vi);
                                    Navigator.of(ctx).pop();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(),

                  // Log Out Tile
                  ListTile(
                    leading: Icon(LucideIcons.logOut, color: theme.colorScheme.destructive),
                    title: Text(
                      translations.translate('logout_title'),
                      style: TextStyle(color: theme.colorScheme.destructive),
                    ),
                    subtitle: Text(translations.translate('logout_subtitle')),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => ShadDialog(
                          title: Text(translations.translate('logout_confirm_title')),
                          description: Text(translations.translate('logout_confirm_desc')),
                          actions: [
                            ShadButton.outline(
                              child: Text(translations.translate('cancel')),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                            ShadButton(
                              backgroundColor: theme.colorScheme.destructive,
                              hoverBackgroundColor: theme.colorScheme.destructive.withOpacity(0.9),
                              child: Text(translations.translate('logout_title')),
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                await ref.read(authProvider.notifier).logout();
                              },
                            ),
                          ],
                        ),
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
}
