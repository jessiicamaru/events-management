import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/core/notifications/notification_service.dart';
import 'package:habit_tracker/core/notifications/reminder_planner.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';
import 'package:habit_tracker/features/settings/presentation/providers/reminder_settings_provider.dart';

/// The app's single [NotificationService].
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

/// Builds the notification body for one reminder, in the user's language.
String buildReminderBody(AppTranslations translations, ScheduledReminder reminder) {
  final minutes = reminder.eventStart.difference(reminder.fireAt).inMinutes;

  if (minutes <= 0) return translations.translate('reminder_starting_now');

  if (minutes < Duration.minutesPerHour) {
    return translations.translate(
      'reminder_starts_in_minutes',
      params: {'n': '$minutes'},
    );
  }

  final hours = (minutes / Duration.minutesPerHour).round();

  return translations.translate(
    'reminder_starts_in_hours',
    params: {'n': '$hours'},
  );
}

/// Keeps the OS's pending reminders in step with the user's events and settings.
///
/// Watched from the root widget, in the same way as `homeWidgetSyncProvider`: any
/// change to events or to reminder settings re-plans and reschedules.
///
/// It only ever *writes* to the notification plugin — it never invalidates the
/// providers it watches, which is what keeps this from looping.
final reminderSyncProvider = Provider<void>((ref) {
  final settings = ref.watch(reminderSettingsProvider);
  final service = ref.read(notificationServiceProvider);

  if (!settings.enabled) {
    // Turning reminders off must clear what is already pending, or the user keeps
    // getting notifications for a feature they switched off.
    service.cancelAll();
    return;
  }

  final eventsAsync = ref.watch(eventsProvider);
  if (!eventsAsync.hasValue) return;

  final translations = ref.watch(translationsProvider);

  final reminders = ReminderPlanner.plan(
    events: eventsAsync.value!,
    now: DateTime.now(),
    leadTime: settings.leadTime,
  );

  // Fire and forget — rescheduling is best-effort and must not block a rebuild.
  service.applyPlan(
    reminders,
    bodyBuilder: (reminder) => buildReminderBody(translations, reminder),
  );
});
