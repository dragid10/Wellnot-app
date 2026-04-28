// calendar_settings_screen_test.dart: Widget tests for the Calendar sub-page
//
// Cross-ref:
//   - Screen under test: lib/screens/settings/calendar_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:symptom_tracker_app/constants/defaults.dart';
import 'package:symptom_tracker_app/screens/settings/calendar_settings_screen.dart';
import 'package:symptom_tracker_app/services/preferences_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'As a user, I expect to see the Calendar screen with the week start day setting',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CalendarSettingsScreen()),
    );

    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Week starts on'), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect the week start day to default to "System" when I have not changed it',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CalendarSettingsScreen()),
    );

    final weekStartTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Week starts on'),
    );
    final subtitleWidget = weekStartTile.subtitle as Text;
    expect(subtitleWidget.data, 'System');
  });

  testWidgets(
      'As a user, I expect a dialog with all day options when I tap the week start day setting',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CalendarSettingsScreen()),
    );

    await tester.tap(find.text('Week starts on'));
    await tester.pump();

    expect(find.text('Sunday'), findsOneWidget);
    expect(find.text('Monday'), findsOneWidget);
    expect(find.text('Tuesday'), findsOneWidget);
    expect(find.text('Wednesday'), findsOneWidget);
    expect(find.text('Thursday'), findsOneWidget);
    expect(find.text('Friday'), findsOneWidget);
    expect(find.text('Saturday'), findsOneWidget);
    expect(
        find.widgetWithText(RadioListTile<String>, 'System'), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect the week start day subtitle to update when I select Monday from the dialog',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CalendarSettingsScreen()),
    );

    await tester.tap(find.text('Week starts on'));
    await tester.pump();

    await tester.tap(find.text('Monday'));
    // saveCalendarStartDay is async — let it complete.
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    final weekStartTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Week starts on'),
    );
    final subtitleWidget = weekStartTile.subtitle as Text;
    expect(subtitleWidget.data, 'Monday');

    // Reset.
    PreferencesService.calendarStartDayNotifier.value = defaultCalendarStartDay;
  });
}
