// export_data_screen_test.dart: Widget tests for the Export Data sub-page
//
// Cross-ref:
//   - Screen under test: lib/screens/settings/export_data_screen.dart

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:symptom_tracker_app/screens/settings/export_data_screen.dart';
import 'package:symptom_tracker_app/services/database.dart';

import '../../../helpers/test_database.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  testWidgets(
      'As a user, I expect to see the Export Data screen with JSON and CSV options',
      (tester) async {
    final db = createTestDatabase();
    await tester.pumpWidget(
      Provider<AppDatabase>(
        create: (_) => db,
        child: const MaterialApp(home: ExportDataScreen()),
      ),
    );

    expect(find.text('Export Data'), findsOneWidget);
    expect(find.text('JSON (Recommended)'), findsOneWidget);
    expect(find.text('CSV'), findsOneWidget);
    expect(find.textContaining('spreadsheet'), findsOneWidget);
    expect(find.textContaining('backup & restore'), findsOneWidget);
  });
}
