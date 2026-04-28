// display_settings_screen_test.dart: Widget tests for the Display sub-page
//
// Cross-ref:
//   - Screen under test: lib/screens/settings/display_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symptom_tracker_app/screens/settings/display_settings_screen.dart';

void main() {
  testWidgets(
      'As a user, I expect to see the Display screen with tag and note preview toggles',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DisplaySettingsScreen()),
    );

    expect(find.text('Display'), findsOneWidget);
    expect(find.text('Show tag preview'), findsOneWidget);
    expect(find.text('Show note preview'), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect the tag and note preview toggles to default to enabled',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DisplaySettingsScreen()),
    );

    final tagSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Show tag preview'),
    );
    expect(tagSwitch.value, isTrue);

    final noteSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Show note preview'),
    );
    expect(noteSwitch.value, isTrue);
  });
}
