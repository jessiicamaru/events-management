import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// Keys used for SharedPreferences data exchange with native Android widgets.
abstract class HomeWidgetKeys {
  static const String habitsJson = 'habits_json';
  static const String upNextJson = 'up_next_json';
  static const String lastUpdated = 'last_updated';
}

/// Android widget class names registered in AndroidManifest.xml.
abstract class HomeWidgetNames {
  static const String todayHabits = 'widget.TodayHabitsReceiver';
  static const String upNext = 'widget.UpNextReceiver';
}

/// Service responsible for syncing Flutter app data to Android Home Screen Widgets.
///
/// This service serializes habit and event data into JSON, stores it in
/// SharedPreferences via [HomeWidget], and triggers native widget refreshes.
class HomeWidgetService {
  const HomeWidgetService._();

  /// Updates the "Today's Habits" widget with current habit data and today's events.
  static Future<void> updateTodayHabits({
    required List<HabitModel> habits,
    required List<EventModel> events,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find today's events and map habit completion status
    final todayHabits = habits.map((habit) {
      final todayEvents = events.where((e) {
        final eventDate = e.startTime.toLocal();
        return e.habitId == habit.id &&
            eventDate.year == today.year &&
            eventDate.month == today.month &&
            eventDate.day == today.day;
      }).toList();

      final isCompleted = todayEvents.any((e) => e.isCompleted);
      final totalEvents = todayEvents.length;

      return {
        'id': habit.id,
        'name': habit.name,
        'isCompleted': isCompleted,
        'totalEvents': totalEvents,
        'currentStreak': habit.currentStreak,
      };
    }).toList();

    final payload = {
      'date': today.toIso8601String(),
      'habits': todayHabits,
      'completedCount': todayHabits.where((h) => h['isCompleted'] == true).length,
      'totalCount': todayHabits.length,
    };

    await HomeWidget.saveWidgetData<String>(
      HomeWidgetKeys.habitsJson,
      jsonEncode(payload),
    );
    await HomeWidget.saveWidgetData<String>(
      HomeWidgetKeys.lastUpdated,
      now.toIso8601String(),
    );
    await HomeWidget.updateWidget(androidName: HomeWidgetNames.todayHabits);
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
      updateTodayHabits(habits: habits, events: events),
      updateUpNext(events: events),
    ]);
  }
}
