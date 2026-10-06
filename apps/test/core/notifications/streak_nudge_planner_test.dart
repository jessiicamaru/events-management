import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/notifications/reminder_planner.dart';
import 'package:habit_tracker/core/notifications/streak_nudge_planner.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';

void main() {
  DateTime at(int hour, {int minute = 0}) => DateTime(2026, 9, 11, hour, minute);

  final habit = HabitModel(
    id: 'habit-1',
    name: 'Read',
    targetDays: const [1, 2, 3, 4, 5],
    currentStreak: 5,
  );

  EventModel event({bool completed = false, int hour = 21}) => EventModel(
        id: 'event-1',
        title: 'Read',
        startTime: at(hour),
        endTime: at(hour).add(const Duration(minutes: 30)),
        habitId: 'habit-1',
        isCompleted: completed,
      );

  List<ScheduledReminder> plan({
    required DateTime now,
    bool enabled = true,
    bool completed = false,
  }) =>
      StreakNudgePlanner.plan(
        events: [event(completed: completed)],
        habits: [habit],
        now: now,
        enabled: enabled,
      );

  test('schedules one nudge at the cutoff, planned hours earlier in the day', () {
    final nudges = plan(now: at(9));

    expect(nudges, hasLength(1));
    final nudge = nudges.single;
    expect(nudge.fireAt, at(AppConstants.streakAtRiskHour));
    expect(nudge.kind, ReminderKind.streakAtRisk);
    expect(nudge.title, 'Read');
    expect(nudge.eventId, habit.id, reason: 'the nudge is about the habit, not one event');
    expect(nudge.id, AppConstants.streakNudgeNotificationId);
  });

  test('schedules nothing once the cutoff has passed', () {
    // Home still shows the card; a notification for a moment gone by is noise.
    expect(plan(now: at(AppConstants.streakAtRiskHour, minute: 1)), isEmpty);
  });

  test('schedules nothing when the habit is already done', () {
    expect(plan(now: at(9), completed: true), isEmpty);
  });

  test('schedules nothing when the user turned nudges off', () {
    expect(plan(now: at(9), enabled: false), isEmpty);
  });

  test('several habits at risk are still one notification', () {
    final nudges = StreakNudgePlanner.plan(
      events: [
        event(),
        EventModel(
          id: 'event-2',
          title: 'Run',
          startTime: at(22),
          endTime: at(22).add(const Duration(minutes: 30)),
          habitId: 'habit-2',
        ),
      ],
      habits: [
        habit,
        HabitModel(id: 'habit-2', name: 'Run', targetDays: const [1], currentStreak: 30),
      ],
      now: at(9),
      enabled: true,
    );

    expect(nudges, hasLength(1));
    expect(nudges.single.title, 'Run', reason: 'the longest streak leads');
    expect(nudges.single.alsoAtRisk, 1,
        reason: 'the body has to say the other one is at stake too');
  });

  test('a lone habit at risk reports no others', () {
    expect(plan(now: at(9)).single.alsoAtRisk, 0);
  });

  test('schedules nothing when the habit was ticked at another slot today', () {
    // One completion secures the calendar day, so the open evening slot is not a streak
    // about to break.
    final nudges = StreakNudgePlanner.plan(
      events: [
        event(hour: 7, completed: true),
        EventModel(
          id: 'event-evening',
          title: 'Read',
          startTime: at(21),
          endTime: at(21).add(const Duration(minutes: 30)),
          habitId: 'habit-1',
        ),
      ],
      habits: [habit],
      now: at(9),
      enabled: true,
    );

    expect(nudges, isEmpty);
  });

  test('the nudge id is outside the space event reminders hash into', () {
    // Both plans go to one applyPlan with no shared dedupe, so an overlap would mean one
    // silently overwriting the other.
    expect(
      AppConstants.streakNudgeNotificationId & AppConstants.eventReminderIdMask,
      isNot(AppConstants.streakNudgeNotificationId),
    );

    for (var i = 0; i < 20000; i++) {
      final id = ReminderPlanner.reminderId('evt-$i', at(7), 15);
      expect(id, lessThanOrEqualTo(AppConstants.eventReminderIdMask));
      expect(id, isNot(AppConstants.streakNudgeNotificationId));
      expect(id, isNonNegative);
    }
  });

  test('an event reminder keeps its own kind, so the body text cannot be swapped', () {
    final withReminder = EventModel(
      id: 'event-1',
      title: 'Read',
      startTime: at(21),
      endTime: at(21).add(const Duration(minutes: 30)),
      habitId: 'habit-1',
      reminderMinutesBefore: const [15],
    );

    final reminders = ReminderPlanner.plan(events: [withReminder], now: at(9));

    expect(reminders, isNotEmpty);
    expect(reminders.every((r) => r.kind == ReminderKind.eventReminder), isTrue);
  });
}
