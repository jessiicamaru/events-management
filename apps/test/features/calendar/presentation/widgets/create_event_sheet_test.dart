import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/core/providers/shared_preferences_provider.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/create_event_sheet.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/habits/presentation/habits_provider.dart';

class MockApiService implements ApiService {
  List<EventModel> eventsToReturn = [];
  EventModel? lastSyncedEvent;

  @override
  Future<List<EventModel>> fetchEvents({DateTime? startTime, DateTime? endTime}) async => eventsToReturn;

  @override
  Future<void> syncEvent(EventModel event) async {
    lastSyncedEvent = event;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A stub HabitsNotifier that returns a fixed list without calling the API.
class _StubHabitsNotifier extends HabitsNotifier {
  final List<HabitModel> habits;
  _StubHabitsNotifier(this.habits);

  @override
  Future<List<HabitModel>> build() async => habits;
}

void main() {
  late MockApiService mockApiService;
  late SharedPreferences prefs;

  final sampleHabits = [
    HabitModel(id: 'h1', name: 'Morning Run', categoryId: 'cat1', targetDays: []),
    HabitModel(id: 'h2', name: 'Read 10 pages', categoryId: 'cat2', targetDays: []),
  ];

  Widget buildTestableWidget(Widget child, {List<HabitModel> habits = const []}) {
    return ProviderScope(
      overrides: [
        apiServiceProvider.overrideWithValue(mockApiService),
        sharedPreferencesProvider.overrideWithValue(prefs),
        habitsProvider.overrideWith(() => _StubHabitsNotifier(habits)),
      ],
      child: ShadApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  setUp(() async {
    mockApiService = MockApiService();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('CreateEventSheet', () {
    testWidgets('renders form fields correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const CreateEventSheet(),
        habits: sampleHabits,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Schedule Event'), findsOneWidget);
      expect(find.text('Habits'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('Create Event'), findsOneWidget);
    });

    testWidgets('shows habit chips from habitsProvider', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const CreateEventSheet(),
        habits: sampleHabits,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Morning Run'), findsOneWidget);
      expect(find.text('Read 10 pages'), findsOneWidget);
    });

    testWidgets('tapping habit chip fills title field', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const CreateEventSheet(),
        habits: sampleHabits,
      ));
      await tester.pumpAndSettle();

      // Tap "Morning Run" chip
      await tester.tap(find.text('Morning Run'));
      await tester.pumpAndSettle();

      // Title field should be auto-filled
      expect(find.widgetWithText(ShadInput, 'Morning Run'), findsOneWidget);
    });

    testWidgets('shows empty state with no habits', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const CreateEventSheet(),
        habits: const [],
      ));
      await tester.pumpAndSettle();

      // Unscheduled Habits section should not appear
      expect(find.text('Unscheduled Habits'), findsNothing);
      // But the form should still show
      expect(find.text('Title'), findsOneWidget);
    });

    testWidgets('shows validation error when submitting without title', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const CreateEventSheet(),
        habits: const [],
      ));
      await tester.pumpAndSettle();

      // The form grew a Reminders field, pushing the button past the viewport. Without
      // this the tap lands off-screen and silently does nothing.
      await tester.ensureVisible(find.text('Create Event'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Event'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter an event title'), findsOneWidget);
    });

    testWidgets('defaults a new event to no reminders', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const CreateEventSheet(),
        habits: const [],
      ));
      await tester.pumpAndSettle();

      // Reminders are opt-in per event: there is no global default to inherit.
      expect(find.text('Reminders'), findsOneWidget);
      expect(find.text('No reminder'), findsOneWidget);
    });

    testWidgets('pre-selects the reminders of the event being edited', (WidgetTester tester) async {
      final existing = EventModel(
        id: 'evt-1',
        title: 'Jogging',
        habitId: '',
        startTime: DateTime(2026, 3, 2, 18).toUtc(),
        endTime: DateTime(2026, 3, 2, 19).toUtc(),
        reminderMinutesBefore: const [60, 30, 5],
      );

      await tester.pumpWidget(buildTestableWidget(
        CreateEventSheet(eventToEdit: existing),
        habits: const [],
      ));
      await tester.pumpAndSettle();

      // Summarised earliest-first, the way it is stored.
      expect(
        find.text('1 hour before, 30 minutes before, 5 minutes before'),
        findsOneWidget,
      );
    });
  });
}
