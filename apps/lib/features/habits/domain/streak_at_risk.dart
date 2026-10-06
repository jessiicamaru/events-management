import 'package:habit_tracker/core/utils/app_constants.dart';
import 'package:habit_tracker/features/calendar/domain/event_occurrence_expander.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';

/// A habit whose streak is alive, is booked for today, is not done yet, and whose day is
/// nearly over.
class HabitAtRisk {
  final HabitModel habit;

  /// The occurrence that would keep the streak — the earliest unfinished one today.
  final EventModel occurrence;

  const HabitAtRisk({required this.habit, required this.occurrence});

  int get streak => habit.currentStreak;

  @override
  bool operator ==(Object other) =>
      other is HabitAtRisk &&
      other.habit.id == habit.id &&
      other.occurrence.id == occurrence.id &&
      other.occurrence.startTime == occurrence.startTime;

  @override
  int get hashCode => Object.hash(habit.id, occurrence.id, occurrence.startTime);

  @override
  String toString() => 'HabitAtRisk(${habit.name}, streak: $streak)';
}

/// Decides which streaks are about to break.
///
/// Pure, like [EventOccurrenceExpander] and `HomeAgenda`: no provider, no plugin, and no
/// clock of its own. The same function answers two questions — what to show on Home
/// ([evaluate] with the current time) and whether to schedule this evening's nudge
/// ([evaluate] with [cutoffFor], which is how the planner asks "will this be at risk by
/// then?").
///
/// A habit is at risk when all of these hold:
///   * its streak is alive (`currentStreak > 0`) — there is something to lose;
///   * it has an occurrence today that is not completed;
///   * the day is running out: the time is at or past [AppConstants.streakAtRiskHour].
///
/// A habit with nothing booked today is **not** at risk here. Whether the streak survives
/// an unbooked day is the day-boundary question in roadmap 5.1, and guessing at it would
/// nag people about habits they never planned for today.
abstract final class StreakAtRisk {
  /// The habits at risk at [now], most to lose first.
  static List<HabitAtRisk> evaluate({
    required List<EventModel> events,
    required List<HabitModel> habits,
    required DateTime now,
    int cutoffHour = AppConstants.streakAtRiskHour,
  }) {
    final local = now.toLocal();
    if (local.hour < cutoffHour) return const [];

    final dayStart = DateTime(local.year, local.month, local.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // The expander substitutes a split-off day for the series' own occurrence, so a day
    // that has been ticked or completed carries its own state here.
    final today = EventOccurrenceExpander.expand(
      events: events,
      rangeStart: dayStart,
      rangeEnd: dayEnd,
    ).where((occurrence) {
      final start = occurrence.startTime.toLocal();
      return !start.isBefore(dayStart) && start.isBefore(dayEnd);
    }).toList();

    final atRisk = <HabitAtRisk>[];

    for (final habit in habits) {
      if (habit.currentStreak <= 0) continue;

      final unfinished = today
          .where((o) => o.habitId == habit.id && !o.isCompleted)
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      if (unfinished.isEmpty) continue;

      atRisk.add(HabitAtRisk(habit: habit, occurrence: unfinished.first));
    }

    atRisk.sort((a, b) => b.streak.compareTo(a.streak));

    return atRisk;
  }

  /// The moment on [now]'s day when a day counts as running out, in local time.
  static DateTime cutoffFor(
    DateTime now, {
    int cutoffHour = AppConstants.streakAtRiskHour,
  }) {
    final local = now.toLocal();

    return DateTime(local.year, local.month, local.day, cutoffHour);
  }
}
