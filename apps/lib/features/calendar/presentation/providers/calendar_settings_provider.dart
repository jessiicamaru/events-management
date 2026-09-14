import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'calendar_settings_provider.g.dart';

class CalendarSettings {
  final int visibleStartHour;
  final int visibleEndHour;

  const CalendarSettings({
    required this.visibleStartHour,
    required this.visibleEndHour,
  });

  CalendarSettings copyWith({
    int? visibleStartHour,
    int? visibleEndHour,
  }) {
    return CalendarSettings(
      visibleStartHour: visibleStartHour ?? this.visibleStartHour,
      visibleEndHour: visibleEndHour ?? this.visibleEndHour,
    );
  }
}

@riverpod
class CalendarSettingsNotifier extends _$CalendarSettingsNotifier {
  static const _startHourKey = 'calendar_start_hour';
  static const _endHourKey = 'calendar_end_hour';

  @override
  CalendarSettings build() {
    _loadSettings(); // Sync-ish load or defaults first
    return const CalendarSettings(visibleStartHour: 6, visibleEndHour: 24);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final startHour = prefs.getInt(_startHourKey) ?? 6;
    final endHour = prefs.getInt(_endHourKey) ?? 24;
    Future.microtask(() {
      state = CalendarSettings(visibleStartHour: startHour, visibleEndHour: endHour);
    });
  }

  Future<void> updateSettings({int? startHour, int? endHour}) async {
    final prefs = await SharedPreferences.getInstance();
    int newStart = startHour ?? state.visibleStartHour;
    int newEnd = endHour ?? state.visibleEndHour;

    // Validate bounds
    if (newStart < 0) newStart = 0;
    if (newEnd > 24) newEnd = 24;
    if (newStart >= newEnd) newStart = newEnd - 1; // Ensure valid range

    await prefs.setInt(_startHourKey, newStart);
    await prefs.setInt(_endHourKey, newEnd);

    state = state.copyWith(visibleStartHour: newStart, visibleEndHour: newEnd);
  }
}
