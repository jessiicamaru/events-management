import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_task_model.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/event_details_dialog.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/calendar/models/event_category.dart';

/// A mock ApiService that returns empty data so no real network calls occur.
class _MockApiService implements ApiService {
  @override
  Future<List<EventTaskModel>> fetchEventTasks(String eventId) async => [];

  @override
  Future<List<EventCategory>> fetchEventCategories({String? squadId}) async => [
    const EventCategory(id: 'cat1', name: 'Health', colorPreset: 'Rose'),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value([]);
}

class MockLocaleNotifier extends LocaleNotifier {
  @override
  AppLocale build() => AppLocale.en;
}

void main() {
  Widget createWidgetUnderTest(EventModel event, HabitModel habit) {
    return ProviderScope(
      overrides: [
        apiServiceProvider.overrideWithValue(_MockApiService()),
        localeProvider.overrideWith(() => MockLocaleNotifier()),
        translationsProvider.overrideWithValue(AppTranslations(AppLocale.en)),
      ],
      child: ShadApp(
        home: Scaffold(
          body: EventDetailsDialog(
            event: event,
            habit: habit,
          ),
        ),
      ),
    );
  }

  testWidgets('EventDetailsDialog renders correctly for pending event', (WidgetTester tester) async {
    final event = EventModel(
      id: 'event-1',
      title: 'Morning Run',
      startTime: DateTime(2023, 1, 1, 6, 0),
      endTime: DateTime(2023, 1, 1, 7, 0),
      habitId: 'habit-1',
      isCompleted: false,
    );
    
    final habit = HabitModel(
      id: 'habit-1',
      name: 'Running',
      categoryId: 'cat1',
      targetDays: [1, 2, 3],
    );

    await tester.pumpWidget(createWidgetUnderTest(event, habit));
    await tester.pumpAndSettle();

    expect(find.text('Morning Run'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Start Focus Session'), findsOneWidget);
  });

  testWidgets('EventDetailsDialog renders correctly for completed event', (WidgetTester tester) async {
    final event = EventModel(
      id: 'event-1',
      title: 'Morning Run',
      startTime: DateTime(2023, 1, 1, 6, 0),
      endTime: DateTime(2023, 1, 1, 7, 0),
      habitId: 'habit-1',
      isCompleted: true,
    );
    
    final habit = HabitModel(
      id: 'habit-1',
      name: 'Running',
      categoryId: 'cat1',
      targetDays: [1, 2, 3],
    );

    await tester.pumpWidget(createWidgetUnderTest(event, habit));
    await tester.pumpAndSettle();
    
    // Custom text printer
    final texts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).toList();
    print('Found texts: $texts');
    
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Mark as Pending'), findsOneWidget);
  });
}
