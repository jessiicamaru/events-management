import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
            const Expanded(
              child: Center(
                child: Text('Settings Screen (Work in progress)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
