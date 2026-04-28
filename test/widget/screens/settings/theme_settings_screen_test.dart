// theme_settings_screen_test.dart: Widget tests for the Theme sub-page
//
// Cross-ref:
//   - Screen under test: lib/screens/settings/theme_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symptom_tracker_app/screens/settings/theme_settings_screen.dart';
import 'package:symptom_tracker_app/services/preferences_service.dart';

void main() {
  testWidgets(
      'As a user, I expect to see the Theme screen title and a segmented control with Light, System, and Dark options',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ThemeSettingsScreen()),
    );

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect the segmented control to reflect the current theme mode',
      (tester) async {
    PreferencesService.themeModeNotifier.value = ThemeMode.dark;

    await tester.pumpWidget(
      const MaterialApp(home: ThemeSettingsScreen()),
    );

    // The SegmentedButton should have ThemeMode.dark selected.
    final segmentedButton = tester.widget<SegmentedButton<ThemeMode>>(
      find.byType(SegmentedButton<ThemeMode>),
    );
    expect(segmentedButton.selected, {ThemeMode.dark});

    // Reset.
    PreferencesService.themeModeNotifier.value = ThemeMode.system;
  });
}
