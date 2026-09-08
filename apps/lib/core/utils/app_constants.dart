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
  
  // Magic Numbers
  static const int defaultPomodoroDurationMinutes = 30;
  static const List<int> defaultTargetDays = [1, 2, 3, 4, 5];
  static const double draggableElevation = 4.0;
  static const double borderRadius = 8.0;
}
