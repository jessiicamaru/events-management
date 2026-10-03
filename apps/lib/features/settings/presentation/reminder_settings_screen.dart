import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/core/notifications/notification_service.dart';
import 'package:habit_tracker/core/notifications/reminder_sync_provider.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';
import 'package:habit_tracker/features/settings/presentation/providers/reminder_settings_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Settings for event reminders: on/off, how early, and whether the OS will
/// actually deliver them.
class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  ConsumerState<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState
    extends ConsumerState<ReminderSettingsScreen> {
  NotificationPermissionStatus? _status;
  int? _pendingCount;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final service = ref.read(notificationServiceProvider);

    final status = await service.currentStatus();
    final pending = await service.pendingCount();

    if (!mounted) return;

    setState(() {
      _status = status;
      _pendingCount = pending;
    });
  }

  Future<void> _onEnabledChanged(bool enabled) async {
    final notifier = ref.read(reminderSettingsProvider.notifier);

    if (!enabled) {
      await notifier.setEnabled(false);
      await _refreshStatus();
      return;
    }

    // Ask for permission at the moment the user opts in, so the system prompt has
    // obvious context. Enable either way — a blocked permission is surfaced below
    // rather than silently reverting a switch the user just flipped.
    final status = await ref.read(notificationServiceProvider).requestPermissions();
    await notifier.setEnabled(true);

    if (!mounted) return;

    setState(() => _status = status);
    await _refreshStatus();
  }

  Future<void> _sendTestNotification() async {
    final translations = ref.read(translationsProvider);
    final toaster = ShadToaster.of(context);

    await ref.read(notificationServiceProvider).showTestNotification(
      title: translations.translate('reminders_test_title'),
      body: translations.translate('reminders_test_body'),
    );

    toaster.show(
      ShadToast(title: Text(translations.translate('reminders_test_title'))),
    );
  }

  String _leadTimeLabel(AppTranslations translations, Duration leadTime) {
    if (leadTime == Duration.zero) {
      return translations.translate('reminders_lead_at_start');
    }

    if (leadTime.inMinutes >= Duration.minutesPerHour) {
      return translations.translate('reminders_lead_hour');
    }

    return translations.translate(
      'reminders_lead_minutes',
      params: {'n': '${leadTime.inMinutes}'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);
    final settings = ref.watch(reminderSettingsProvider);

    // Watching this here means flipping a setting reschedules immediately, rather
    // than waiting for the user to navigate back to a screen that watches it.
    ref.watch(reminderSyncProvider);

    final status = _status;
    final showBlocked =
        settings.enabled && status != null && !status.notificationsAllowed;
    final showInexact = settings.enabled &&
        status != null &&
        status.notificationsAllowed &&
        !status.exactAlarmsAllowed;

    return Scaffold(
      appBar: AppBar(
        title: Text(translations.translate('reminders_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.foreground,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            ShadCard(
              title: Text(
                translations.translate('reminders_title'),
                style: theme.textTheme.large,
              ),
              description: Text(translations.translate('reminders_desc')),
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    const Icon(LucideIcons.bell, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translations.translate('reminders_enable'),
                            style: theme.textTheme.p,
                          ),
                          Text(
                            translations.translate('reminders_enable_desc'),
                            style: theme.textTheme.muted,
                          ),
                        ],
                      ),
                    ),
                    ShadSwitch(
                      value: settings.enabled,
                      onChanged: _onEnabledChanged,
                    ),
                  ],
                ),
              ),
            ),

            if (showBlocked) ...[
              const SizedBox(height: 16),
              _WarningCard(
                icon: LucideIcons.bellOff,
                title: translations.translate('reminders_permission_needed'),
                body: translations.translate(
                  'reminders_permission_needed_desc',
                ),
                isError: true,
              ),
            ],

            if (showInexact) ...[
              const SizedBox(height: 16),
              _WarningCard(
                icon: LucideIcons.clock,
                title: translations.translate('reminders_inexact_warning'),
                body: translations.translate('reminders_inexact_warning_desc'),
                isError: false,
              ),
            ],

            if (settings.enabled) ...[
              const SizedBox(height: 24),
              Text(
                translations.translate('reminders_lead_time'),
                style: theme.textTheme.large,
              ),
              const SizedBox(height: 8),
              ShadRadioGroup<int>(
                initialValue: settings.leadTime.inMinutes,
                onChanged: (minutes) {
                  if (minutes == null) return;
                  ref
                      .read(reminderSettingsProvider.notifier)
                      .setLeadTime(Duration(minutes: minutes));
                },
                items: AppConstants.reminderLeadTimeOptions.map(
                  (option) => ShadRadio<int>(
                    value: option.inMinutes,
                    label: Text(_leadTimeLabel(translations, option)),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              if (_pendingCount != null)
                Text(
                  translations.translate(
                    'reminders_scheduled_count',
                    params: {'n': '$_pendingCount'},
                  ),
                  style: theme.textTheme.muted,
                ),

              const SizedBox(height: 16),
              ShadButton.outline(
                onPressed: _sendTestNotification,
                child: Text(translations.translate('reminders_test')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.isError,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final accent =
        isError ? theme.colorScheme.destructive : theme.colorScheme.primary;

    return ShadCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.p.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body, style: theme.textTheme.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
