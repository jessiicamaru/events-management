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
/// One nudge per evening in range, never one per habit: several habits at risk share a
/// single notification, because the point is to prompt the evening, not to fill the shade.
abstract final class StreakNudgePlanner {
  /// One nudge per evening that has something at risk, for the next
  /// [AppConstants.streakNudgeEvenings] evenings.
  ///
  /// "At risk by the cutoff" is [StreakAtRisk.evaluate] asked about that cutoff rather
  /// than now, which is why planning at 09:00 can schedule tonight's nudge.
  ///
  /// It reaches past tonight on purpose. Planning only today's cutoff meant the nudge
  /// existed only on days the app was opened before 20:00 — so the evening after a quiet
  /// day, the one that needed it most, was silent. Tomorrow's nudge is scheduled on the
  /// assumption that tomorrow's booked habits will not be done, because nothing tomorrow
  /// can be complete yet; completing one re-plans the whole set and drops it.
  ///
  /// Returns empty when the user turned nudges off, or when no evening in range has a
  /// habit at risk. A cutoff already past is never planned — a notification for a moment
  /// gone by is noise, and Home still shows the card.
  static List<ScheduledReminder> plan({
    required List<EventModel> events,
    required List<HabitModel> habits,
    required DateTime now,
    required bool enabled,
    int cutoffHour = AppConstants.streakAtRiskHour,
    int evenings = AppConstants.streakNudgeEvenings,
  }) {
    if (!enabled) return const [];

    final nudges = <ScheduledReminder>[];
    var cutoff = StreakAtRisk.nextCutoffAfter(now, cutoffHour: cutoffHour);

    for (var evening = 0; evening < evenings; evening++) {
      final atRisk = StreakAtRisk.evaluate(
        events: events,
        habits: habits,
        now: cutoff,
        cutoffHour: cutoffHour,
      );

      if (atRisk.isNotEmpty) nudges.add(_nudgeFor(atRisk, cutoff, evening));

      cutoff = StreakAtRisk.nextCutoffAfter(cutoff, cutoffHour: cutoffHour);
    }

    return nudges;
  }

  static ScheduledReminder _nudgeFor(
    List<HabitAtRisk> atRisk,
    DateTime cutoff,
    int evening,
  ) {
    final first = atRisk.first;

    return ScheduledReminder(
      // One id per evening, so tonight's nudge and tomorrow's do not overwrite each other.
      id: AppConstants.streakNudgeNotificationId + evening,
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
    );
  }
}
