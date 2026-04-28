// clear_reset_screen_test.dart: Widget tests for the Clear & Reset sub-page
//
// Cross-ref:
//   - Screen under test: lib/screens/settings/clear_reset_screen.dart

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:symptom_tracker_app/screens/settings/clear_reset_screen.dart';
import 'package:symptom_tracker_app/services/database.dart';

import '../../../helpers/test_database.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpClearReset(WidgetTester tester) async {
    final db = createTestDatabase();
    await tester.pumpWidget(
      Provider<AppDatabase>(
        create: (_) => db,
        child: const MaterialApp(home: ClearResetScreen()),
      ),
    );
  }

  testWidgets(
      'As a user, I expect to see three options: Clear Logged Data, Reset Settings, and Clear Everything',
      (tester) async {
    await pumpClearReset(tester);

    expect(find.text('Clear & Reset'), findsOneWidget);
    expect(find.text('Clear Logged Data'), findsOneWidget);
    expect(find.text('Reset Settings'), findsOneWidget);
    expect(find.text('Clear Everything'), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect each option to have a subtitle explaining what it does',
      (tester) async {
    await pumpClearReset(tester);

    expect(find.text('Delete all entries, custom symptoms, and tags'),
        findsOneWidget);
    expect(
        find.text(
            'Reset theme, calendar, notifications, and all preferences to defaults'),
        findsOneWidget);
    expect(find.text('Delete all data and reset all settings'), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect a confirmation dialog when I tap Clear Logged Data',
      (tester) async {
    await pumpClearReset(tester);

    await tester.tap(find.text('Clear Logged Data'));
    await tester.pump();

    expect(find.text('Clear Logged Data?'), findsOneWidget);
    expect(find.textContaining('permanently delete'), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect a confirmation dialog when I tap Reset Settings',
      (tester) async {
    await pumpClearReset(tester);

    await tester.tap(find.text('Reset Settings'));
    await tester.pump();

    expect(find.text('Reset All Settings?'), findsOneWidget);
    expect(find.textContaining('reset theme'), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect a confirmation dialog when I tap Clear Everything',
      (tester) async {
    await pumpClearReset(tester);

    await tester.tap(find.text('Clear Everything'));
    await tester.pump();

    expect(find.text('Clear Everything?'), findsOneWidget);
    expect(find.textContaining('reset all app settings'), findsOneWidget);
  });
}
