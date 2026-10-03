import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// Turns stored events into the concrete occurrences that fall in a window.
///
/// A recurring event is stored once, as a base event plus an `RRULE`. Anything that
/// needs to know "what is actually happening between these two dates" has to expand
/// that rule and then subtract the occurrences the user has skipped or edited.
///
/// That expansion was copy-pasted in three places (twice in `HomeWidgetService`, once
/// in `CommandCenterPanel`). This is the one definition.
abstract final class EventOccurrenceExpander {
  /// Expands recurring events in [events] into their occurrences between
  /// [rangeStart] and [rangeEnd], and returns them alongside the non-recurring
  /// events, sorted by start time.
  ///
  /// [rangeStart] and [rangeEnd] are **local** times and bound the recurrence
  /// expansion only. Non-recurring events are passed through untouched — callers
  /// apply whatever window they actually care about, because they disagree: the
  /// "today" widget wants one calendar day, "up next" wants to keep an event that
  /// started earlier and is still running.
  ///
  /// Occurrences are dropped when either:
  ///   * the date appears in the base event's [EventModel.recurrenceExceptionDates]
  ///     (the user deleted that one occurrence), or
  ///   * another event in [events] is a child of this one
  ///     ([EventModel.parentEventId]) whose [EventModel.exceptionDate] matches
  ///     (the user edited that one occurrence, so the child represents it instead).
  ///
  /// **Known limitation.** A malformed `RRULE` does not throw — measured against
  /// `SfCalendar.getRecurrenceDateTimeCollection`, inputs like `'not an rrule'`,
  /// `''` and `'FREQ=BOGUS'` all return zero occurrences. Such an event therefore
  /// disappears from every view that relies on this expander, silently. That matches
  /// the behaviour of the three copies this replaced, so it is preserved rather than
  /// changed here: an empty result cannot be distinguished from a rule that
  /// legitimately has no occurrences in range (a spent `COUNT`, for instance), so
  /// "fall back to the base event when empty" would duplicate real events. Detecting
  /// it properly needs rule validation at the point the rule is saved.
  ///
  /// The `catch` below is kept for inputs that *do* throw, and falls back to the base
  /// event in that case.
  static List<EventModel> expand({
    required List<EventModel> events,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final occurrences = <EventModel>[];

    for (final event in events) {
      final rule = event.recurrenceRule;

      if (rule == null || rule.isEmpty) {
        occurrences.add(event);
        continue;
      }

      try {
        final dates = SfCalendar.getRecurrenceDateTimeCollection(
          rule.replaceAll('RRULE:', ''),
          event.startTime.toLocal(),
          specificStartDate: rangeStart,
          specificEndDate: rangeEnd,
        );

        final duration = event.endTime.difference(event.startTime);

        for (final date in dates) {
          if (_isDeletedOccurrence(event, date)) continue;
          if (_isEditedOccurrence(event, date, events)) continue;

          occurrences.add(
            event.copyWith(
              startTime: date.toUtc(),
              endTime: date.add(duration).toUtc(),
            ),
          );
        }
      } catch (_) {
        occurrences.add(event);
      }
    }

    occurrences.sort((a, b) => a.startTime.compareTo(b.startTime));

    return occurrences;
  }

  /// Whether the user deleted this single occurrence of [event].
  static bool _isDeletedOccurrence(EventModel event, DateTime occurrence) {
    final exceptions = event.recurrenceExceptionDates;
    if (exceptions == null || exceptions.isEmpty) return false;

    for (final raw in exceptions.split(',')) {
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) continue;

      if (_isSameMinute(parsed.toLocal(), occurrence)) return true;
    }

    return false;
  }

  /// Whether a separate child event already represents this occurrence because the
  /// user edited it.
  static bool _isEditedOccurrence(
    EventModel event,
    DateTime occurrence,
    List<EventModel> allEvents,
  ) {
    for (final other in allEvents) {
      if (other.parentEventId != event.id) continue;

      final exceptionDate = other.exceptionDate;
      if (exceptionDate == null) continue;

      if (_isSameMinute(exceptionDate.toLocal(), occurrence)) return true;
    }

    return false;
  }

  /// Compared to the minute: an exception is recorded against an occurrence's slot,
  /// and seconds are not meaningful there.
  static bool _isSameMinute(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;
}
