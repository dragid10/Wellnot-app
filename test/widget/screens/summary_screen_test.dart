import 'package:flutter_test/flutter_test.dart';
import 'package:symptom_tracker_app/models/symptom_models.dart';
import 'package:symptom_tracker_app/screens/summary_screen.dart';
import 'package:symptom_tracker_app/services/database.dart';

import '../../helpers/test_database.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for `lib/screens/summary_screen.dart`.
///
/// Tests the date range summary screen: date range selector, empty state,
/// mood distribution, symptom list, and tag list.
///
/// Cross-ref:
///   - Screen under test: lib/screens/summary_screen.dart
///   - In-memory DB: test/helpers/test_database.dart
///   - Widget wrapper: test/helpers/widget_test_helpers.dart
void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  /// Pumps the SummaryScreen and allows async loading to complete.
  Future<void> pumpSummary(WidgetTester tester, AppDatabase db) async {
    await pumpApp(tester, widget: const SummaryScreen(), database: db);
    // Allow async _loadSummary() to complete.
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
  }

  testWidgets(
      'As a user, I expect to see the Summary title and date range selector when opening the summary screen',
      (tester) async {
    await pumpSummary(tester, db);

    expect(find.text('Summary'), findsOneWidget);
    // All four range options should be visible in the segmented control.
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('Last 30 days'), findsOneWidget);
    expect(find.text('This month'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect to see an empty state message when there are no entries in the selected range',
      (tester) async {
    await pumpSummary(tester, db);

    expect(find.text('No entries in this date range.'), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect to see mood distribution when entries exist in the selected range',
      (tester) async {
    // Insert entries within the last 7 days.
    final now = DateTime.now();
    await db.saveEntry(
      dateTime: now.subtract(const Duration(days: 1)),
      mood: '😊',
      symptoms: [UserSymptomModel(id: -1, name: 'Headache', severity: 3)],
      tags: [],
    );
    await db.saveEntry(
      dateTime: now.subtract(const Duration(days: 2)),
      mood: '😊',
      symptoms: [UserSymptomModel(id: -1, name: 'Nausea', severity: 2)],
      tags: [],
    );
    await db.saveEntry(
      dateTime: now.subtract(const Duration(days: 3)),
      mood: '😢',
      symptoms: [],
      tags: [],
    );

    await pumpSummary(tester, db);

    // Should show entry count.
    expect(find.text('3 entries'), findsOneWidget);
    // Should show mood distribution section.
    expect(find.text('Mood Distribution'), findsOneWidget);
    // Both moods should appear.
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('As a user, I expect to see top symptoms ranked by frequency',
      (tester) async {
    final now = DateTime.now();
    await db.saveEntry(
      dateTime: now.subtract(const Duration(days: 1)),
      mood: '😊',
      symptoms: [
        UserSymptomModel(id: -1, name: 'Headache', severity: 4),
        UserSymptomModel(id: -1, name: 'Nausea', severity: 2),
      ],
      tags: [],
    );
    await db.saveEntry(
      dateTime: now.subtract(const Duration(days: 2)),
      mood: '😢',
      symptoms: [
        UserSymptomModel(id: -1, name: 'Headache', severity: 2),
      ],
      tags: [],
    );

    await pumpSummary(tester, db);

    expect(find.text('Top Symptoms'), findsOneWidget);
    // Headache should appear first (2 occurrences).
    expect(find.text('Headache'), findsOneWidget);
    expect(find.text('2x'), findsOneWidget);
    // Nausea (1 occurrence).
    expect(find.text('Nausea'), findsOneWidget);
    expect(find.text('1x'), findsOneWidget);
    // Average severity label for Headache: (4+2)/2 = 3.0 → Moderate
    expect(find.text('Avg: Moderate'), findsOneWidget);
  });

  testWidgets('As a user, I expect to see top tags when entries have tags',
      (tester) async {
    final now = DateTime.now();
    await db.saveEntry(
      dateTime: now.subtract(const Duration(days: 1)),
      mood: '😊',
      symptoms: [],
      tags: [
        UserTagModel(id: -1, name: 'After Meal'),
        UserTagModel(id: -1, name: 'At Work'),
      ],
    );
    await db.saveEntry(
      dateTime: now.subtract(const Duration(days: 2)),
      mood: '😢',
      symptoms: [],
      tags: [
        UserTagModel(id: -1, name: 'After Meal'),
      ],
    );

    await pumpSummary(tester, db);

    expect(find.text('Top Tags'), findsOneWidget);
    expect(find.text('After Meal'), findsOneWidget);
    expect(find.text('At Work'), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect the overview card to show "1 entry" (singular) for a single entry',
      (tester) async {
    final now = DateTime.now();
    await db.saveEntry(
      dateTime: now.subtract(const Duration(days: 1)),
      mood: '😊',
      symptoms: [],
      tags: [],
    );

    await pumpSummary(tester, db);

    expect(find.text('1 entry'), findsOneWidget);
  });
}
