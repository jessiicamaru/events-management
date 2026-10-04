import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_task_model.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/event_tasks_checklist.dart';
import 'package:habit_tracker/features/focus_session/presentation/widgets/post_session_dialog.dart';
import '../../../../test_utils.dart';

/// A server with one daily series ("jog") whose tasks are the template, and which
/// splits a day off into "jog-fri" with fresh copies — the way the real endpoint does.
class _FakeServer implements ApiService {
  final Map<String, List<EventTaskModel>> tasks = {
    // Ticked on the template, as the demo data left it: must not show on a new day.
    'jog': [
      const EventTaskModel(id: 't-warm', eventId: 'jog', title: 'Warm up', order: 0, isCompleted: true),
      const EventTaskModel(id: 't-run', eventId: 'jog', title: 'Run 5 km', order: 1),
    ],
    'single': [
      const EventTaskModel(id: 's1', eventId: 'single', title: 'Read', order: 0),
    ],
  };

  final List<String> materializeCalls = [];
  final List<String> toggleCalls = [];
  final List<Map<String, Object?>> completeCalls = [];

  @override
  Future<String> materializeOccurrence(String seriesId, DateTime occurrenceStart) async {
    materializeCalls.add('$seriesId@${occurrenceStart.toUtc().toIso8601String()}');
    tasks.putIfAbsent(
      'jog-fri',
      () => [
        for (final t in tasks[seriesId]!)
          t.copyWith(id: 'c-${t.id}', eventId: 'jog-fri', isCompleted: false),
      ],
    );
    return 'jog-fri';
  }

  @override
  Future<List<EventTaskModel>> fetchEventTasks(String eventId) async =>
      List.of(tasks[eventId] ?? const []);

  @override
  Future<void> toggleEventTask(String eventId, String taskId, bool isCompleted) async {
    toggleCalls.add('$eventId/$taskId=$isCompleted');
    tasks[eventId] = [
      for (final t in tasks[eventId]!) t.id == taskId ? t.copyWith(isCompleted: isCompleted) : t,
    ];
  }

  @override
  Future<void> completeSession(
    String id,
    String actualDuration,
    bool updateCalendar, {
    DateTime? occurrenceStart,
  }) async {
    completeCalls.add({'id': id, 'occurrenceStart': occurrenceStart});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value([]);
}

class _NoEvents extends EventsNotifier {
  @override
  Future<List<EventModel>> build() async => const [];
}

void main() {
  final friday = DateTime.utc(2026, 9, 11, 10);

  final fridayOfSeries = EventModel(
    id: 'jog',
    title: 'Jogging',
    startTime: friday,
    endTime: friday.add(const Duration(hours: 1)),
    habitId: '',
    recurrenceRule: 'RRULE:FREQ=DAILY',
  );

  final single = EventModel(
    id: 'single',
    title: 'Reading',
    startTime: friday,
    endTime: friday.add(const Duration(hours: 1)),
    habitId: '',
  );

  late _FakeServer server;

  setUp(() => server = _FakeServer());

  Widget build(Widget child) => ProviderScope(
        overrides: [
          ...commonTestOverrides,
          apiServiceProvider.overrideWithValue(server),
          eventsProvider.overrideWith(_NoEvents.new),
        ],
        child: ShadApp(home: Scaffold(body: SingleChildScrollView(child: child))),
      );

  testWidgets('a day of a series shows the series tasks as a fresh, unticked list', (tester) async {
    await tester.pumpWidget(build(EventTasksChecklist(event: fridayOfSeries)));
    await tester.pumpAndSettle();

    expect(find.text('Warm up'), findsOneWidget);
    expect(find.text('Run 5 km'), findsOneWidget);
    expect(find.text('0/2'), findsOneWidget, reason: 'the template tick belongs to no day');
    expect(server.materializeCalls, isEmpty, reason: 'looking changes nothing');
  });

  testWidgets('ticking a task gives the day its own copy and ticks only that', (tester) async {
    // The bug being fixed: ticking "Warm up" on Monday ticked it on every day.
    await tester.pumpWidget(build(EventTasksChecklist(event: fridayOfSeries)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ShadCheckbox).first);
    await tester.pumpAndSettle();

    expect(server.materializeCalls, ['jog@${friday.toIso8601String()}']);
    expect(server.toggleCalls, ['jog-fri/c-t-warm=true']);
    expect(
      server.tasks['jog']!.map((t) => t.isCompleted),
      [true, false],
      reason: 'the series template is untouched — so every other day is too',
    );
    expect(find.text('1/2'), findsOneWidget, reason: "now showing Friday's own list");
  });

  testWidgets('after the split, further ticks go straight to the day', (tester) async {
    await tester.pumpWidget(build(EventTasksChecklist(event: fridayOfSeries)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ShadCheckbox).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ShadCheckbox).last);
    await tester.pumpAndSettle();

    expect(server.materializeCalls, hasLength(1));
    expect(server.toggleCalls, ['jog-fri/c-t-warm=true', 'jog-fri/c-t-run=true']);
    expect(find.text('2/2'), findsOneWidget);
  });

  testWidgets('an ordinary event is ticked in place, with nothing split off', (tester) async {
    await tester.pumpWidget(build(EventTasksChecklist(event: single)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ShadCheckbox).first);
    await tester.pumpAndSettle();

    expect(server.materializeCalls, isEmpty);
    expect(server.toggleCalls, ['single/s1=true']);
  });

  group('PostSessionDialog', () {
    Future<void> finishSession(WidgetTester tester, EventModel event) async {
      await tester.pumpWidget(
        build(PostSessionDialog(event: event, actualSeconds: 1200, targetSeconds: 1800)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark as Complete'));
      await tester.pumpAndSettle();
    }

    testWidgets('completes the day it was for, not the whole series', (tester) async {
      await finishSession(tester, fridayOfSeries);

      expect(server.completeCalls.single['id'], 'jog');
      expect(server.completeCalls.single['occurrenceStart'], friday);
    });

    testWidgets('sends no day for an ordinary event', (tester) async {
      await finishSession(tester, single);

      expect(server.completeCalls.single['occurrenceStart'], isNull);
    });
  });
}
