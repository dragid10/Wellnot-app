// platform_service.dart: Platform channel helpers for native OS queries.
//
// Provides access to OS-level settings that Flutter doesn't expose directly,
// such as the user's preferred first day of the week.
//
// Uses a static-methods-only pattern to match the other stateless services
// (ChangelogService, ItemPreferencesService, ExportService).
//
// Cross-ref:
//   - Android implementation: android/app/.../MainActivity.kt
//   - iOS implementation: ios/Runner/AppDelegate.swift
//   - Consumed by: app.dart (systemStartDayNotifier)

import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';

/// Provides access to OS-level settings via platform channels.
///
/// All methods are static — no instance state is needed since the underlying
/// [MethodChannel] is a lightweight proxy to native code.
class PlatformService {
  /// Platform channel for querying OS-level settings.
  static const _channel = MethodChannel('com.symptom_tracker_app/platform');

  /// Reads the system's "first day of week" preference from the OS.
  ///
  /// Returns the appropriate [StartingDayOfWeek] based on the value from:
  /// - Android: `java.util.Calendar.getInstance().getFirstDayOfWeek()`
  /// - iOS: `Calendar.current.firstWeekday`
  ///
  /// Both APIs return 1 = Sunday, 2 = Monday, ..., 7 = Saturday.
  /// Falls back to [StartingDayOfWeek.sunday] if the platform call fails.
  static Future<StartingDayOfWeek> getSystemFirstDayOfWeek() async {
    try {
      final int dayIndex =
          await _channel.invokeMethod<int>('getFirstDayOfWeek') ?? 1;
      return _dayIndexToStartingDay(dayIndex);
    } on PlatformException {
      return StartingDayOfWeek.sunday;
    } on MissingPluginException {
      return StartingDayOfWeek.sunday;
    }
  }

  /// Converts a platform day index (1 = Sunday ... 7 = Saturday) to
  /// a [StartingDayOfWeek] enum value.
  static StartingDayOfWeek _dayIndexToStartingDay(int index) {
    switch (index) {
      case 1:
        return StartingDayOfWeek.sunday;
      case 2:
        return StartingDayOfWeek.monday;
      case 3:
        return StartingDayOfWeek.tuesday;
      case 4:
        return StartingDayOfWeek.wednesday;
      case 5:
        return StartingDayOfWeek.thursday;
      case 6:
        return StartingDayOfWeek.friday;
      case 7:
        return StartingDayOfWeek.saturday;
      default:
        return StartingDayOfWeek.sunday;
    }
  }
}
