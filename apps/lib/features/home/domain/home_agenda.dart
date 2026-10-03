import 'package:habit_tracker/features/calendar/domain/event_occurrence_expander.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';

/// Everything the home screen shows, worked out in one pass.
///
/// Kept apart from the widgets so the decisions that actually matter — which event
/// counts as "up next", what is left today, which habit has nothing booked — can be
/// tested without building a UI. The screen only lays this out.
class HomeAgenda {
  const HomeAgenda({
    required this.focusEvent,
    required this.isHappeningNow,
    required this.restOfToday,
    required this.habitsWithoutASlotToday,
    required this.completedToday,
    required this.totalToday,
  });

  /// The event to put at the top: the one running right now, or else the next one
  /// coming up. Null when there is nothing ahead within the look-ahead window.
  final EventModel? focusEvent;

  /// Whether [focusEvent] has already started. Changes the wording from
  /// "up next" to "happening now", and it is the difference between a reminder
  /// and a nudge to get going.
  final bool isHappeningNow;

  /// Today's remaining occurrences, [focusEvent] excluded, earliest first.
  final List<EventModel> restOfToday;

  /// Habits with nothing on today's calendar.
  ///
  /// Deliberately *not* filtered by [HabitModel.targetDays]: no screen in the app
  /// lets a user edit that field, so every habit still carries the Mon–Fri default
  /// from `AppConstants.defaultTargetDays`. Filtering on it would invent a
  /// distinction the user never made, and would empty this list every weekend.
  final List<HabitModel> habitsWithoutASlotToday;

  /// Today's completed and total occurrence counts, for the progress line.
  final int completedToday;
  final int totalToday;

  bool get hasAnythingToday => totalToday > 0;

  /// Builds the agenda from the raw provider data.
  ///
  /// [now] is injected rather than read from the clock so tests are not flaky.
  /// [lookAhead] bounds how far forward [focusEvent] may reach: without a bound,
  /// an empty week would surface an event a month away as "up next", which reads
  /// as noise rather than help.
  static HomeAgenda build({
    required List<EventModel> events,
    required List<HabitModel> habits,
    required DateTime now,
    Duration lookAhead = const Duration(days: 7),
  }) {
    // Starts a day early on purpose: an event that began before `now` and is still
    // running is the single most useful thing this screen can show, and a window
    // starting at `now` would expand right past it.
    final occurrences = EventOccurrenceExpander.expand(
      events: events,
      rangeStart: now.subtract(const Duration(days: 1)),
      rangeEnd: now.add(lookAhead),
    );

    final focusEvent = _pickFocusEvent(occurrences, now, now.add(lookAhead));
    final isHappeningNow =
        focusEvent != null && !now.isBefore(focusEvent.startTime.toLocal());

    final today = occurrences
        .where((e) => _isSameDay(e.startTime.toLocal(), now))
        .toList();

    final restOfToday = today
        .where(
          (e) =>
              e.startTime.toLocal().isAfter(now) &&
              !_isSameOccurrence(e, focusEvent),
        )
        .toList();

    final habitIdsBookedToday = today
        .map((e) => e.habitId)
        .where((id) => id.isNotEmpty)
        .toSet();

    final habitsWithoutASlotToday = habits
        .where((h) => h.id.isNotEmpty && !habitIdsBookedToday.contains(h.id))
        .toList();

    return HomeAgenda(
      focusEvent: focusEvent,
      isHappeningNow: isHappeningNow,
      restOfToday: restOfToday,
      habitsWithoutASlotToday: habitsWithoutASlotToday,
      completedToday: today.where((e) => e.isCompleted).length,
      totalToday: today.length,
    );
  }

  /// An event already under way wins over one that starts later, even if the later
  /// one is closer to [now] in the sorted list — being mid-event is the stronger
  /// signal about what the user is doing.
  ///
  /// [horizon] has to be applied here rather than left to the expander:
  /// `EventOccurrenceExpander` bounds recurrence expansion only and passes
  /// non-recurring events through untouched, so a one-off event a month away would
  /// otherwise be offered as "up next".
  static EventModel? _pickFocusEvent(
    List<EventModel> occurrences,
    DateTime now,
    DateTime horizon,
  ) {
    for (final event in occurrences) {
      if (event.isCompleted) continue;

      final start = event.startTime.toLocal();
      final end = event.endTime.toLocal();

      // Not bounded by the horizon: an event running right now started in the past.
      if (now.isAfter(start) && now.isBefore(end)) return event;
    }

    for (final event in occurrences) {
      if (event.isCompleted) continue;

      final start = event.startTime.toLocal();

      if (start.isAfter(horizon)) continue;
      if (now.isBefore(start)) return event;
    }

    return null;
  }

  /// Compared by id *and* start time. Two occurrences of one recurring event share
  /// an id, so the id alone does not identify an occurrence.
  ///
  /// The expander cannot currently produce two occurrences of the same event on the
  /// same day — `SfCalendar` supports no frequency shorter than `DAILY` — so id
  /// alone would be enough today. This does not rely on that.
  static bool _isSameOccurrence(EventModel a, EventModel? b) =>
      b != null && a.id == b.id && a.startTime == b.startTime;

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
