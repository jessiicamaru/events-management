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
  /// calendar event that somebody ran a focus session on.
  ///
  /// Derived rather than sent: the totals already count every session, so whatever the
  /// habit rows do not account for is this. Shown as its own row, because leaving it out
  /// made the numbers in the headline disagree with the bars under it.
  int get unlinkedSessions =>
      totalSessions - byHabit.fold(0, (sum, i) => sum + i.sessions);

  int get unlinkedPlannedMinutes =>
      totalPlannedMinutes - byHabit.fold(0, (sum, i) => sum + i.plannedMinutes);

  int get unlinkedActualMinutes =>
      totalActualMinutes - byHabit.fold(0, (sum, i) => sum + i.actualMinutes);

  /// The row for those sessions, or null when every session belongs to a habit.
  PlanVsActualItem? get unlinked => unlinkedSessions <= 0
      ? null
      : PlanVsActualItem(
          id: '',
          name: '',
          sessions: unlinkedSessions,
          plannedMinutes: unlinkedPlannedMinutes,
          actualMinutes: unlinkedActualMinutes,
        );

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
