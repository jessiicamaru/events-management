import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/calendar/domain/event_occurrence_expander.dart';
import 'package:intl/intl.dart';

/// Keys used for SharedPreferences data exchange with native Android widgets.
abstract class HomeWidgetKeys {
  static const String habitsJson = 'habits_json';
  static const String upNextJson = 'up_next_json';
  static const String lastUpdated = 'last_updated';
}

/// Android widget class names registered in AndroidManifest.xml.
abstract class HomeWidgetNames {
  static const String todayEvents = 'widget.TodayEventsReceiver';
  static const String upNext = 'widget.UpNextReceiver';
}

/// Service responsible for syncing Flutter app data to Android Home Screen Widgets.
///
/// This service serializes habit and event data into JSON, stores it in
/// SharedPreferences via [HomeWidget], and triggers native widget refreshes.
class HomeWidgetService {
  const HomeWidgetService._();

  /// Updates the "Today's Events" widget with today's events.
  static Future<void> updateTodayEvents({
    required List<EventModel> events,
  }) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Expand recurrences for today, then keep only what actually falls on today.
    final expandedEvents = EventOccurrenceExpander.expand(
      events: events,
      rangeStart: todayStart,
      rangeEnd: todayEnd,
    ).where((event) {
      final startLocal = event.startTime.toLocal();

      return startLocal.year == todayStart.year &&
          startLocal.month == todayStart.month &&
          startLocal.day == todayStart.day;
    }).toList();


    final todayEventsPayload = expandedEvents.map((e) {
      final startLocal = e.startTime.toLocal();
      final endLocal = e.endTime.toLocal();
      final timeStr = '${DateFormat('h:mm a').format(startLocal)} - ${DateFormat('h:mm a').format(endLocal)}';
      return {
        'id': e.id,
        'title': e.title,
        'time': timeStr,
        'isCompleted': e.isCompleted,
      };
    }).toList();

    final payload = {
      'date': todayStart.toIso8601String(),
      'events': todayEventsPayload,
      'completedCount': todayEventsPayload.where((e) => e['isCompleted'] == true).length,
      'totalCount': todayEventsPayload.length,
    };

    await HomeWidget.saveWidgetData<String>(
      HomeWidgetKeys.habitsJson,
      jsonEncode(payload),
    );
    await HomeWidget.saveWidgetData<String>(
      HomeWidgetKeys.lastUpdated,
      now.toIso8601String(),
    );
    await HomeWidget.updateWidget(androidName: HomeWidgetNames.todayEvents);
  }

  /// Updates the "Up Next" widget with the next upcoming event.
  static Future<void> updateUpNext({
    required List<EventModel> events,
  }) async {
    final now = DateTime.now();
    final rangeStart = now.subtract(const Duration(days: 1));
    final rangeEnd = now.add(const Duration(days: 7));

    // Non-recurring events are passed through unfiltered on purpose: one that began
    // before rangeStart may still be running, and that is the event to show.
    final expandedEvents = EventOccurrenceExpander.expand(
      events: events,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );


    // Find the next upcoming or currently active event
    EventModel? activeEvent;

    for (var event in expandedEvents) {
      final startLocal = event.startTime.toLocal();
      final endLocal = event.endTime.toLocal();
      if (now.isAfter(startLocal) && now.isBefore(endLocal)) {
        activeEvent = event;
        break;
      }
    }

    if (activeEvent == null) {
      for (var event in expandedEvents) {
        final startLocal = event.startTime.toLocal();
        if (now.isBefore(startLocal) && !event.isCompleted) {
          activeEvent = event;
          break;
        }
      }
    }

    final Map<String, dynamic> payload;
    if (activeEvent != null) {
      final startLocal = activeEvent.startTime.toLocal();
      final endLocal = activeEvent.endTime.toLocal();
      final isOngoing =
          now.isAfter(startLocal) && now.isBefore(endLocal);

      payload = {
        'hasEvent': true,
        'title': activeEvent.title,
        'startTime': startLocal.toIso8601String(),
        'endTime': endLocal.toIso8601String(),
        'isOngoing': isOngoing,
        'categoryId': activeEvent.categoryId,
      };
    } else {
      payload = {'hasEvent': false};
    }

    await HomeWidget.saveWidgetData<String>(
      HomeWidgetKeys.upNextJson,
      jsonEncode(payload),
    );
    await HomeWidget.saveWidgetData<String>(
      HomeWidgetKeys.lastUpdated,
      now.toIso8601String(),
    );
    await HomeWidget.updateWidget(androidName: HomeWidgetNames.upNext);
  }

  /// Convenience method to update all widgets at once.
  static Future<void> updateAll({
    required List<HabitModel> habits,
    required List<EventModel> events,
  }) async {
    await Future.wait([
      updateTodayEvents(events: events),
      updateUpNext(events: events),
    ]);
  }
}
