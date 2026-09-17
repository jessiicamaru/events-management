import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:habit_tracker/core/providers/shared_preferences_provider.dart';
import '../../domain/models/calendar_event_style.dart';

part 'calendar_settings_provider.g.dart';

class CalendarSettings {
  final int visibleStartHour;
  final int visibleEndHour;
  final CalendarEventStyle eventStyle;

  const CalendarSettings({
    required this.visibleStartHour,
    required this.visibleEndHour,
    this.eventStyle = CalendarEventStyle.colored,
  });

  CalendarSettings copyWith({
    int? visibleStartHour,
    int? visibleEndHour,
    CalendarEventStyle? eventStyle,
  }) {
    return CalendarSettings(
      visibleStartHour: visibleStartHour ?? this.visibleStartHour,
      visibleEndHour: visibleEndHour ?? this.visibleEndHour,
      eventStyle: eventStyle ?? this.eventStyle,
    );
  }
}

@riverpod
class CalendarSettingsNotifier extends _$CalendarSettingsNotifier {
  static const _startHourKey = 'calendar_start_hour';
  static const _endHourKey = 'calendar_end_hour';
  static const _eventStyleKey = 'calendar_event_style';

  bool _disposed = false;

  @override
  CalendarSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final startHour = prefs.getInt(_startHourKey) ?? 6;
    final endHour = prefs.getInt(_endHourKey) ?? 24;
    
    final styleIndex = prefs.getInt(_eventStyleKey) ?? CalendarEventStyle.colored.index;
    final eventStyle = CalendarEventStyle.values.elementAtOrNull(styleIndex) ?? CalendarEventStyle.colored;

    return CalendarSettings(
      visibleStartHour: startHour, 
      visibleEndHour: endHour,
      eventStyle: eventStyle,
    );
  }

  Future<void> updateSettings({int? startHour, int? endHour, CalendarEventStyle? eventStyle}) async {
    final prefs = ref.read(sharedPreferencesProvider);
    int newStart = startHour ?? state.visibleStartHour;
    int newEnd = endHour ?? state.visibleEndHour;
    CalendarEventStyle newStyle = eventStyle ?? state.eventStyle;

    // Validate bounds
    if (newStart < 0) newStart = 0;
    if (newEnd > 24) newEnd = 24;
    if (newStart >= newEnd) newStart = newEnd - 1; // Ensure valid range

    await prefs.setInt(_startHourKey, newStart);
    await prefs.setInt(_endHourKey, newEnd);
    await prefs.setInt(_eventStyleKey, newStyle.index);

    state = state.copyWith(
      visibleStartHour: newStart, 
      visibleEndHour: newEnd,
      eventStyle: newStyle,
    );
  }
}
