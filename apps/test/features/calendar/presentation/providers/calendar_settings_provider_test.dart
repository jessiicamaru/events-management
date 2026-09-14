import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/features/calendar/presentation/providers/calendar_settings_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer makeProviderContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('CalendarSettingsNotifier initializes with default values', () async {
    final container = makeProviderContainer();
    final settings = container.read(calendarSettingsProvider);
    
    // Default values are 6 and 24
    expect(settings.visibleStartHour, 6);
    expect(settings.visibleEndHour, 24);
  });

  test('CalendarSettingsNotifier updates values and saves to SharedPreferences', () async {
    final container = makeProviderContainer();
    
    await container.read(calendarSettingsProvider.notifier).updateSettings(startHour: 8, endHour: 20);
    
    final settings = container.read(calendarSettingsProvider);
    expect(settings.visibleStartHour, 8);
    expect(settings.visibleEndHour, 20);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('calendar_start_hour'), 8);
    expect(prefs.getInt('calendar_end_hour'), 20);
  });

  test('CalendarSettingsNotifier ensures valid hour ranges', () async {
    final container = makeProviderContainer();
    
    await container.read(calendarSettingsProvider.notifier).updateSettings(startHour: 22, endHour: 10);
    
    final settings = container.read(calendarSettingsProvider);
    // startHour should be constrained to endHour - 1
    expect(settings.visibleStartHour, 9);
    expect(settings.visibleEndHour, 10);
  });
}
