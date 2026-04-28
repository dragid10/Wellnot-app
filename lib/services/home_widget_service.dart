// services/home_widget_service.dart: Bridges app data to native home screen widgets
//
// Queries the database for today's entries, serializes them to a JSON array
// matching the calendar entry list format (time, mood, symptoms), and pushes
// to native widgets via the home_widget package.
//
// Cross-ref:
//   - Widget constants: constants/home_widget.dart
//   - Database queries: services/database.dart
//   - Called from: main.dart (init), app.dart (on entry changes)
//   - Android widgets: android/app/src/main/kotlin/.../glance/
//   - Calendar entry list format: screens/calendar_screen.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../constants/home_widget.dart' as widget_constants;
import 'database.dart';

/// Manages data synchronization between the Flutter app and native home
/// screen widgets on both Android and iOS.
class HomeWidgetService {
  /// Initializes the home_widget package. Must be called once during app
  /// startup, before any widget data updates.
  static Future<void> initialize() async {
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(widget_constants.appGroupId);
    }
  }

  /// Queries today's entries and pushes them to native widgets.
  /// Call this after every entry save, delete, or clear operation.
  static Future<void> updateWidgetData(AppDatabase db) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(
        const Duration(hours: 23, minutes: 59, seconds: 59),
      );

      final entries = await db.getEntriesForDateRange(todayStart, todayEnd);

      // Sort chronologically, matching the calendar entry list order.
      entries.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      // Serialize each entry to match the calendar list format:
      // time | mood - symptoms (with ID for deep linking to detail screen)
      final timeFormatter = DateFormat.jm();
      final serialized = entries.map((e) {
        final symptoms = e.symptoms.map((s) => s.name).join(', ');
        return {
          'id': e.id,
          'time': timeFormatter.format(e.dateTime),
          'mood': e.mood,
          'symptoms': symptoms,
        };
      }).toList();

      await HomeWidget.saveWidgetData(
        widget_constants.widgetKeyTodayEntries,
        jsonEncode(serialized),
      );

      // Store the date so native widgets can detect stale data after midnight.
      final dateString = DateFormat('yyyy-MM-dd').format(now);
      await HomeWidget.saveWidgetData(
        widget_constants.widgetKeyTodayDate,
        dateString,
      );

      await _updateAllWidgets();
    } catch (e) {
      debugPrint('HomeWidgetService.updateWidgetData failed: $e');
    }
  }

  /// Notifies all registered native widgets to refresh.
  static Future<void> _updateAllWidgets() async {
    if (Platform.isAndroid) {
      await HomeWidget.updateWidget(
        qualifiedAndroidName: widget_constants.androidTodayMoodsReceiver,
      );
    } else if (Platform.isIOS) {
      await HomeWidget.updateWidget(
        iOSName: widget_constants.iosTodayMoodsWidgetKind,
      );
    }
  }
}
