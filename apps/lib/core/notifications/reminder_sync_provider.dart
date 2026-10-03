import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/core/notifications/notification_service.dart';
import 'package:habit_tracker/core/notifications/reminder_planner.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';

/// The app's single [NotificationService].
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

/// Builds the notification body for one reminder, in the user's language.
String buildReminderBody(AppTranslations translations, ScheduledReminder reminder) {
  final minutes = reminder.minutesBefore;

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

/// Keeps the OS's pending reminders in step with the user's events.
///
/// Watched from the root widget, in the same way as `homeWidgetSyncProvider`: any change
/// to events re-plans and reschedules. Reminders are configured per event, so there is no
/// global switch to consult — an event with an empty reminder set simply contributes
/// nothing, and if no event has any, the plan is empty and everything is cancelled.
///
/// It only ever *writes* to the notification plugin — it never invalidates the providers
/// it watches, which is what keeps this from looping.
final reminderSyncProvider = Provider<void>((ref) {
  final eventsAsync = ref.watch(eventsProvider);
  if (!eventsAsync.hasValue) return;

  final service = ref.read(notificationServiceProvider);
  final translations = ref.watch(translationsProvider);

  final reminders = ReminderPlanner.plan(
    events: eventsAsync.value!,
    now: DateTime.now(),
  );

  // Fire and forget — rescheduling is best-effort and must not block a rebuild.
  // applyPlan cancels everything first, so an empty plan clears any stale alarms.
  service.applyPlan(
    reminders,
    bodyBuilder: (reminder) => buildReminderBody(translations, reminder),
  );
});
