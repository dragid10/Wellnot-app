// about_screen_test.dart: Widget tests for the About sub-page
//
// Cross-ref:
//   - Screen under test: lib/screens/settings/about_screen.dart

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:symptom_tracker_app/screens/settings/about_screen.dart';
import 'package:symptom_tracker_app/services/database.dart';

import '../../../helpers/test_database.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Wellnot',
      packageName: 'dev.alexo.symptom_tracker_app',
      version: '1.9.0',
      buildNumber: '25',
      buildSignature: '',
    );
  });

  /// Helper to pump the AboutScreen and wait for FutureBuilder.
  Future<void> pumpAbout(WidgetTester tester) async {
    final db = createTestDatabase();
    await tester.pumpWidget(
      Provider<AppDatabase>(
        create: (_) => db,
        child: const MaterialApp(home: AboutScreen()),
      ),
    );
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }

  testWidgets(
      'As a user, I expect to see the About screen with app name, version, and copyright',
      (tester) async {
    await pumpAbout(tester);

    expect(find.text('About'), findsOneWidget);
    expect(find.text('Wellnot'), findsOneWidget);
    expect(find.text('v1.9.0 (Build 25)'), findsOneWidget);
    expect(find.textContaining('Alex Oladele'), findsOneWidget);
  });

  testWidgets('As a user, I expect to see an Open Source Licenses link',
      (tester) async {
    await pumpAbout(tester);

    expect(find.text('Open Source Licenses'), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect a hidden easter egg image to appear when I long-press the app name for 8+ seconds',
      (tester) async {
    await pumpAbout(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Wellnot')),
    );

    await tester.pump(const Duration(seconds: 9));

    expect(find.byType(Image), findsOneWidget);

    await gesture.up();
    await tester.pump();
  });

  testWidgets(
      'As a user, I expect the easter egg to not appear when I release the long-press before 8 seconds',
      (tester) async {
    await pumpAbout(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Wellnot')),
    );

    await tester.pump(const Duration(seconds: 5));
    await gesture.up();
    await tester.pump();

    expect(find.byType(Image), findsNothing);
  });
}
