import 'package:habit_tracker/features/calendar/domain/event_occurrence.dart';
import 'package:habit_tracker/features/calendar/domain/event_occurrence_expander.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';

/// One day of activity, as shown on the home screen.
class DailyActivity {
  const DailyActivity({
    required this.date,
    required this.scheduled,
    required this.completed,
    required this.focusMinutes,
  });

  /// The calendar day, with no time part. The server groups by the UTC+7 day that
  /// streaks use, so this is that day — not a moment to convert to local time.
  final DateTime date;
  final int scheduled;
  final int completed;
  final int focusMinutes;

  factory DailyActivity.fromJson(Map<String, dynamic> json) {
    // The server sends the day as midnight UTC ("2026-09-10T00:00:00Z"). Take the
    // date parts as they are: calling toLocal() first would move it to the previous
    // day for anyone west of UTC.
    final parsed = DateTime.parse(json['date'] as String);

    return DailyActivity(
      date: DateTime(parsed.year, parsed.month, parsed.day),
      // The server counts one-off events only; see [ActivitySummary.withRepeatingDays].
      scheduled: json['oneOffScheduled'] as int? ?? 0,
      completed: json['oneOffCompleted'] as int? ?? 0,
      focusMinutes: json['focusMinutes'] as int? ?? 0,
    );
  }

  DailyActivity plus({required int scheduled, required int completed}) => DailyActivity(
        date: date,
        scheduled: this.scheduled + scheduled,
        completed: this.completed + completed,
        focusMinutes: focusMinutes,
      );
}

/// A window of daily activity plus its totals.
///
/// Hand-written rather than freezed: it is read-only data with no copyWith or
/// equality needs, and one less generated file is one less thing to go stale.
class ActivitySummary {
  const ActivitySummary({
    required this.days,
    required this.totalScheduled,
    required this.totalCompleted,
    required this.totalFocusMinutes,
    required this.bestFocusMinutes,
  });

  /// Oldest first, one entry per day including empty ones.
  final List<DailyActivity> days;
  final int totalScheduled;
  final int totalCompleted;
  final int totalFocusMinutes;
  final int bestFocusMinutes;

  bool get isEmpty => totalScheduled == 0 && totalFocusMinutes == 0;

  /// Completed share of scheduled events, 0–1. Null when nothing was scheduled, so
  /// the UI can say so instead of showing a misleading 0%.
  double? get completionRate =>
      totalScheduled == 0 ? null : totalCompleted / totalScheduled;

  /// What the server sent: one-off events and focus time. Days of repeating events are
  /// missing until [withRepeatingDays] adds them.
  factory ActivitySummary.fromJson(Map<String, dynamic> json) {
    final days = (json['days'] as List? ?? const [])
        .map((d) => DailyActivity.fromJson(d as Map<String, dynamic>))
        .toList();

    return ActivitySummary._fromDays(
      days,
      totalFocusMinutes: json['totalFocusMinutes'] as int? ?? 0,
      bestFocusMinutes: json['bestFocusMinutes'] as int? ?? 0,
    );
  }

  factory ActivitySummary._fromDays(
    List<DailyActivity> days, {
    required int totalFocusMinutes,
    required int bestFocusMinutes,
  }) {
    return ActivitySummary(
      days: days,
      totalScheduled: days.fold(0, (sum, d) => sum + d.scheduled),
      totalCompleted: days.fold(0, (sum, d) => sum + d.completed),
      totalFocusMinutes: totalFocusMinutes,
      bestFocusMinutes: bestFocusMinutes,
    );
  }

  /// Adds the days of repeating events, which the server cannot count.
  ///
  /// A repeating event is stored as one row dated on its first day. Counting rows
  /// counted each series once, on that day, and otherwise counted only the days that
  /// had been split off — and a day is split off exactly when it is completed, so the
  /// completion rate drifted towards 100%. Here each series is expanded over the
  /// window with [EventOccurrenceExpander], the same code that draws Home and schedules
  /// reminders, with split-off days standing in for the series' days they replace.
  ///
  /// [events] must hold every series and every split-off day; `eventsProvider`
  /// does, since the server returns both regardless of the date range asked for.
  ActivitySummary withRepeatingDays(List<EventModel> events) {
    if (days.isEmpty) return this;

    final repeating = events
        .where((e) => e.isSeriesOccurrence || e.parentEventId != null)
        .toList();
    if (repeating.isEmpty) return this;

    final firstDay = days.first.date;
    final afterLastDay = days.last.date.add(const Duration(days: 1));

    final counts = <DateTime, ({int scheduled, int completed})>{};
    final occurrences = EventOccurrenceExpander.expand(
      events: repeating,
      rangeStart: firstDay,
      rangeEnd: afterLastDay,
    );

    for (final occurrence in occurrences) {
      final start = occurrence.startTime.toLocal();
      final day = DateTime(start.year, start.month, start.day);
      if (day.isBefore(firstDay) || !day.isBefore(afterLastDay)) continue;

      final current = counts[day] ?? (scheduled: 0, completed: 0);
      counts[day] = (
        scheduled: current.scheduled + 1,
        completed: current.completed + (occurrence.isCompleted ? 1 : 0),
      );
    }

    return ActivitySummary._fromDays(
      [
        for (final day in days)
          switch (counts[day.date]) {
            final added? => day.plus(scheduled: added.scheduled, completed: added.completed),
            null => day,
          },
      ],
      totalFocusMinutes: totalFocusMinutes,
      bestFocusMinutes: bestFocusMinutes,
    );
  }
}
