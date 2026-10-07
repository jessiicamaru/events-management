/// Booked time against recorded time for one habit or one category.
///
/// Hand-written rather than freezed, for the same reason as `ActivitySummary`: read-only
/// data with no copyWith or equality needs, and one less generated file to go stale.
class PlanVsActualItem {
  const PlanVsActualItem({
    required this.id,
    required this.name,
    required this.sessions,
    required this.plannedMinutes,
    required this.actualMinutes,
  });

  final String id;
  final String name;

  /// How many finished sessions these numbers come from. Shown, because "you average 18
  /// against 30" means something different after 2 sessions and after 20.
  final int sessions;

  final int plannedMinutes;
  final int actualMinutes;

  /// Recorded time as a share of booked time: 1.0 is exactly as planned, 0.6 is "you
  /// book 30 and spend 18", above 1.0 is overrunning.
  ///
  /// Null when nothing was booked, which the server should not send but can: an event may
  /// carry a zero `TargetDuration`. A ratio against zero is not 0 or infinity, it is
  /// "no answer", and the UI says so instead of drawing a bar.
  double? get ratio => plannedMinutes <= 0 ? null : actualMinutes / plannedMinutes;

  /// Minutes over (positive) or under (negative) what was booked.
  int get differenceMinutes => actualMinutes - plannedMinutes;

  factory PlanVsActualItem.fromJson(Map<String, dynamic> json) => PlanVsActualItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        sessions: json['sessions'] as int? ?? 0,
        plannedMinutes: json['plannedMinutes'] as int? ?? 0,
        actualMinutes: json['actualMinutes'] as int? ?? 0,
      );
}

/// Booked against recorded time over a window, grouped two ways.
class PlanVsActual {
  const PlanVsActual({
    required this.byHabit,
    required this.byCategory,
    required this.totalSessions,
    required this.totalPlannedMinutes,
    required this.totalActualMinutes,
  });

  /// Busiest first, by recorded time. Only habits with a finished session appear.
  final List<PlanVsActualItem> byHabit;

  /// The same sessions grouped by category; events with no category are absent.
  final List<PlanVsActualItem> byCategory;

  final int totalSessions;
  final int totalPlannedMinutes;
  final int totalActualMinutes;

  bool get isEmpty => totalSessions == 0;

  /// Sessions the habit list cannot show, because their event has no habit — a plain
  /// calendar event somebody ran a focus session on. Null when there are none.
  ///
  /// Derived rather than sent: the totals already count every session, so whatever a
  /// grouping does not account for is its remainder. Leaving it out made the bars add up to
  /// less than the headline above them, silently.
  PlanVsActualItem? get unlinked => _remainder(byHabit);

  /// The same for categories: sessions on events with no category. Null when there are none.
  ///
  /// Both groupings need this, and for the same reason — neither one sees every session.
  /// Only the habit half got it at first, which left the category view covering a fraction
  /// of the headline with nothing saying so.
  PlanVsActualItem? get uncategorised => _remainder(byCategory);

  int get unlinkedSessions => _missingSessions(byHabit);
  int get uncategorisedSessions => _missingSessions(byCategory);

  int _missingSessions(List<PlanVsActualItem> rows) =>
      totalSessions - rows.fold<int>(0, (sum, i) => sum + i.sessions);

  /// What [rows] leave unaccounted, as a row of its own. Null when they account for
  /// everything, or for more than everything.
  ///
  /// All three numbers are checked, not just the count. The groupings and the totals come
  /// from three separate queries with no snapshot between them, so a session finished or
  /// deleted mid-load can leave the count positive while the minutes go negative — which
  /// rendered as "-30 min of -20 min" under a row claiming no time was booked. Such a row is
  /// transient (the next refresh is consistent) and better shown as nothing.
  PlanVsActualItem? _remainder(List<PlanVsActualItem> rows) {
    final sessions = _missingSessions(rows);
    final planned =
        totalPlannedMinutes - rows.fold<int>(0, (sum, i) => sum + i.plannedMinutes);
    final actual = totalActualMinutes - rows.fold<int>(0, (sum, i) => sum + i.actualMinutes);

    if (sessions <= 0 || planned < 0 || actual < 0) return null;

    return PlanVsActualItem(
      id: '',
      name: '',
      sessions: sessions,
      plannedMinutes: planned,
      actualMinutes: actual,
    );
  }

  /// The overall share of booked time actually spent, or null when nothing was booked.
  double? get ratio =>
      totalPlannedMinutes <= 0 ? null : totalActualMinutes / totalPlannedMinutes;

  factory PlanVsActual.fromJson(Map<String, dynamic> json) => PlanVsActual(
        byHabit: _items(json['byHabit']),
        byCategory: _items(json['byCategory']),
        totalSessions: json['totalSessions'] as int? ?? 0,
        totalPlannedMinutes: json['totalPlannedMinutes'] as int? ?? 0,
        totalActualMinutes: json['totalActualMinutes'] as int? ?? 0,
      );

  static List<PlanVsActualItem> _items(Object? raw) => (raw as List<dynamic>? ?? const [])
      .map((e) => PlanVsActualItem.fromJson(e as Map<String, dynamic>))
      .toList();
}
