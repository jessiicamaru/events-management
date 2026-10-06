import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/core/notifications/notification_service.dart';
import 'package:habit_tracker/core/notifications/reminder_planner.dart';
import 'package:habit_tracker/core/notifications/reminder_sync_provider.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/habits/presentation/habits_provider.dart';
import 'package:habit_tracker/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:flutter/material.dart';
import '../../test_utils.dart';

/// Records what reached the plugin instead of talking to one.
class RecordingNotificationService implements NotificationService {
  final List<List<ScheduledReminder>> plans = [];
  final List<String> bodies = [];

  @override
  Future<void> applyPlan(
    List<ScheduledReminder> reminders, {
    required String Function(ScheduledReminder) bodyBuilder,
  }) async {
    plans.add(reminders);
    bodies.addAll(reminders.map(bodyBuilder));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEvents extends EventsNotifier {
  _FakeEvents(this._events);

  final List<EventModel> _events;

  @override
  Future<List<EventModel>> build() async => _events;
}

class _FakeHabits extends HabitsNotifier {
  _FakeHabits(this._habits);

  final List<HabitModel> _habits;

  @override
  Future<List<HabitModel>> build() async => _habits;
}

class _FakeSettings extends AppSettingsNotifier {
  _FakeSettings(this._settings);

  final AppSettings _settings;

  @override
  AppSettings build() => _settings;
}

void main() {
  // A fixed morning. Read from the wall clock, these fixtures asserted "this suite runs
  // before 20:00": after the cutoff the nudge planner returns nothing and three tests here
  // failed — which on CI (UTC) meant every push between 20:00 and midnight.
  final now = DateTime(2026, 9, 12, 9, 0);

  // Far enough before the cutoff that both a reminder and a nudge are still schedulable.
  final soon = now.add(const Duration(days: 1)).copyWith(hour: 9, minute: 0);
  final today = now;

  EventModel event({
    required String id,
    required DateTime start,
    String habitId = 'habit-1',
    bool completed = false,
    List<int> reminders = const [],
  }) =>
      EventModel(
        id: id,
        title: 'Read',
        startTime: start,
        endTime: start.add(const Duration(minutes: 30)),
        habitId: habitId,
        isCompleted: completed,
        reminderMinutesBefore: reminders,
      );

  /// An occurrence late today, so the habit is unfinished when the cutoff arrives.
  EventModel tonight({String id = 'tonight', String habitId = 'habit-1'}) => event(
        id: id,
        habitId: habitId,
        start: DateTime(today.year, today.month, today.day, 23, 30),
      );

  HabitModel habit({String id = 'habit-1', String name = 'Read', int streak = 5}) =>
      HabitModel(
        id: id,
        name: name,
        targetDays: const [1, 2, 3, 4, 5],
        currentStreak: streak,
      );

  ProviderContainer containerWith({
    required List<EventModel> events,
    required List<HabitModel> habits,
    required RecordingNotificationService service,
    bool streakNudges = true,
  }) {
    final container = ProviderContainer(
      overrides: [
        ...commonTestOverrides,
        notificationServiceProvider.overrideWithValue(service),
        eventsProvider.overrideWith(() => _FakeEvents(events)),
        habitsProvider.overrideWith(() => _FakeHabits(habits)),
        appSettingsProvider.overrideWith(
          () => _FakeSettings(
            AppSettings(
              themeMode: ThemeMode.light,
              primaryColor: AppColorTheme.zinc,
              streakNudges: streakNudges,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    return container;
  }

  /// Resolves both async providers, then reads the sync provider once, with the clock
  /// pinned to [at] — the provider plans against `clock.now()`.
  Future<void> settle(ProviderContainer container, {DateTime? at}) async {
    await container.read(eventsProvider.future);
    await container.read(habitsProvider.future);

    await withClock(Clock.fixed(at ?? now), () async {
      container.read(reminderSyncProvider);
      // The provider fires applyPlan without awaiting it.
      await Future<void>.delayed(Duration.zero);
    });
  }

  group('reminderSyncProvider', () {
    test('sends event reminders and the streak nudge in ONE applyPlan call', () async {
      // This is the whole reason the two planners share a provider: applyPlan opens with
      // cancelAll(), so a second call would wipe whatever the first registered.
      final service = RecordingNotificationService();
      final container = containerWith(
        events: [
          event(id: 'with-reminder', start: soon, reminders: const [15]),
          tonight(),
        ],
        habits: [habit()],
        service: service,
      );

      await settle(container);

      expect(service.plans, hasLength(1), reason: 'exactly one applyPlan call');

      final kinds = service.plans.single.map((r) => r.kind).toSet();
      expect(kinds, containsAll(ReminderKind.values),
          reason: 'both kinds ride in the same plan');
    });

    test('drops the nudge, but keeps event reminders, when the switch is off', () async {
      final service = RecordingNotificationService();
      final container = containerWith(
        events: [
          event(id: 'with-reminder', start: soon, reminders: const [15]),
          tonight(),
        ],
        habits: [habit()],
        service: service,
        streakNudges: false,
      );

      await settle(container);

      final plan = service.plans.single;
      expect(plan.any((r) => r.kind == ReminderKind.streakAtRisk), isFalse);
      expect(plan.any((r) => r.kind == ReminderKind.eventReminder), isTrue);
    });

    test('builds the nudge body from the habit, not from minutesBefore', () async {
      // minutesBefore is 0 on a nudge; without the kind branch the body would read
      // "Starting now".
      final service = RecordingNotificationService();
      final container = containerWith(
        events: [tonight()],
        habits: [habit()],
        service: service,
      );

      await settle(container);

      expect(service.bodies, contains('Still open today — finish it to keep your streak'));
      expect(service.bodies, isNot(contains('Starting now')));
    });

    test('names the other habits at risk in the body when there are several', () async {
      final service = RecordingNotificationService();
      final container = containerWith(
        events: [
          tonight(),
          tonight(id: 'tonight-2', habitId: 'habit-2'),
          tonight(id: 'tonight-3', habitId: 'habit-3'),
        ],
        habits: [
          habit(),
          habit(id: 'habit-2', name: 'Run', streak: 30),
          habit(id: 'habit-3', name: 'Meditate', streak: 2),
        ],
        service: service,
      );

      await settle(container);

      expect(
        service.bodies,
        contains('Still open today, with 2 more — finish them to keep your streaks'),
      );
    });

    test('an unrelated settings change does not re-register every alarm', () async {
      // applyPlan opens with cancelAll(), so re-running on a theme tap would tear down
      // and rebuild up to 251 alarms for nothing. The watch is narrowed to the one field.
      final service = RecordingNotificationService();
      final container = containerWith(
        events: [
          event(id: 'with-reminder', start: soon, reminders: const [15]),
          tonight(),
        ],
        habits: [habit()],
        service: service,
      );

      // A live subscription, so the provider re-runs when a dependency changes.
      container.listen(reminderSyncProvider, (_, _) {});
      await settle(container);

      expect(service.plans, hasLength(1));

      final settings = container.read(appSettingsProvider.notifier);
      settings.state = settings.state.copyWith(themeMode: ThemeMode.dark);
      settings.state = settings.state.copyWith(primaryColor: AppColorTheme.rose);
      await Future<void>.delayed(Duration.zero);

      expect(service.plans, hasLength(1),
          reason: 'the theme is no business of this provider');

      settings.state = settings.state.copyWith(streakNudges: false);
      await Future<void>.delayed(Duration.zero);

      expect(service.plans, hasLength(2),
          reason: 'the field it does watch still re-plans');
    });

    test('keeps the plan when habits have not loaded yet', () async {
      // Habits are a separate request; the event reminders must not wait for it.
      final service = RecordingNotificationService();
      final container = containerWith(
        events: [event(id: 'with-reminder', start: soon, reminders: const [15])],
        habits: const [],
        service: service,
      );

      await container.read(eventsProvider.future);
      // Pinned like settle(), but without awaiting habits — that is what this test is about.
      // Read from the wall clock, the fixtures would age into the past and the reminder would
      // be dropped as overdue.
      await withClock(Clock.fixed(now), () async {
        container.read(reminderSyncProvider);
        await Future<void>.delayed(Duration.zero);
      });

      expect(service.plans.single.any((r) => r.kind == ReminderKind.eventReminder), isTrue);
    });
  });

  group('buildReminderBody', () {
    final translations = AppTranslations(AppLocale.en);

    ScheduledReminder nudge({int alsoAtRisk = 0}) => ScheduledReminder(
          id: AppConstants.streakNudgeNotificationId,
          eventId: 'habit-1',
          title: 'Read',
          fireAt: soon,
          eventStart: soon,
          minutesBefore: 0,
          kind: ReminderKind.streakAtRisk,
          alsoAtRisk: alsoAtRisk,
        );

    test('a lone nudge does not claim other habits', () {
      expect(
        buildReminderBody(translations, nudge()),
        'Still open today — finish it to keep your streak',
      );
    });

    test('a nudge covering several habits says how many', () {
      expect(
        buildReminderBody(translations, nudge(alsoAtRisk: 2)),
        'Still open today, with 2 more — finish them to keep your streaks',
      );
    });

    test('an event reminder is unaffected by the kind branch', () {
      final reminder = ScheduledReminder(
        id: 1,
        eventId: 'event-1',
        title: 'Read',
        fireAt: soon,
        eventStart: soon.add(const Duration(minutes: 15)),
        minutesBefore: 15,
      );

      expect(buildReminderBody(translations, reminder), contains('15'));
    });
  });
}
