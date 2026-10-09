import 'dart:ui' show Offset;

class AppConstants {
  // Network
  static const String webBaseUrl = 'http://localhost:5000/api/v1';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:5000/api/v1';
  static const int connectTimeoutSeconds = 5;
  static const int receiveTimeoutSeconds = 3;

  /// Key under which a request records the token it was sent with
  /// (`RequestOptions.extra`), so a 401 can be traced back to the session that made
  /// the request. See [AuthInterceptor].
  static const String requestSessionTokenKey = 'sessionToken';

  static const int unauthorizedStatusCode = 401;

  // UI Strings
  static const String appTitle = 'Smart Calendar';
  static const String habitsTitle = 'Habits';
  static const String addHabit = 'Add Habit';
  static const String cancel = 'Cancel';
  static const String add = 'Add';
  static const String habitNameLabel = 'Habit Name';
  static const String categoryLabel = 'Category';
  static const String unscheduledHabitsLabel = 'Unscheduled Habits (Drag to Calendar)';
  static const String noHabitsMessage = 'No habits yet. Tap + to add.';
  static const String noUnscheduledHabitsMessage = 'No habits yet. Go to Habits tab to create one.';
  static const String uncategorized = 'Uncategorized';
  static const String unknown = 'Unknown';
  static const String errorPrefix = 'Error: ';
  
  // Calendar drag-and-drop
  /// Id of the throw-away event used to preview where a dragged habit would land.
  /// [CalendarEventDataSource] keys its preview styling off this exact value.
  static const String hoverPreviewEventId = 'hover_preview';

  /// Length of the event created by dropping a habit onto the calendar.
  static const Duration defaultDroppedEventDuration = Duration(hours: 1);

  /// A drag reports its top-left corner, but the drop should land on the middle of the
  /// dragged card. Half the habit card's size, used to shift the hit test to its centre.
  static const Offset draggedHabitCentreOffset = Offset(70, 35);

  // Event reminders (local notifications)
  /// Offsets, in minutes before the start, that a reminder may be set for.
  /// `0` means "when it starts". An event with an empty list has no reminders,
  /// which is the default for a newly created event.
  ///
  /// Must stay in step with `ReminderOptions.AllowedMinutesBefore` on the server,
  /// which rejects anything outside this set.
  static const List<int> reminderOptionsMinutes = [0, 5, 15, 30, 60];

  /// One reminder per offset is the natural ceiling for a single event.
  static const int maxRemindersPerEvent = 5;

  /// How far ahead reminders are scheduled. Android limits how many alarms one app
  /// may hold, and the event data changes daily, so scheduling further out would
  /// mostly be scheduling things that are about to be rescheduled anyway.
  static const Duration reminderHorizon = Duration(days: 7);

  /// Ceiling on pending reminders across all events; the soonest are kept.
  ///
  /// Higher than it looks necessary because an event may now carry up to
  /// [maxRemindersPerEvent], so a week of a few daily habits multiplies quickly.
  /// Android tolerates a few hundred alarms per app; this stays well inside that.
  static const int maxScheduledReminders = 250;

  /// Android notification channel for event reminders.
  static const String reminderChannelId = 'event_reminders';

  // Streak-at-risk nudge
  /// Local hour from which a day counts as "running out", so an unfinished habit that
  /// has a streak to lose is worth a nudge.
  ///
  /// A fixed hour on purpose. The data for a per-habit time exists (the hour each habit
  /// is usually completed at), but a single hour is what makes the rule explainable.
  ///
  /// It is **not** yet the same decision as roadmap 5.1's day boundary, and the two are
  /// currently made in different clocks: this is the device's local hour, while the
  /// server's streak day is a hardcoded UTC+7 (`StreakCalculator.DefaultDayBoundaryOffset`).
  /// For a user west of UTC+7 the cutoff therefore falls inside what the backend already
  /// counts as the next day. Reconciling them is 5.1's job; until then this constant is
  /// the one place to change the client half.
  static const int streakAtRiskHour = 20;

  /// Base notification id for the evening nudge. A fixed base, unlike event reminders,
  /// which hash theirs from the occurrence: there is one nudge per planned evening
  /// ([streakNudgeEvenings]), at consecutive ids from this base, so re-planning replaces
  /// each evening's nudge rather than stacking a second one.
  ///
  /// Above [eventReminderIdMask], so it cannot be the id a hashed event reminder lands on.
  /// The two are scheduled in one `applyPlan` call with no shared dedupe between them, so
  /// an overlap would mean one silently overwriting the other.
  static const int streakNudgeNotificationId = 0x7FFFFFF0;

  /// How many evenings ahead the nudge is planned, counting the next cutoff as one.
  ///
  /// Two, so a day the app is never opened still gets its nudge: planning only tonight
  /// meant the feature covered exactly the days somebody already used the app, and the
  /// evening after a quiet day is when it matters most. Tomorrow's state is unknowable —
  /// nothing booked for tomorrow can be completed yet — so tomorrow's nudge is scheduled on
  /// the assumption that it will not be, and dropped the moment it is: completing anything
  /// re-plans the whole set.
  ///
  /// **Two is the ceiling, and the limit is the server's.** `StreakCalculator` reports a
  /// streak as alive only while its last completion is today or yesterday, so the
  /// `currentStreak` the client plans from stays true for today and tomorrow and no longer.
  /// A nudge planned further out would fire about a streak that is already broken — "finish
  /// it to keep your streak" for a streak lost two nights ago, which is how the switch gets
  /// turned off. Raising this needs that grace period raised first.
  ///
  /// (Ids also run from [streakNudgeNotificationId] upwards, one per evening, but they are
  /// not what binds: the space below the signed 32-bit ceiling allows 16.)
  static const int streakNudgeEvenings = 2;

  /// Mask applied to hashed event-reminder ids (`ReminderPlanner.reminderId`), keeping
  /// them positive **and** below every fixed notification id above.
  static const int eventReminderIdMask = 0x3FFFFFFF;

  // Routing
  /// Where a signed-in user lands: after login, and when opening the app.
  ///
  /// One constant because it was written in two places — the router's redirect and
  /// the login screen's own `context.go` — and when Home was added only the router
  /// was changed, so logging in still went to the calendar.
  static const String landingRoute = '/home';

  // Events always loaded
  /// The window around now that `eventsProvider` always includes, whatever range
  /// the calendar is showing.
  ///
  /// The provider is shared: the calendar reads it for the range being browsed,
  /// but the reminder scheduler, the Android widgets and the home screen read it for
  /// *now*. It used to fetch only the browsed range, so browsing to December left
  /// all three looking at December — which cancelled every pending reminder — and a
  /// cold start, with no range yet, fetched every event the user had ever had.
  ///
  /// One day back, so an event that started before now and is still running is in
  /// the window.
  static const Duration upcomingWindowBehind = Duration(days: 1);

  /// Must reach at least [reminderHorizon], or the reminder planner loses events at
  /// the far edge of its own horizon. The extra day is margin for that edge.
  static const Duration upcomingWindowAhead = Duration(days: 8);

  /// Days of history in the home screen's activity summary.
  static const int analyticsSummaryDays = 14;

  // Assistant
  /// The assistant's chat, opened over the tabs rather than as a sixth one.
  static const String assistantRoute = '/assistant';

  /// SignalR hub the server pushes a turn's progress on ("looking at your calendar…").
  static const String assistantHubPath = '/assistantHub';
  static const String assistantToolStartedEvent = 'assistant.toolStarted';
  static const String assistantToolFinishedEvent = 'assistant.toolFinished';

  /// How long to wait for a reply. A turn runs the model and its tools inside one
  /// request — several seconds is normal — so the app-wide [receiveTimeoutSeconds]
  /// would fail every turn.
  static const int assistantReceiveTimeoutSeconds = 120;

  /// Longest message the server accepts (`SendAssistantMessageCommandHandler.MaxTextLength`).
  static const int assistantMaxMessageLength = 2000;

  // Magic Numbers
  static const int defaultPomodoroDurationMinutes = 30;
  static const List<int> defaultTargetDays = [1, 2, 3, 4, 5];
  static const double draggableElevation = 4.0;
  static const double borderRadius = 8.0;
}
