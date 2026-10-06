import 'package:habit_tracker/core/notifications/reminder_planner.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/habits/domain/streak_at_risk.dart';

/// Decides whether this evening gets a "your streak is about to break" notification.
///
/// Pure, and deliberately separate from [ReminderPlanner]: an event reminder says
/// "something starts soon", this says "something you kept going for days is still
/// unfinished". They share the plan only because the notification plugin holds one set of
/// pending alarms — `applyPlan` cancels everything it is not given, so both plans must
/// reach it together.
///
/// At most one nudge exists at a time. Several habits at risk are one notification, not
/// one each: the point is to prompt the evening, not to fill the shade.
abstract final class StreakNudgePlanner {
  /// The nudge for today, or nothing.
  ///
  /// Returns empty when the user turned nudges off, when the cutoff has already passed
  /// (a notification for a moment gone by is noise — Home still shows the card), or when
  /// nothing would be at risk by the cutoff.
  ///
  /// "Would be at risk by the cutoff" is [StreakAtRisk.evaluate] asked about the cutoff
  /// rather than now, which is why planning at 09:00 can schedule tonight's nudge. The
  /// plan is rebuilt whenever events change, so finishing the habit during the day
  /// cancels it.
  static List<ScheduledReminder> plan({
    required List<EventModel> events,
    required List<HabitModel> habits,
    required DateTime now,
    required bool enabled,
    int cutoffHour = AppConstants.streakAtRiskHour,
  }) {
    if (!enabled) return const [];

    final cutoff = StreakAtRisk.cutoffFor(now, cutoffHour: cutoffHour);
    if (!cutoff.isAfter(now.toLocal())) return const [];

    final atRisk = StreakAtRisk.evaluate(
      events: events,
      habits: habits,
      now: cutoff,
      cutoffHour: cutoffHour,
    );
    if (atRisk.isEmpty) return const [];

    final first = atRisk.first;

    return [
      ScheduledReminder(
        id: AppConstants.streakNudgeNotificationId,
        // The habit, not an event: the nudge is about the streak, and which occurrence
        // carries it can change during the day.
        eventId: first.habit.id,
        title: first.habit.name,
        fireAt: cutoff,
        eventStart: first.occurrence.startTime.toLocal(),
        // Unused for this kind; the body is built from the habit's name.
        minutesBefore: 0,
        kind: ReminderKind.streakAtRisk,
        alsoAtRisk: atRisk.length - 1,
      ),
    ];
  }
}
