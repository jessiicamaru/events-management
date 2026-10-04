/// One day of activity, as returned by `GET /analytics/summary`.
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
      scheduled: json['scheduled'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      focusMinutes: json['focusMinutes'] as int? ?? 0,
    );
  }
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

  factory ActivitySummary.fromJson(Map<String, dynamic> json) {
    return ActivitySummary(
      days: (json['days'] as List? ?? const [])
          .map((d) => DailyActivity.fromJson(d as Map<String, dynamic>))
          .toList(),
      totalScheduled: json['totalScheduled'] as int? ?? 0,
      totalCompleted: json['totalCompleted'] as int? ?? 0,
      totalFocusMinutes: json['totalFocusMinutes'] as int? ?? 0,
      bestFocusMinutes: json['bestFocusMinutes'] as int? ?? 0,
    );
  }
}
