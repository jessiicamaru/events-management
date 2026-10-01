import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
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

    final List<EventModel> expandedEvents = [];

    for (var event in events) {
      if (event.recurrenceRule == null || event.recurrenceRule!.isEmpty) {
        final startLocal = event.startTime.toLocal();
        if (startLocal.year == todayStart.year &&
            startLocal.month == todayStart.month &&
            startLocal.day == todayStart.day) {
          expandedEvents.add(event);
        }
      } else {
        try {
          final rrule = event.recurrenceRule!.replaceAll('RRULE:', '');
          final dates = SfCalendar.getRecurrenceDateTimeCollection(
            rrule,
            event.startTime.toLocal(),
            specificStartDate: todayStart,
            specificEndDate: todayEnd,
          );

          final duration = event.endTime.difference(event.startTime);

          for (var date in dates) {
            bool isException = false;
            if (event.recurrenceExceptionDates != null &&
                event.recurrenceExceptionDates!.isNotEmpty) {
              final exceptionDates = event.recurrenceExceptionDates!.split(',');
              for (var exDateStr in exceptionDates) {
                try {
                  final exDate = DateTime.parse(exDateStr).toLocal();
                  if (exDate.year == date.year &&
                      exDate.month == date.month &&
                      exDate.day == date.day &&
                      exDate.hour == date.hour &&
                      exDate.minute == date.minute) {
                    isException = true;
                    break;
                  }
                } catch (_) {}
              }
            }
            if (isException) continue;

            bool hasCustomException = false;
            for (var other in events) {
              if (other.parentEventId == event.id &&
                  other.exceptionDate != null) {
                final exDate = other.exceptionDate!.toLocal();
                if (exDate.year == date.year &&
                    exDate.month == date.month &&
                    exDate.day == date.day &&
                    exDate.hour == date.hour &&
                    exDate.minute == date.minute) {
                  hasCustomException = true;
                  break;
                }
              }
            }
            if (hasCustomException) continue;

            expandedEvents.add(
              event.copyWith(
                startTime: date.toUtc(),
                endTime: date.add(duration).toUtc(),
              ),
            );
          }
        } catch (_) {}
      }
    }

    expandedEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

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

    // Expand recurring events (same logic as CommandCenterPanel)
    final List<EventModel> expandedEvents = [];

    for (var event in events) {
      if (event.recurrenceRule == null || event.recurrenceRule!.isEmpty) {
        expandedEvents.add(event);
      } else {
        try {
          final rrule = event.recurrenceRule!.replaceAll('RRULE:', '');
          final dates = SfCalendar.getRecurrenceDateTimeCollection(
            rrule,
            event.startTime.toLocal(),
            specificStartDate: rangeStart,
            specificEndDate: rangeEnd,
          );

          final duration = event.endTime.difference(event.startTime);

          for (var date in dates) {
            bool isException = false;
            if (event.recurrenceExceptionDates != null &&
                event.recurrenceExceptionDates!.isNotEmpty) {
              final exceptionDates =
                  event.recurrenceExceptionDates!.split(',');
              for (var exDateStr in exceptionDates) {
                try {
                  final exDate = DateTime.parse(exDateStr).toLocal();
                  if (exDate.year == date.year &&
                      exDate.month == date.month &&
                      exDate.day == date.day &&
                      exDate.hour == date.hour &&
                      exDate.minute == date.minute) {
                    isException = true;
                    break;
                  }
                } catch (_) {}
              }
            }
            if (isException) continue;

            bool hasCustomException = false;
            for (var other in events) {
              if (other.parentEventId == event.id &&
                  other.exceptionDate != null) {
                final exDate = other.exceptionDate!.toLocal();
                if (exDate.year == date.year &&
                    exDate.month == date.month &&
                    exDate.day == date.day &&
                    exDate.hour == date.hour &&
                    exDate.minute == date.minute) {
                  hasCustomException = true;
                  break;
                }
              }
            }
            if (hasCustomException) continue;

            expandedEvents.add(
              event.copyWith(
                startTime: date.toUtc(),
                endTime: date.add(duration).toUtc(),
              ),
            );
          }
        } catch (_) {
          expandedEvents.add(event);
        }
      }
    }

    expandedEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

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
