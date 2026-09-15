import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/features/calendar/presentation/providers/calendar_settings_provider.dart';
import 'package:habit_tracker/features/calendar/domain/models/calendar_event_style.dart';
import 'package:habit_tracker/core/providers/shared_preferences_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer makeProviderContainer(SharedPreferences prefs) {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('CalendarSettingsNotifier initializes with default values', () async {
    final prefs = await SharedPreferences.getInstance();
    final container = makeProviderContainer(prefs);
    final settings = container.read(calendarSettingsProvider);
    
    // Default values are 6 and 24 and EventStyle.colored
    expect(settings.visibleStartHour, 6);
    expect(settings.visibleEndHour, 24);
    expect(settings.eventStyle, CalendarEventStyle.colored);
  });

  test('CalendarSettingsNotifier updates values and saves to SharedPreferences', () async {
    final prefs = await SharedPreferences.getInstance();
    final container = makeProviderContainer(prefs);
    
    await container.read(calendarSettingsProvider.notifier).updateSettings(
      startHour: 8, 
      endHour: 20, 
      eventStyle: CalendarEventStyle.mixed,
    );
    
    final settings = container.read(calendarSettingsProvider);
    expect(settings.visibleStartHour, 8);
    expect(settings.visibleEndHour, 20);
    expect(settings.eventStyle, CalendarEventStyle.mixed);

    expect(prefs.getInt('calendar_start_hour'), 8);
    expect(prefs.getInt('calendar_end_hour'), 20);
    expect(prefs.getInt('calendar_event_style'), CalendarEventStyle.mixed.index);
  });

  test('CalendarSettingsNotifier ensures valid hour ranges', () async {
    final prefs = await SharedPreferences.getInstance();
    final container = makeProviderContainer(prefs);
    
    await container.read(calendarSettingsProvider.notifier).updateSettings(startHour: 22, endHour: 10);
    
    final settings = container.read(calendarSettingsProvider);
    // startHour should be constrained to endHour - 1
    expect(settings.visibleStartHour, 9);
    expect(settings.visibleEndHour, 10);
  });
}
