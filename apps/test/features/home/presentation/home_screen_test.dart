import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/habits/presentation/habits_provider.dart';
import 'package:habit_tracker/features/home/domain/models/activity_summary.dart';
import 'package:habit_tracker/features/home/presentation/home_screen.dart';
import 'package:habit_tracker/features/home/presentation/providers/activity_summary_provider.dart';
import 'package:habit_tracker/features/profile/domain/models/user_profile_model.dart';
import 'package:habit_tracker/features/profile/presentation/providers/user_profile_provider.dart';
import '../../../test_utils.dart';
import '../activity_summary_fixture.dart';

class MockApiService implements ApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value([]);
}

class FakeProfileNotifier extends UserProfileNotifier {
  FakeProfileNotifier(this.profile);

  final UserProfileModel profile;

  @override
  Future<UserProfileModel> build() async => profile;
}

void main() {
  /// Events are built relative to the real clock, because the screen reads
  /// `DateTime.now()` itself — a fixed date would drift out of "today".
  final now = DateTime.now();

  EventModel event({
    required String id,
    required String title,
    required Duration fromNow,
    String habitId = '',
    bool isCompleted = false,
  }) {
    final start = now.add(fromNow);
    return EventModel(
      id: id,
      title: title,
      startTime: start.toUtc(),
      endTime: start.add(const Duration(minutes: 45)).toUtc(),
      habitId: habitId,
      isCompleted: isCompleted,
    );
  }

  Widget buildScreen({
    List<EventModel> events = const [],
    List<HabitModel> habits = const [],
    UserProfileModel? profile,
  }) {
    return ProviderScope(
      overrides: [
        ...commonTestOverrides,
        apiServiceProvider.overrideWithValue(MockApiService()),
        // Stubbed explicitly: the catch-all mock above answers every call with a
        // List, which would leave the activity card silently in its error state.
        activitySummaryProvider.overrideWith(
          (ref) async => ActivitySummary.fromJson(serverResponse()),
        ),
        eventsProvider.overrideWith(() => _FakeEventsNotifier(events)),
        habitsProvider.overrideWith(() => _FakeHabitsNotifier(habits)),
        if (profile != null)
          userProfileProvider.overrideWith(() => FakeProfileNotifier(profile)),
      ],
      child: const ShadApp(home: HomeScreen()),
    );
  }

  testWidgets('shows the next event as up next', (tester) async {
    await tester.pumpWidget(
      buildScreen(
        events: [
          event(id: '1', title: 'Morning Jog', fromNow: const Duration(hours: 2)),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Up Next'), findsOneWidget);
    expect(find.text('Morning Jog'), findsOneWidget);
    expect(find.text('Start Session'), findsOneWidget);
  });

  testWidgets('says happening now for an event already under way', (tester) async {
    await tester.pumpWidget(
      buildScreen(
        events: [
          event(
            id: '1',
            title: 'Deep Work',
            fromNow: const Duration(minutes: -10),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Happening now'), findsOneWidget);
    expect(find.text('Up Next'), findsNothing);
  });

  testWidgets('shows the activity summary further down the page', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    // Below the fold, and ListView builds lazily — scroll to it rather than
    // assuming it is already on screen.
    await tester.scrollUntilVisible(find.text('Last 14 days'), 200);

    expect(find.text('Last 14 days'), findsOneWidget);
    expect(find.text('3 of 4'), findsOneWidget);
  });

  testWidgets('shows the empty state when nothing is coming up', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Nothing coming up'), findsOneWidget);
    expect(find.text('Start Session'), findsNothing);
    expect(find.text('Nothing else today.'), findsOneWidget);
  });

  testWidgets('lists habits that have nothing booked today', (tester) async {
    await tester.pumpWidget(
      buildScreen(
        events: [
          event(
            id: '1',
            title: 'Jog',
            // At "now", not later: +1h would land tomorrow when run after 23:00.
            fromNow: Duration.zero,
            habitId: 'h1',
          ),
        ],
        habits: [
          HabitModel(id: 'h1', name: 'Jogging', targetDays: const []),
          HabitModel(id: 'h2', name: 'Reading', targetDays: const []),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Not on today's calendar"), findsOneWidget);
    expect(find.text('Reading'), findsOneWidget);
    expect(
      find.text('Jogging'),
      findsNothing,
      reason: 'Jogging already has an event today',
    );
  });

  testWidgets('asks a user with no habits to create one', (tester) async {
    // Regression: with zero habits the card said "Every habit has a slot today" —
    // true of an empty set, and wrong to say. Seen on a real account.
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.textContaining('You have no habits yet'), findsOneWidget);
    expect(find.text('Create a habit'), findsOneWidget);
    expect(find.text('Every habit has a slot today.'), findsNothing);
  });

  testWidgets('says every habit has a slot only when there are habits, all booked', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildScreen(
        events: [
          event(
            id: '1',
            title: 'Jog',
            // At "now", not later: +1h would land tomorrow when run after 23:00.
            fromNow: Duration.zero,
            habitId: 'h1',
          ),
        ],
        habits: [HabitModel(id: 'h1', name: 'Jogging', targetDays: const [])],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Every habit has a slot today.'), findsOneWidget);
    expect(find.textContaining('You have no habits yet'), findsNothing);
  });

  testWidgets('hides the habits card until habits have loaded', (tester) async {
    // An unloaded list is empty too, and would otherwise produce the same false
    // "every habit has a slot" message.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...commonTestOverrides,
          apiServiceProvider.overrideWithValue(MockApiService()),
          activitySummaryProvider.overrideWith(
            (ref) async => ActivitySummary.fromJson(serverResponse()),
          ),
          eventsProvider.overrideWith(() => _FakeEventsNotifier(const [])),
          habitsProvider.overrideWith(_NeverLoadingHabitsNotifier.new),
        ],
        child: const ShadApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Proves the page is past its loading spinner, so the card's absence is the
    // behaviour under test and not just an unrendered page.
    expect(find.text('Nothing coming up'), findsOneWidget);
    expect(find.text("Not on today's calendar"), findsNothing);
    expect(find.text('Every habit has a slot today.'), findsNothing);
  });

  testWidgets('shows the streak and XP badges from the profile', (tester) async {
    await tester.pumpWidget(
      buildScreen(
        profile: const UserProfileModel(
          id: 'u1',
          email: 'a@b.com',
          totalXP: 320,
          currentStreak: 4,
          displayName: 'Sam',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Sam'), findsOneWidget);
    expect(find.text('4-day streak'), findsOneWidget);
    expect(find.text('320 XP'), findsOneWidget);
  });

  testWidgets('hides the streak badge when the streak is zero', (tester) async {
    // A "0-day streak" badge is noise, and reads as a rebuke on day one.
    await tester.pumpWidget(
      buildScreen(
        profile: const UserProfileModel(
          id: 'u1',
          email: 'a@b.com',
          totalXP: 0,
          currentStreak: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('streak'), findsNothing);
    expect(find.text('0 XP'), findsOneWidget);
  });

  testWidgets('separates later events from the up-next card', (tester) async {
    await tester.pumpWidget(
      buildScreen(
        events: [
          event(id: '1', title: 'First Thing', fromNow: const Duration(minutes: 30)),
          event(id: '2', title: 'Second Thing', fromNow: const Duration(minutes: 90)),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('First Thing'), findsOneWidget);
    expect(find.text('Later today'), findsOneWidget);

    // "Second Thing" only appears if it is still on the same calendar day, which
    // it is not when the suite runs late in the evening.
    final sameDay = DateTime.now()
        .add(const Duration(minutes: 90))
        .day == DateTime.now().day;
    expect(find.text('Second Thing'), sameDay ? findsOneWidget : findsNothing);
  });
}

class _FakeEventsNotifier extends EventsNotifier {
  _FakeEventsNotifier(this.events);

  final List<EventModel> events;

  @override
  Future<List<EventModel>> build() async => events;
}

class _FakeHabitsNotifier extends HabitsNotifier {
  _FakeHabitsNotifier(this.habits);

  final List<HabitModel> habits;

  @override
  Future<List<HabitModel>> build() async => habits;
}

class _NeverLoadingHabitsNotifier extends HabitsNotifier {
  @override
  Future<List<HabitModel>> build() => Completer<List<HabitModel>>().future;
}
