import 'package:habit_tracker/core/providers/shared_preferences_provider.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_settings_provider.g.dart';

/// The user's reminder preferences. Persisted locally — reminders are a device
/// concern, so there is nothing to sync to the server.
class ReminderSettings {
  final bool enabled;

  /// How long before an event the reminder fires.
  final Duration leadTime;

  const ReminderSettings({required this.enabled, required this.leadTime});

  ReminderSettings copyWith({bool? enabled, Duration? leadTime}) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        leadTime: leadTime ?? this.leadTime,
      );

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      other.leadTime == leadTime;

  @override
  int get hashCode => Object.hash(enabled, leadTime);
}

@riverpod
class ReminderSettingsNotifier extends _$ReminderSettingsNotifier {
  static const _enabledKey = 'settings_reminders_enabled';
  static const _leadMinutesKey = 'settings_reminders_lead_minutes';

  @override
  ReminderSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);

    // Off by default: scheduling notifications the user never asked for is the kind of
    // thing that gets an app uninstalled.
    final enabled = prefs.getBool(_enabledKey) ?? false;

    final leadMinutes =
        prefs.getInt(_leadMinutesKey) ??
        AppConstants.defaultReminderLeadTime.inMinutes;

    return ReminderSettings(
      enabled: enabled,
      leadTime: Duration(minutes: leadMinutes),
    );
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    await ref.read(sharedPreferencesProvider).setBool(_enabledKey, enabled);
  }

  Future<void> setLeadTime(Duration leadTime) async {
    state = state.copyWith(leadTime: leadTime);
    await ref
        .read(sharedPreferencesProvider)
        .setInt(_leadMinutesKey, leadTime.inMinutes);
  }
}
