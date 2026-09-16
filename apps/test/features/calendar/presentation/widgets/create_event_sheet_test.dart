import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/core/providers/shared_preferences_provider.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/create_event_sheet.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';

class MockApiService implements ApiService {
  List<EventModel> eventsToReturn = [];
  EventModel? lastSyncedEvent;

  @override
  Future<List<EventModel>> fetchEvents() async => eventsToReturn;

  @override
  Future<void> syncEvent(EventModel event) async {
    lastSyncedEvent = event;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockApiService mockApiService;
  // The sheet reads calendar settings, which come from SharedPreferences. The provider
  // throws unless it is overridden, so every test here needs a real instance backed by
  // the in-memory store.
  late SharedPreferences prefs;

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        apiServiceProvider.overrideWithValue(mockApiService),
        sharedPreferencesProvider.overrideWithValue(prefs),
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

  final sampleHabits = [
    HabitModel(id: 'h1', name: 'Morning Run', category: 'Health', targetDays: []),
    HabitModel(id: 'h2', name: 'Read 10 pages', category: 'Learning', targetDays: []),
  ];

  group('CreateEventSheet', () {
    testWidgets('renders form fields correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(
        CreateEventSheet(
          habitsAsync: AsyncData(sampleHabits),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Schedule Event'), findsOneWidget);
      expect(find.text('Unscheduled Habits'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('Create Event'), findsOneWidget);
    });

    testWidgets('shows habit chips from habitsAsync', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(
        CreateEventSheet(
          habitsAsync: AsyncData(sampleHabits),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Morning Run'), findsOneWidget);
      expect(find.text('Read 10 pages'), findsOneWidget);
    });

    testWidgets('tapping habit chip fills title field', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(
        CreateEventSheet(
          habitsAsync: AsyncData(sampleHabits),
        ),
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
        CreateEventSheet(
          habitsAsync: const AsyncData([]),
        ),
      ));
      await tester.pumpAndSettle();

      // Unscheduled Habits section should not appear
      expect(find.text('Unscheduled Habits'), findsNothing);
      // But the form should still show
      expect(find.text('Title'), findsOneWidget);
    });

    testWidgets('shows validation error when submitting without title', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(
        CreateEventSheet(
          habitsAsync: const AsyncData([]),
        ),
      ));
      await tester.pumpAndSettle();

      // Tap Create without filling title
      await tester.tap(find.text('Create Event'));
      await tester.pumpAndSettle();

      expect(find.text('Title is required'), findsOneWidget);
    });
  });
}
