import 'package:habit_tracker/core/utils/app_constants.dart';
import 'package:habit_tracker/features/calendar/domain/event_occurrence_expander.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';

/// One notification the app intends to post at a specific local time.
class ScheduledReminder {
  /// Stable across re-planning: the same occurrence and offset always produce the same
  /// id, so rescheduling replaces a pending alarm instead of stacking a duplicate.
  final int id;

  final String eventId;
  final String title;

  /// When to post, in local time.
  final DateTime fireAt;

  /// When the event itself starts, in local time.
  final DateTime eventStart;

  /// Which of the event's reminder offsets this is. `0` means "when it starts".
  final int minutesBefore;

  const ScheduledReminder({
    required this.id,
    required this.eventId,
    required this.title,
    required this.fireAt,
    required this.eventStart,
    required this.minutesBefore,
  });

  @override
  bool operator ==(Object other) =>
      other is ScheduledReminder &&
      other.id == id &&
      other.eventId == eventId &&
      other.title == title &&
      other.fireAt == fireAt &&
      other.eventStart == eventStart &&
      other.minutesBefore == minutesBefore;

  @override
  int get hashCode =>
      Object.hash(id, eventId, title, fireAt, eventStart, minutesBefore);

  @override
  String toString() =>
      'ScheduledReminder(id: $id, eventId: $eventId, fireAt: $fireAt, '
      'minutesBefore: $minutesBefore)';
}

/// Decides which reminders should exist, given the user's events.
///
/// Deliberately pure — no plugin, no platform, no clock of its own. Everything that
/// decides *whether* a notification happens lives here and is unit-tested;
/// `NotificationService` only carries out the result.
///
/// Each event carries its own [EventModel.reminderMinutesBefore], so one event can have
/// several reminders ("1 hour, 30 min, 5 min before") and a single occurrence of a
/// recurring series can differ from the rest — that occurrence is a child event with its
/// own set, which the expander already substitutes for the master's.
abstract final class ReminderPlanner {
  /// Builds the reminder set for [events].
  ///
  /// [now] is the current local time. Only occurrences starting within [horizon] are
  /// considered — Android caps how many alarms an app may hold, and the data changes
  /// daily, so planning further ahead would mostly be scheduling things about to be
  /// rescheduled.
  ///
  /// Skipped: events with no reminders set, anything already completed, anything whose
  /// fire time has passed, and anything beyond [maxReminders] (soonest win).
  static List<ScheduledReminder> plan({
    required List<EventModel> events,
    required DateTime now,
    Duration horizon = AppConstants.reminderHorizon,
    int maxReminders = AppConstants.maxScheduledReminders,
  }) {
    final horizonEnd = now.add(horizon);

    final occurrences = EventOccurrenceExpander.expand(
      events: events,
      rangeStart: now,
      rangeEnd: horizonEnd,
    );

    final reminders = <ScheduledReminder>[];
    final seenIds = <int>{};

    for (final occurrence in occurrences) {
      if (occurrence.isCompleted) continue;
      if (occurrence.reminderMinutesBefore.isEmpty) continue;

      final start = occurrence.startTime.toLocal();
      if (start.isAfter(horizonEnd)) continue;

      for (final minutesBefore in occurrence.reminderMinutesBefore) {
        // Guards against a value the server would have rejected reaching us anyway.
        if (!AppConstants.reminderOptionsMinutes.contains(minutesBefore)) continue;

        final fireAt = start.subtract(Duration(minutes: minutesBefore));

        // A reminder for a moment that has already passed is noise, not a reminder.
        // The later offsets of the same event may still be in the future, so keep going.
        if (!fireAt.isAfter(now)) continue;

        final id = reminderId(occurrence.id, start, minutesBefore);

        // A duplicate id would silently overwrite, so keep the first and move on.
        if (!seenIds.add(id)) continue;

        reminders.add(
          ScheduledReminder(
            id: id,
            eventId: occurrence.id,
            title: occurrence.title,
            fireAt: fireAt,
            eventStart: start,
            minutesBefore: minutesBefore,
          ),
        );
      }
    }

    reminders.sort((a, b) => a.fireAt.compareTo(b.fireAt));

    if (reminders.length > maxReminders) {
      return reminders.sublist(0, maxReminders);
    }

    return reminders;
  }

  /// A stable 31-bit id for one reminder of one occurrence.
  ///
  /// Android notification ids are 32-bit signed ints, so the hash is masked to stay
  /// positive. Derived from the event id, the occurrence's start minute **and** the
  /// offset — without the offset, an event's "1 hour before" and "5 min before" would
  /// collide and only one would survive.
  static int reminderId(
    String eventId,
    DateTime occurrenceStart,
    int minutesBefore,
  ) {
    final slot = DateTime(
      occurrenceStart.year,
      occurrenceStart.month,
      occurrenceStart.day,
      occurrenceStart.hour,
      occurrenceStart.minute,
    );

    return Object.hash(eventId, slot.millisecondsSinceEpoch, minutesBefore) &
        0x7FFFFFFF;
  }
}
