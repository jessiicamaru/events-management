import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';

/// Asked before the assistant is used for the first time: what leaves the device, and
/// that it can be turned off. The assistant is off until the user says yes here.
class AssistantConsentView extends ConsumerWidget {
  const AssistantConsentView({super.key, required this.onAccept, this.busy = false});

  final VoidCallback onAccept;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final t = ref.watch(translationsProvider);

    Widget point(IconData icon, String key) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(t.translate(key), style: theme.textTheme.small)),
            ],
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ShadCard(
        title: Text(t.translate('assistant_consent_title')),
        description: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(t.translate('assistant_consent_body')),
        ),
        footer: SizedBox(
          width: double.infinity,
          child: ShadButton(
            onPressed: busy ? null : onAccept,
            child: Text(t.translate('assistant_consent_accept')),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 16),
          child: Column(
            children: [
              point(LucideIcons.eye, 'assistant_consent_point_read'),
              point(LucideIcons.toggleLeft, 'assistant_consent_point_off'),
            ],
          ),
        ),
      ),
    );
  }
}
