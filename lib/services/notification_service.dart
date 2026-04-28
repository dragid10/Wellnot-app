// notification_service.dart: Local notification service for reminders
//
// Handles initialization, platform-specific permission requests, scheduling
// daily reminder notifications at a user-chosen time, and persisting
// notification settings via SharedPreferences.
//
// Cross-ref:
//   - Called from main.dart during app bootstrap (applySettings)
//   - Settings UI: screens/manage_items_screen.dart
//   - Constants/pref keys: constants/defaults.dart
//   - Uses a MethodChannel to communicate with native Android code in
//     MainActivity.kt for exact alarm permission checks
//   - Package ID: dev.alexo.symptom_tracker_app

import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../constants/defaults.dart';

/// Immutable snapshot of the user's notification preferences.
///
/// Replaces the raw `Map<String, dynamic>` that [NotificationService.loadSettings]
/// previously returned, providing compile-time type safety and eliminating
/// stringly-typed key lookups.
class NotificationSettings {
  /// Whether the daily reminder notification is enabled.
  final bool enabled;

  /// Hour (0–23) for the daily reminder.
  final int hour;

  /// Minute (0–59) for the daily reminder.
  final int minute;

  const NotificationSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });
}

/// Service responsible for local push notifications.
///
/// Lifecycle (called in order from main.dart):
/// 1. [init] — register platform-specific notification settings + init timezones
/// 2. [requestPermissions] — prompt the user for notification + alarm permissions
/// 3. [applySettings] — load persisted settings and schedule/cancel accordingly
///
/// Settings are stored in SharedPreferences under the keys defined in
/// `constants/defaults.dart` (prefKeyNotificationsEnabled, etc.).
///
/// This class is a singleton — use [NotificationService()] everywhere.
/// The single instance ensures [init] is only called once (in main.dart)
/// and all callers share the same initialized plugin + timezone state.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Callback invoked when the user taps a notification. The [payload]
  /// string identifies which notification was tapped (e.g., 'open_new_entry').
  /// Set by [init] from main.dart.
  void Function(String? payload)? onNotificationTap;

  /// MethodChannel for checking exact alarm permissions on Android 12+.
  ///
  /// The native side is implemented in MainActivity.kt and calls
  /// `AlarmManager.canScheduleExactAlarms()`.
  static const MethodChannel _exactAlarmChannel =
      MethodChannel('com.symptom_tracker_app/exact_alarm');

  /// Checks whether the app has permission to schedule exact alarms.
  ///
  /// Returns `true` on non-Android platforms (iOS handles this differently).
  /// On Android, invokes the native MethodChannel; returns `false` if the
  /// channel call fails (e.g., on older Android versions without the API).
  Future<bool> canScheduleExactAlarms() async {
    if (Platform.isAndroid) {
      try {
        final bool granted =
            await _exactAlarmChannel.invokeMethod('canScheduleExactAlarms');
        return granted;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  /// Opens the Android system settings page where the user can grant the
  /// `SCHEDULE_EXACT_ALARM` permission. No-ops on non-Android platforms.
  Future<void> openExactAlarmSettings() async {
    if (Platform.isAndroid) {
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        package: 'dev.alexo.symptom_tracker_app',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    }
  }

  /// Initializes platform-specific notification settings and timezone data.
  ///
  /// Must be called before [requestPermissions] or [applySettings].
  /// Uses the default app icon (`@mipmap/ic_launcher`) for Android notifications.
  Future<void> init() async {
    // Initialize timezone database and set the local location to the device's
    // actual timezone. Without setLocalLocation, tz.local defaults to UTC and
    // notifications fire at the wrong time.
    tz.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onNotificationTap?.call(response.payload);
      },
    );
  }

  /// Requests notification permissions from the user.
  ///
  /// Returns `true` if all required permissions were granted, `false` if
  /// the user denied any of them.
  ///
  /// - **iOS:** Requests alert, badge, and sound permissions.
  /// - **Android:** Requests POST_NOTIFICATIONS (Android 13+), then checks
  ///   and requests exact alarm permission (Android 12+).
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final granted = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    } else if (Platform.isAndroid) {
      final androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final notificationsGranted =
          await androidPlugin?.requestNotificationsPermission();
      if (notificationsGranted != true) return false;

      // Exact alarms require a separate permission on Android 12+.
      final canSchedule = await canScheduleExactAlarms();
      if (!canSchedule) {
        await openExactAlarmSettings();
        // Re-check after the user returns from system settings.
        final nowCanSchedule = await canScheduleExactAlarms();
        if (!nowCanSchedule) return false;
      }
      return true;
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Settings persistence (SharedPreferences)
  // ---------------------------------------------------------------------------

  /// Loads notification settings from SharedPreferences.
  ///
  /// Returns a typed [NotificationSettings] with compile-time safety.
  /// Falls back to defaults from `constants/defaults.dart` if no values are
  /// stored (i.e., first launch).
  Future<NotificationSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationSettings(
      enabled: prefs.getBool(prefKeyNotificationsEnabled) ??
          defaultNotificationsEnabled,
      hour: prefs.getInt(prefKeyNotificationHour) ?? defaultNotificationHour,
      minute:
          prefs.getInt(prefKeyNotificationMinute) ?? defaultNotificationMinute,
    );
  }

  /// Persists notification settings to SharedPreferences.
  ///
  /// Call this whenever the user changes their notification preferences
  /// in the settings UI, then call [applySettings] to reschedule/cancel.
  Future<void> saveSettings({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyNotificationsEnabled, enabled);
    await prefs.setInt(prefKeyNotificationHour, hour);
    await prefs.setInt(prefKeyNotificationMinute, minute);
  }

  // ---------------------------------------------------------------------------
  // Persistent notification settings
  // ---------------------------------------------------------------------------

  /// Loads the persistent notification enabled state from SharedPreferences.
  Future<bool> loadPersistentEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefKeyPersistentNotification) ??
        defaultPersistentNotificationEnabled;
  }

  /// Persists the persistent notification enabled state.
  Future<void> savePersistentEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyPersistentNotification, enabled);
  }

  /// Notification ID for the persistent "quick add" notification.
  static const int _persistentNotificationId = 1;

  /// Shows a non-dismissible notification via a foreground service.
  ///
  /// On Android 14+, only foreground-service-bound notifications are truly
  /// non-swipeable. Uses `startForegroundService()` from the Android-specific
  /// plugin API. On non-Android platforms, falls back to a regular `show()`.
  Future<void> showPersistentNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'persistent_channel',
      'Quick Add',
      channelDescription: 'Persistent notification to quickly log symptoms',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
    );

    if (Platform.isAndroid) {
      final androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.startForegroundService(
        id: _persistentNotificationId,
        title: 'Wellnot',
        body: 'Tap to log your symptoms',
        notificationDetails: androidDetails,
        payload: 'open_new_entry',
        foregroundServiceTypes: {
          AndroidServiceForegroundType.foregroundServiceTypeSpecialUse
        },
        // START_NOT_STICKY: don't let Android auto-restart the service after
        // a kill. The plugin's ForegroundService.onStartCommand dereferences
        // Intent extras without a null check and crashes when the OS
        // reschedules with a null intent (low memory, "optimize all apps",
        // reboot). applySettings() re-shows this on every app launch.
        // See flutter_local_notifications#2298.
        startType: AndroidServiceStartType.startNotSticky,
      );
    } else {
      const details = NotificationDetails(android: androidDetails);
      await flutterLocalNotificationsPlugin.show(
        id: _persistentNotificationId,
        title: 'Wellnot',
        body: 'Tap to log your symptoms',
        notificationDetails: details,
        payload: 'open_new_entry',
      );
    }
  }

  /// Cancels the persistent notification and stops the foreground service.
  Future<void> cancelPersistentNotification() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.stopForegroundService();
    } else {
      await flutterLocalNotificationsPlugin.cancel(
          id: _persistentNotificationId);
    }
  }

  /// Loads the persistent notification preference and shows or cancels it.
  Future<void> applyPersistentNotification() async {
    final enabled = await loadPersistentEnabled();
    if (enabled) {
      await showPersistentNotification();
    } else {
      await cancelPersistentNotification();
    }
  }

  // ---------------------------------------------------------------------------
  // Scheduling
  // ---------------------------------------------------------------------------

  /// Computes the next [tz.TZDateTime] for the given [hour] and [minute]
  /// in the device's local timezone.
  ///
  /// If that time has already passed today, it returns tomorrow at the same
  /// time. This ensures `zonedSchedule` always receives a future date.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Schedules a daily notification at the specified [hour] and [minute].
  ///
  /// Uses `zonedSchedule` with `matchDateTimeComponents: DateTimeComponents.time`
  /// so the notification repeats daily at the same local time, correctly
  /// handling DST transitions. The notification ID is `0` (only one reminder
  /// is active at a time).
  Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
  }) async {
    // Cancel any existing notification before scheduling a new one so the
    // old schedule doesn't linger if the time changed.
    await flutterLocalNotificationsPlugin.cancel(id: 0);

    // Android notification channel configuration.
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('daily_reminder_channel', 'Daily Reminders',
            channelDescription: 'Daily reminder to log symptoms',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');

    // iOS notification configuration — must explicitly enable alert,
    // badge, and sound for the notification to appear when the app
    // is in the background or terminated.
    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    final scheduledDate = _nextInstanceOfTime(hour, minute);
    debugPrint(
        'Scheduling notification for $scheduledDate (tz.local=${tz.local.name})');

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: 0,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: 'Wellnot Reminder',
      body: 'Don\'t forget to log your symptoms for today!',
      payload: 'daily_reminder',
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Verify the notification was scheduled.
    final pending =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    debugPrint('Pending notifications: ${pending.length}');
    for (final n in pending) {
      debugPrint('  id=${n.id} title=${n.title}');
    }
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Loads persisted settings and schedules or cancels notifications accordingly.
  ///
  /// Convenience method called from main.dart during bootstrap and from
  /// ManageItemsScreen after the user changes notification preferences.
  Future<void> applySettings() async {
    final settings = await loadSettings();

    if (settings.enabled) {
      await scheduleDailyNotification(
          hour: settings.hour, minute: settings.minute);
    } else {
      await cancelNotifications();
    }
  }
}
