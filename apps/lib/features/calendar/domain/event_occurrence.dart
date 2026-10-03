import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_task_model.dart';

/// Telling apart the three kinds of event the app handles.
///
/// A repeating event is stored once, as a series. Every day of it — whether produced by
/// `EventOccurrenceExpander` or by the calendar's own recurrence engine — reaches the UI
/// as a copy of the series with that day's times, **and the series' id**. So the id
/// alone cannot say which day it is; the start time does.
///
/// A day the user has done something to (edited it, ticked one of its tasks, finished a
/// session) has its own event instead: a child, with [EventModel.parentEventId] and
/// [EventModel.exceptionDate] set. It replaces the series' day wherever days are shown.
extension EventOccurrence on EventModel {
  /// One day of a repeating series that has not been split off into its own event.
  ///
  /// Anything stored against its id — tasks, completion, focus time — would be shared
  /// by every day of the series, so such a day must be split off before it is changed.
  bool get isSeriesOccurrence =>
      (recurrenceRule?.isNotEmpty ?? false) && parentEventId == null;
}

/// In [copies] — a day's own tasks, copied from its series — the copy of [template].
///
/// The copies have new ids, so they are matched on what the server copies across:
/// position first, then title. Position alone would pick the wrong task if the day's
/// list was reordered after it was split off; title alone would pick the wrong one of
/// two tasks with the same name.
EventTaskModel? copiedTaskFor(EventTaskModel template, List<EventTaskModel> copies) {
  for (final copy in copies) {
    if (copy.order == template.order && copy.title == template.title) return copy;
  }
  for (final copy in copies) {
    if (copy.title == template.title) return copy;
  }
  return null;
}
