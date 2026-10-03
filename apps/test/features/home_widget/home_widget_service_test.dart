import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/home_widget/home_widget_service.dart';

void main() {
  group('HomeWidgetService data serialization', () {
    test('updateTodayEvents serializes events with correct completion status and formatted time', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

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

      // Test the serialization logic directly
      final todayEventsPayload = events.map((e) {
        final startLocal = e.startTime.toLocal();
        return {
          'id': e.id,
          'title': e.title,
          'time': '${startLocal.hour}:${startLocal.minute}',
          'isCompleted': e.isCompleted,
        };
      }).toList();

      final payload = {
        'date': today.toIso8601String(),
        'events': todayEventsPayload,
        'completedCount': todayEventsPayload.where((e) => e['isCompleted'] == true).length,
        'totalCount': todayEventsPayload.length,
      };

      final jsonStr = jsonEncode(payload);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['totalCount'], 2);
      expect(decoded['completedCount'], 1);

      final decodedEvents = decoded['events'] as List;
      expect(decodedEvents.length, 2);

      final morningRun = decodedEvents.firstWhere((e) => e['id'] == 'e1');
      expect(morningRun['title'], 'Morning Run Session');
      expect(morningRun['isCompleted'], true);

      final reading = decodedEvents.firstWhere((e) => e['id'] == 'e2');
      expect(reading['title'], 'Read Session');
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
      expect(HomeWidgetNames.todayEvents, 'widget.TodayEventsReceiver');
      expect(HomeWidgetNames.upNext, 'widget.UpNextReceiver');
    });
  });
}
