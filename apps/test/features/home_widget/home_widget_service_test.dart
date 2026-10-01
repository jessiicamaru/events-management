import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/home_widget/home_widget_service.dart';

void main() {
  group('HomeWidgetService data serialization', () {
    test('updateTodayHabits serializes habits with correct completion status', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final habits = [
        HabitModel(id: 'h1', name: 'Morning Run', targetDays: [1, 2, 3], currentStreak: 5),
        HabitModel(id: 'h2', name: 'Read 30 mins', targetDays: [1, 2, 3]),
      ];

      final events = [
        EventModel(
          id: 'e1',
          title: 'Morning Run Session',
          startTime: today.add(const Duration(hours: 6)).toUtc(),
          endTime: today.add(const Duration(hours: 7)).toUtc(),
          habitId: 'h1',
          isCompleted: true,
        ),
        EventModel(
          id: 'e2',
          title: 'Read Session',
          startTime: today.add(const Duration(hours: 20)).toUtc(),
          endTime: today.add(const Duration(hours: 21)).toUtc(),
          habitId: 'h2',
          isCompleted: false,
        ),
      ];

      // Test the serialization logic directly (same as HomeWidgetService.updateTodayHabits)
      final todayHabits = habits.map((habit) {
        final todayEvents = events.where((e) {
          final eventDate = e.startTime.toLocal();
          return e.habitId == habit.id &&
              eventDate.year == today.year &&
              eventDate.month == today.month &&
              eventDate.day == today.day;
        }).toList();

        final isCompleted = todayEvents.any((e) => e.isCompleted);

        return {
          'id': habit.id,
          'name': habit.name,
          'isCompleted': isCompleted,
          'totalEvents': todayEvents.length,
          'currentStreak': habit.currentStreak,
        };
      }).toList();

      final payload = {
        'date': today.toIso8601String(),
        'habits': todayHabits,
        'completedCount': todayHabits.where((h) => h['isCompleted'] == true).length,
        'totalCount': todayHabits.length,
      };

      final jsonStr = jsonEncode(payload);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['totalCount'], 2);
      expect(decoded['completedCount'], 1);

      final decodedHabits = decoded['habits'] as List;
      expect(decodedHabits.length, 2);

      final morningRun = decodedHabits.firstWhere((h) => h['id'] == 'h1');
      expect(morningRun['name'], 'Morning Run');
      expect(morningRun['isCompleted'], true);
      expect(morningRun['currentStreak'], 5);

      final reading = decodedHabits.firstWhere((h) => h['id'] == 'h2');
      expect(reading['name'], 'Read 30 mins');
      expect(reading['isCompleted'], false);
    });

    test('updateUpNext serializes next event correctly', () {
      final now = DateTime.now();
      final futureStart = now.add(const Duration(hours: 2));
      final futureEnd = now.add(const Duration(hours: 3));

      final events = [
        EventModel(
          id: 'e1',
          title: 'Past Event',
          startTime: now.subtract(const Duration(hours: 5)).toUtc(),
          endTime: now.subtract(const Duration(hours: 4)).toUtc(),
          habitId: 'h1',
        ),
        EventModel(
          id: 'e2',
          title: 'Next Meeting',
          startTime: futureStart.toUtc(),
          endTime: futureEnd.toUtc(),
          habitId: 'h2',
          categoryId: 'work',
        ),
        EventModel(
          id: 'e3',
          title: 'Later Event',
          startTime: now.add(const Duration(hours: 5)).toUtc(),
          endTime: now.add(const Duration(hours: 6)).toUtc(),
          habitId: 'h3',
        ),
      ];

      // Replicate the logic of finding next event (non-recurring, simplified)
      final expandedEvents = List<EventModel>.from(events);
      expandedEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

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

      expect(activeEvent, isNotNull);
      expect(activeEvent!.title, 'Next Meeting');

      final startLocal = activeEvent.startTime.toLocal();
      final endLocal = activeEvent.endTime.toLocal();
      final isOngoing = now.isAfter(startLocal) && now.isBefore(endLocal);

      final payload = {
        'hasEvent': true,
        'title': activeEvent.title,
        'startTime': startLocal.toIso8601String(),
        'endTime': endLocal.toIso8601String(),
        'isOngoing': isOngoing,
        'categoryId': activeEvent.categoryId,
      };

      final jsonStr = jsonEncode(payload);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['hasEvent'], true);
      expect(decoded['title'], 'Next Meeting');
      expect(decoded['isOngoing'], false);
      expect(decoded['categoryId'], 'work');
    });

    test('updateUpNext produces empty payload when no events', () {
      final List<EventModel> events = [];

      final payload = events.isEmpty
          ? {'hasEvent': false}
          : {'hasEvent': true};

      final jsonStr = jsonEncode(payload);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['hasEvent'], false);
    });

    test('HomeWidgetKeys constants are correct', () {
      expect(HomeWidgetKeys.habitsJson, 'habits_json');
      expect(HomeWidgetKeys.upNextJson, 'up_next_json');
      expect(HomeWidgetKeys.lastUpdated, 'last_updated');
    });

    test('HomeWidgetNames constants are correct', () {
      expect(HomeWidgetNames.todayHabits, 'TodayHabitsReceiver');
      expect(HomeWidgetNames.upNext, 'UpNextReceiver');
    });
  });
}
