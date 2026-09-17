import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';

class MockApiService implements ApiService {
  List<EventModel> eventsToReturn = [];
  bool syncEventCalled = false;

  @override
  Future<List<EventModel>> fetchEvents() async => eventsToReturn;

  @override
  Future<void> syncEvent(EventModel event) async {
    syncEventCalled = true;
  }

  bool updateEventCalled = false;
  @override
  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    updateEventCalled = true;
  }

  bool deleteEventCalled = false;
  @override
  Future<void> deleteEvent(String id) async {
    deleteEventCalled = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProviderContainer container;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(mockApiService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('EventsNotifier fetches initial data', () async {
    final mockEvents = [
      EventModel(
        id: '1',
        title: 'Event 1',
        habitId: 'habit_1',
        startTime: DateTime(2023, 1, 1, 10),
        endTime: DateTime(2023, 1, 1, 11),
      )
    ];
    mockApiService.eventsToReturn = mockEvents;

    final events = await container.read(eventsProvider.future);

    expect(events, mockEvents);
  });

  test('EventsNotifier adds event optimistically and calls api', () async {
    final mockEvents = <EventModel>[];
    mockApiService.eventsToReturn = mockEvents;

    await container.read(eventsProvider.future);

    final newEvent = EventModel(
      id: '2',
      title: 'Event 2',
      habitId: 'habit_2',
      startTime: DateTime(2023, 1, 2, 10),
      endTime: DateTime(2023, 1, 2, 11),
    );

    await container.read(eventsProvider.notifier).addEvent(newEvent);

    // Verify it called API
    expect(mockApiService.syncEventCalled, true);
  });

  test('EventsNotifier updates event optimistically and calls api', () async {
    final mockEvents = <EventModel>[
      EventModel(
        id: '1',
        title: 'Event 1',
        habitId: 'habit_1',
        startTime: DateTime(2023, 1, 2, 10),
        endTime: DateTime(2023, 1, 2, 11),
      )
    ];
    mockApiService.eventsToReturn = mockEvents;

    await container.read(eventsProvider.future);

    final updatedEvent = mockEvents[0].copyWith(title: 'Updated Event');

    await container.read(eventsProvider.notifier).updateEvent(updatedEvent);

    final events = container.read(eventsProvider).value;
    expect(events?.first.title, 'Updated Event');
    expect(mockApiService.updateEventCalled, true);
  });

  test('EventsNotifier deletes event optimistically and calls api', () async {
    final mockEvents = <EventModel>[
      EventModel(
        id: '1',
        title: 'Event 1',
        habitId: 'habit_1',
        startTime: DateTime(2023, 1, 2, 10),
        endTime: DateTime(2023, 1, 2, 11),
      )
    ];
    mockApiService.eventsToReturn = mockEvents;

    await container.read(eventsProvider.future);

    await container.read(eventsProvider.notifier).deleteEvent('1');

    final events = container.read(eventsProvider).value;
    expect(events?.isEmpty, true);
    expect(mockApiService.deleteEventCalled, true);
  });
}
