import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/profile/presentation/screens/cosmetics_screen.dart' as habit_tracker_cosmetics;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    
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
                  ListTile(
                    leading: const Icon(LucideIcons.sparkles),
                    title: const Text('Cosmetics & Rewards'),
                    subtitle: const Text('View your level and unlock emojis/colors'),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      // We'll use go_router to navigate
                      // context.push('/cosmetics');
                      // Wait, let's just push it directly for simplicity or use go_router
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
}
