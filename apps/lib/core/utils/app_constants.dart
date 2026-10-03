import 'dart:ui' show Offset;

class AppConstants {
  // Network
  static const String webBaseUrl = 'http://localhost:5000/api/v1';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:5000/api/v1';
  static const int connectTimeoutSeconds = 5;
  static const int receiveTimeoutSeconds = 3;

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
  /// Default gap between the reminder and the event starting.
  static const Duration defaultReminderLeadTime = Duration(minutes: 10);

  /// Lead times offered in settings.
  static const List<Duration> reminderLeadTimeOptions = [
    Duration(minutes: 0),
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
  ];

  /// How far ahead reminders are scheduled. Android limits how many alarms one app
  /// may hold, and the event data changes daily, so scheduling further out would
  /// mostly be scheduling things that are about to be rescheduled anyway.
  static const Duration reminderHorizon = Duration(days: 7);

  /// Ceiling on pending reminders. Android starts rejecting alarms somewhere above
  /// this; the soonest ones are kept.
  static const int maxScheduledReminders = 64;

  /// Android notification channel for event reminders.
  static const String reminderChannelId = 'event_reminders';

  // Magic Numbers
  static const int defaultPomodoroDurationMinutes = 30;
  static const List<int> defaultTargetDays = [1, 2, 3, 4, 5];
  static const double draggableElevation = 4.0;
  static const double borderRadius = 8.0;
}
