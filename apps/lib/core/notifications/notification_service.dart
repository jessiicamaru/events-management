import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:habit_tracker/core/notifications/reminder_planner.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Whether the OS will actually deliver what we schedule.
class NotificationPermissionStatus {
  /// The user has allowed notifications at all (Android 13+ asks explicitly).
  final bool notificationsAllowed;

  /// The OS will honour an exact time. When false, reminders still arrive but the
  /// system may batch them and they can drift by many minutes.
  final bool exactAlarmsAllowed;

  const NotificationPermissionStatus({
    required this.notificationsAllowed,
    required this.exactAlarmsAllowed,
  });

  static const denied = NotificationPermissionStatus(
    notificationsAllowed: false,
    exactAlarmsAllowed: false,
  );
}

/// Carries out a [ReminderPlanner] plan against the OS.
///
/// Deliberately thin: it holds no decisions about *whether* a reminder should exist,
/// only how to post one. Everything testable lives in [ReminderPlanner]; this talks to
/// a platform channel and so cannot be meaningfully unit-tested.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialised = false;

  /// Loads the timezone database and registers the notification channel.
  ///
  /// Safe to call more than once. Must run before [applyPlan]: `zonedSchedule` needs a
  /// real timezone, and using the device's own means a reminder stays attached to the
  /// wall-clock time the user chose even if they travel.
  Future<void> initialise() async {
    if (_initialised) return;

    tz_data.initializeTimeZones();

    try {
      final deviceTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceTimezone.identifier));
    } catch (error) {
      // An unknown zone name would otherwise make every schedule call throw. UTC is
      // wrong for the user but keeps the feature working rather than crashing.
      debugPrint('NotificationService: could not resolve device timezone: $error');
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Permission is requested explicitly in requestPermissions() instead, so the
          // prompt appears when the user turns reminders on rather than at first launch.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    await _createAndroidChannel();

    _initialised = true;
  }

  Future<void> _createAndroidChannel() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.reminderChannelId,
        'Event reminders',
        description: 'Reminds you shortly before a scheduled event starts.',
        importance: Importance.high,
      ),
    );
  }

  /// Asks for whatever the platform requires, and reports what was granted.
  ///
  /// Call this from a user action (turning reminders on), not at startup — an
  /// unexplained permission prompt on first launch gets denied.
  Future<NotificationPermissionStatus> requestPermissions() async {
    await initialise();

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) return NotificationPermissionStatus.denied;

      // Android 13+ (API 33). Returns true without prompting below that.
      final notificationsAllowed =
          await android.requestNotificationsPermission() ?? false;

      // Android 12+ (API 31). Not fatal if refused — we fall back to inexact.
      var exactAllowed = await android.canScheduleExactNotifications() ?? false;
      if (!exactAllowed) {
        exactAllowed = await android.requestExactAlarmsPermission() ?? false;
      }

      return NotificationPermissionStatus(
        notificationsAllowed: notificationsAllowed,
        exactAlarmsAllowed: exactAllowed,
      );
    }

    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted =
          await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;

      // iOS has no exact-alarm concept; a granted notification is delivered on time.
      return NotificationPermissionStatus(
        notificationsAllowed: granted,
        exactAlarmsAllowed: granted,
      );
    }

    return NotificationPermissionStatus.denied;
  }

  /// Current status without prompting, for showing state in settings.
  Future<NotificationPermissionStatus> currentStatus() async {
    await initialise();

    if (!Platform.isAndroid) return NotificationPermissionStatus.denied;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return NotificationPermissionStatus.denied;

    return NotificationPermissionStatus(
      notificationsAllowed: await android.areNotificationsEnabled() ?? false,
      exactAlarmsAllowed: await android.canScheduleExactNotifications() ?? false,
    );
  }

  /// Replaces every pending reminder with [reminders].
  ///
  /// Cancel-then-reschedule rather than diffing: the plan is cheap to rebuild, and a
  /// diff would have to track which events were edited or deleted elsewhere (Google
  /// Calendar sync changes them behind the app's back). Wholesale replacement cannot
  /// leave a reminder for an event that no longer exists.
  ///
  /// [bodyBuilder] supplies the notification text. It is injected rather than built
  /// here so the copy stays in the translation map — this service has no access to the
  /// user's locale and should not own user-facing strings.
  Future<void> applyPlan(
    List<ScheduledReminder> reminders, {
    required String Function(ScheduledReminder) bodyBuilder,
  }) async {
    await initialise();

    await _plugin.cancelAll();

    if (reminders.isEmpty) return;

    final scheduleMode = await _resolveScheduleMode();

    for (final reminder in reminders) {
      try {
        await _plugin.zonedSchedule(
          id: reminder.id,
          title: reminder.title,
          body: bodyBuilder(reminder),
          scheduledDate: tz.TZDateTime.from(reminder.fireAt, tz.local),
          notificationDetails: _details(),
          androidScheduleMode: scheduleMode,
          payload: reminder.eventId,
        );
      } catch (error) {
        // One bad reminder must not stop the rest. Most likely causes are the alarm
        // cap and a revoked exact-alarm permission.
        debugPrint(
          'NotificationService: failed to schedule ${reminder.id}: $error',
        );
      }
    }
  }

  /// Clears every pending reminder, for when the user turns the feature off.
  Future<void> cancelAll() async {
    await initialise();
    await _plugin.cancelAll();
  }

  /// Posts a notification immediately so the user can confirm the setup works.
  Future<void> showTestNotification({
    required String title,
    required String body,
  }) async {
    await initialise();

    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: _details(),
    );
  }

  /// How many reminders the OS is currently holding. Useful for diagnostics.
  Future<int> pendingCount() async {
    await initialise();
    final pending = await _plugin.pendingNotificationRequests();

    return pending.length;
  }

  Future<AndroidScheduleMode> _resolveScheduleMode() async {
    if (!Platform.isAndroid) return AndroidScheduleMode.exactAllowWhileIdle;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final canBeExact = await android?.canScheduleExactNotifications() ?? false;

    // Without the permission, exact modes throw. Inexact still delivers — just not
    // punctually — which is better than no reminder at all.
    return canBeExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  NotificationDetails _details() => const NotificationDetails(
    android: AndroidNotificationDetails(
      AppConstants.reminderChannelId,
      'Event reminders',
      channelDescription:
          'Reminds you shortly before a scheduled event starts.',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );
}
