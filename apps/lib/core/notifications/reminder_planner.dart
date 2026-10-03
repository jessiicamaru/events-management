import 'package:habit_tracker/core/utils/app_constants.dart';
import 'package:habit_tracker/features/calendar/domain/event_occurrence_expander.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';

/// One notification the app intends to post at a specific local time.
class ScheduledReminder {
  /// Stable across re-planning: the same occurrence always produces the same id, so
  /// rescheduling replaces a pending alarm instead of stacking a duplicate beside it.
  final int id;

  final String eventId;
  final String title;

  /// When to post, in local time.
  final DateTime fireAt;

  /// When the event itself starts, in local time. Used to word the body.
  final DateTime eventStart;

  const ScheduledReminder({
    required this.id,
    required this.eventId,
    required this.title,
    required this.fireAt,
    required this.eventStart,
  });

  @override
  bool operator ==(Object other) =>
      other is ScheduledReminder &&
      other.id == id &&
      other.eventId == eventId &&
      other.title == title &&
      other.fireAt == fireAt &&
      other.eventStart == eventStart;

  @override
  int get hashCode => Object.hash(id, eventId, title, fireAt, eventStart);

  @override
  String toString() =>
      'ScheduledReminder(id: $id, eventId: $eventId, fireAt: $fireAt)';
}

/// Decides which reminders should exist, given the user's events and settings.
///
/// Deliberately pure — no plugin, no platform, no clock of its own. Everything that
/// decides *whether* a notification happens lives here and is unit-tested;
/// [NotificationService] only carries out the result.
abstract final class ReminderPlanner {
  /// Builds the reminder set for [events].
  ///
  /// [now] is the current local time. [leadTime] is how far before an event to post.
  /// Only occurrences starting within [horizon] of [now] are considered — Android
  /// caps how many alarms an app may hold, so planning years ahead would both fail
  /// and be pointless when the data changes daily.
  ///
  /// Skipped: anything already completed, anything whose fire time has passed, and
  /// anything beyond [AppConstants.maxScheduledReminders] (soonest win).
  static List<ScheduledReminder> plan({
    required List<EventModel> events,
    required DateTime now,
    required Duration leadTime,
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

      final start = occurrence.startTime.toLocal();
      if (start.isAfter(horizonEnd)) continue;

      final fireAt = start.subtract(leadTime);

      // A reminder for a moment that has already passed is noise, not a reminder.
      if (!fireAt.isAfter(now)) continue;

      final id = reminderId(occurrence.id, start);

      // The same occurrence can surface twice if the data contains duplicates;
      // keep one, because a duplicate id would silently overwrite anyway.
      if (!seenIds.add(id)) continue;

      reminders.add(
        ScheduledReminder(
          id: id,
          eventId: occurrence.id,
          title: occurrence.title,
          fireAt: fireAt,
          eventStart: start,
        ),
      );
    }

    reminders.sort((a, b) => a.fireAt.compareTo(b.fireAt));

    if (reminders.length > maxReminders) {
      return reminders.sublist(0, maxReminders);
    }

    return reminders;
  }

  /// A stable 31-bit id for one occurrence.
  ///
  /// Android notification ids are 32-bit signed ints, so the hash is masked to stay
  /// positive. Derived from the event id plus the occurrence's start minute, so every
  /// occurrence of a recurring event gets its own id and re-planning is idempotent.
  static int reminderId(String eventId, DateTime occurrenceStart) {
    final slot = DateTime(
      occurrenceStart.year,
      occurrenceStart.month,
      occurrenceStart.day,
      occurrenceStart.hour,
      occurrenceStart.minute,
    );

    return Object.hash(eventId, slot.millisecondsSinceEpoch) & 0x7FFFFFFF;
  }
}
