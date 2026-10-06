import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/core/notifications/notification_service.dart';
import 'package:habit_tracker/core/notifications/reminder_planner.dart';
import 'package:habit_tracker/core/notifications/streak_nudge_planner.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';
import 'package:habit_tracker/features/habits/presentation/habits_provider.dart';
import 'package:habit_tracker/features/settings/presentation/providers/app_settings_provider.dart';

/// The app's single [NotificationService].
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

/// Builds the notification body for one reminder, in the user's language.
String buildReminderBody(AppTranslations translations, ScheduledReminder reminder) {
  if (reminder.kind == ReminderKind.streakAtRisk) {
    // The title names the habit with most to lose; the body says how many others are in
    // the same position, so one notification does not read as a single-habit alert.
    final others = reminder.alsoAtRisk;

    if (others <= 0) return translations.translate('streak_nudge_body');

    return translations.translate(
      'streak_nudge_body_multi',
      params: {'n': '$others'},
    );
  }

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

/// Keeps the OS's pending notifications in step with the user's events and habits.
///
/// Watched from the root widget, in the same way as `homeWidgetSyncProvider`: any change
/// to events re-plans and reschedules. Reminders are configured per event, so there is no
/// global switch to consult — an event with an empty reminder set simply contributes
/// nothing, and if no event has any, the plan is empty and everything is cancelled.
///
/// It also carries this evening's streak nudge (`StreakNudgePlanner`), because
/// `applyPlan` cancels every pending notification it is not given: planned separately,
/// whichever ran second would wipe the other.
///
/// It only ever *writes* to the notification plugin — it never invalidates the providers
/// it watches, which is what keeps this from looping.
final reminderSyncProvider = Provider<void>((ref) {
  final eventsAsync = ref.watch(eventsProvider);
  if (!eventsAsync.hasValue) return;

  final service = ref.read(notificationServiceProvider);
  final translations = ref.watch(translationsProvider);
  final habitsAsync = ref.watch(habitsProvider);
  // Narrowed to the one field: a theme change must not re-register every alarm.
  final nudgesOn = ref.watch(
    appSettingsProvider.select((settings) => settings.streakNudges),
  );
  final now = DateTime.now();

  final reminders = [
    ...ReminderPlanner.plan(events: eventsAsync.value!, now: now),
    // Habits are a separate request, so the nudge simply waits for them rather than
    // holding up the event reminders.
    if (habitsAsync.hasValue)
      ...StreakNudgePlanner.plan(
        events: eventsAsync.value!,
        habits: habitsAsync.value!,
        now: now,
        enabled: nudgesOn,
      ),
  ];

  // Fire and forget — rescheduling is best-effort and must not block a rebuild.
  // applyPlan cancels everything first, so an empty plan clears any stale alarms.
  service.applyPlan(
    reminders,
    bodyBuilder: (reminder) => buildReminderBody(translations, reminder),
  );
});
