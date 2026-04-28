// import_data_screen_test.dart: Widget tests for the Import Data sub-page
//
// Cross-ref:
//   - Screen under test: lib/screens/settings/import_data_screen.dart

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:symptom_tracker_app/screens/settings/import_data_screen.dart';
import 'package:symptom_tracker_app/services/database.dart';

import '../../../helpers/test_database.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  testWidgets(
      'As a user, I expect to see the Import Data screen with instructions and a file picker button',
      (tester) async {
    final db = createTestDatabase();
    await tester.pumpWidget(
      Provider<AppDatabase>(
        create: (_) => db,
        child: const MaterialApp(home: ImportDataScreen()),
      ),
    );

    expect(find.text('Import Data'), findsOneWidget);
    expect(find.text('Select backup file'), findsOneWidget);
    expect(find.textContaining('Restore your symptom data'), findsOneWidget);
    expect(
        find.textContaining('Existing entries are preserved'), findsOneWidget);

    await db.close();
  });

  testWidgets(
      'As a user, I expect no import button to be visible before selecting a file',
      (tester) async {
    final db = createTestDatabase();
    await tester.pumpWidget(
      Provider<AppDatabase>(
        create: (_) => db,
        child: const MaterialApp(home: ImportDataScreen()),
      ),
    );

    // The import button should not appear until a file is selected and validated.
    expect(find.byType(FilledButton), findsNothing);

    await db.close();
  });
}
