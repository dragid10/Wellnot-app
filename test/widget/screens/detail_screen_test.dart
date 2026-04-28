import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symptom_tracker_app/models/symptom_models.dart';
import 'package:symptom_tracker_app/screens/detail_screen.dart';
import 'package:symptom_tracker_app/services/database.dart';

import '../../helpers/test_database.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for `lib/screens/detail_screen.dart`.
///
/// DetailScreen shows a single entry's details — time, mood, symptoms
/// (with severity labels), tags, and notes. It allows deletion and editing.
///
/// Cross-ref:
///   - Entry model: lib/models/symptom_models.dart (SymptomEntryModel)
///   - Delete method: lib/services/database.dart (AppDatabase.deleteEntry)
///   - Edit navigation: lib/screens/entry_screen.dart
void main() {
  late AppDatabase db;
  late SymptomEntryModel testEntry;

  setUp(() {
    db = createTestDatabase();
    testEntry = SymptomEntryModel(
      id: 1,
      dateTime: DateTime(2024, 6, 15, 14, 30),
      mood: '😊',
      notes: 'Feeling okay today',
      symptoms: [
        UserSymptomModel(id: 1, name: 'Headache', severity: 4),
        UserSymptomModel(id: 2, name: 'Nausea', severity: 2),
      ],
      tags: [
        UserTagModel(id: 1, name: 'After Meal'),
        UserTagModel(id: 2, name: 'At Work'),
      ],
    );
  });

  tearDown(() async {
    await db.close();
  });

  // Should display the time, mood, notes, and all symptoms/tags.
  testWidgets(
      'As a user, I expect to see the mood and notes when viewing an entry\'s details',
      (tester) async {
    await pumpApp(
      tester,
      widget: SymptomDetailScreen(entry: testEntry),
      database: db,
    );
    await tester.pumpAndSettle();

    // Mood emoji should be visible.
    expect(find.text('😊'), findsOneWidget);
    // Notes should be visible.
    expect(find.text('Feeling okay today'), findsOneWidget);
  });

  // Symptom chips should include severity labels like "Headache (Severe)".
  testWidgets(
      'As a user, I expect to see symptoms with their severity labels (e.g. "Headache (Severe)") on the detail screen',
      (tester) async {
    await pumpApp(
      tester,
      widget: SymptomDetailScreen(entry: testEntry),
      database: db,
    );
    await tester.pumpAndSettle();

    // Severity 4 = "Severe", Severity 2 = "Mild".
    expect(find.text('Headache (Severe)'), findsOneWidget);
    expect(find.text('Nausea (Mild)'), findsOneWidget);
  });

  // Tag chips should be rendered when tags are present.
  testWidgets(
      'As a user, I expect to see all tags associated with the entry on the detail screen',
      (tester) async {
    await pumpApp(
      tester,
      widget: SymptomDetailScreen(entry: testEntry),
      database: db,
    );
    await tester.pumpAndSettle();

    expect(find.text('After Meal'), findsOneWidget);
    expect(find.text('At Work'), findsOneWidget);
  });

  // The delete icon should be present in the app bar.
  testWidgets(
      'As a user, I expect a delete icon to be available when viewing an entry',
      (tester) async {
    await pumpApp(
      tester,
      widget: SymptomDetailScreen(entry: testEntry),
      database: db,
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete), findsOneWidget);
  });

  // Tapping delete should show a confirmation dialog.
  testWidgets(
      'As a user, I expect a confirmation dialog when I tap delete so I don\'t accidentally lose an entry',
      (tester) async {
    await pumpApp(
      tester,
      widget: SymptomDetailScreen(entry: testEntry),
      database: db,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text('Delete Entry?'), findsOneWidget);
    expect(find.text('This action cannot be undone.'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  // The edit FAB should be present.
  testWidgets(
      'As a user, I expect an edit button to be available so I can modify an existing entry',
      (tester) async {
    await pumpApp(
      tester,
      widget: SymptomDetailScreen(entry: testEntry),
      database: db,
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Duplicate / "Log Similar" (#43)
  // ---------------------------------------------------------------------------

  // A "Log Similar" button should be visible on the detail screen.
  testWidgets(
      'As a user, I expect a Log Similar button so I can quickly create a new entry with the same symptoms',
      (tester) async {
    await pumpApp(
      tester,
      widget: SymptomDetailScreen(entry: testEntry),
      database: db,
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.copy), findsOneWidget);
  });
}
