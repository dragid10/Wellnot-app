// reminders_settings_screen_test.dart: Widget tests for the Reminders sub-page
//
// Cross-ref:
//   - Screen under test: lib/screens/settings/reminders_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:symptom_tracker_app/screens/settings/reminders_settings_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Helper to pump RemindersSettingsScreen with async load.
  Future<void> pumpReminders(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RemindersSettingsScreen()),
    );
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }

  testWidgets('As a user, I expect to see the Reminders screen title',
      (tester) async {
    await pumpReminders(tester);
    expect(find.text('Reminders'), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect the daily reminder to be disabled by default so notifications require opt-in',
      (tester) async {
    await pumpReminders(tester);

    final dailySwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Daily Reminder'),
    );
    expect(dailySwitch.value, isFalse);
  });

  testWidgets(
      'As a user, I expect to see the reminder time defaulting to 9:00 AM',
      (tester) async {
    await pumpReminders(tester);

    expect(find.text('Reminder Time'), findsOneWidget);
    expect(find.textContaining('9:00'), findsOneWidget);
    expect(find.textContaining('AM'), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect the Quick Add Notification toggle to be visible and disabled by default',
      (tester) async {
    await pumpReminders(tester);

    expect(find.text('Quick Add Notification'), findsOneWidget);
    final persistentSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Quick Add Notification'),
    );
    expect(persistentSwitch.value, isFalse);
  });
}
