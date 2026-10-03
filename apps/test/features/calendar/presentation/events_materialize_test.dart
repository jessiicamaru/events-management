import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';

class _SlowSplitApi implements ApiService {
  final Completer<String> reply = Completer<String>();
  int calls = 0;

  @override
  Future<String> materializeOccurrence(String seriesId, DateTime occurrenceStart) {
    calls++;
    return reply.future;
  }

  @override
  Future<List<EventModel>> fetchEvents({DateTime? startTime, DateTime? endTime}) async => const [];

  @override
  Future<void> syncGoogleCalendar() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final friday = DateTime.utc(2026, 9, 11, 10);

  final seriesDay = EventModel(
    id: 'jog',
    title: 'Jogging',
    startTime: friday,
    endTime: friday.add(const Duration(hours: 1)),
    habitId: '',
    recurrenceRule: 'RRULE:FREQ=DAILY',
  );

  late _SlowSplitApi api;
  late ProviderContainer container;

  setUp(() {
    api = _SlowSplitApi();
    container = ProviderContainer(overrides: [apiServiceProvider.overrideWithValue(api)]);
    container.listen(eventsProvider, (_, _) {}, fireImmediately: true);
  });

  tearDown(() => container.dispose());

  test('two quick taps on the same day share one request', () async {
    final notifier = container.read(eventsProvider.notifier);

    final first = notifier.materializeOccurrence(seriesDay);
    final second = notifier.materializeOccurrence(seriesDay);
    api.reply.complete('jog-fri');

    expect(await first, 'jog-fri');
    expect(await second, 'jog-fri');
    expect(api.calls, 1, reason: 'otherwise both could create the day');
  });

  test('different days are split off separately', () async {
    final notifier = container.read(eventsProvider.notifier);

    notifier.materializeOccurrence(seriesDay);
    notifier.materializeOccurrence(
      seriesDay.copyWith(startTime: friday.add(const Duration(days: 1))),
    );

    expect(api.calls, 2);
    api.reply.complete('x');
  });

  test('an ordinary event needs no request', () async {
    final single = seriesDay.copyWith(id: 'single', recurrenceRule: null);

    expect(await container.read(eventsProvider.notifier).materializeOccurrence(single), 'single');
    expect(api.calls, 0);
  });
}
