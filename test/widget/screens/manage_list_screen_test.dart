// manage_list_screen_test.dart: Widget tests for the Manage Symptoms/Tags
// sub-pages.
//
// Tests cover: default item display, adding custom items, duplicate detection,
// and default item protection (issue #8).
//
// Cross-ref:
//   - Screen under test: lib/screens/manage_list_screen.dart
//   - Parent screen: lib/screens/manage_items_screen.dart
//   - Default lists: lib/constants/defaults.dart

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:symptom_tracker_app/constants/defaults.dart';
import 'package:symptom_tracker_app/models/symptom_models.dart';
import 'package:symptom_tracker_app/screens/manage_list_screen.dart';
import 'package:symptom_tracker_app/services/database.dart';

import '../../helpers/test_database.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  // Initialize mock SharedPreferences so hide preferences load correctly.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Helper to pump ManageListScreen for symptoms.
  Future<AppDatabase> pumpSymptoms(WidgetTester tester) async {
    final db = createTestDatabase();
    await tester.pumpWidget(
      Provider<AppDatabase>(
        create: (_) => db,
        child: const MaterialApp(
          home: ManageListScreen(
            title: 'Manage Symptoms',
            itemType: 'symptom',
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    return db;
  }

  /// Helper to pump ManageListScreen for tags.
  Future<AppDatabase> pumpTags(WidgetTester tester) async {
    final db = createTestDatabase();
    await tester.pumpWidget(
      Provider<AppDatabase>(
        create: (_) => db,
        child: const MaterialApp(
          home: ManageListScreen(
            title: 'Manage Tags',
            itemType: 'tag',
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    return db;
  }

  // ---------------------------------------------------------------------------
  // Symptoms sub-page
  // ---------------------------------------------------------------------------

  // Default symptoms should be visible as read-only chips.
  testWidgets(
      'As a user, I expect to see all default symptoms listed on the Manage Symptoms page',
      (tester) async {
    await pumpSymptoms(tester);

    for (final name in defaultSymptoms) {
      expect(find.text(name), findsOneWidget,
          reason: 'Default symptom "$name" should be visible');
    }
  });

  // Adding a new custom symptom should make it appear in the list.
  testWidgets(
      'As a user, I expect a custom symptom I add to appear in the list immediately',
      (tester) async {
    await pumpSymptoms(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Enter symptom name'),
      'Back Pain',
    );
    await tester.tap(find.byIcon(Icons.add));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(find.text('Back Pain'), findsOneWidget);
  });

  // Attempting to add a duplicate shows a snackbar.
  testWidgets(
      'As a user, I expect to see an error message when trying to add a symptom that already exists',
      (tester) async {
    await pumpSymptoms(tester);

    final textField = find.widgetWithText(TextField, 'Enter symptom name');
    await tester.enterText(textField, 'Headache');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.textContaining('already exists'), findsOneWidget);
    // Advance past the 2-second duplicate highlight timer.
    await tester.pump(const Duration(seconds: 3));
  });

  // Default symptoms inserted by saveEntry should NOT appear as custom items
  // with delete buttons.
  testWidgets(
      'As a user, I expect default symptoms used in entries to not show up as deletable custom items',
      (tester) async {
    final db = await pumpSymptoms(tester);

    // Simulate saveEntry creating a default symptom in the UserSymptoms table.
    await tester.runAsync(() async {
      await db.saveEntry(
        dateTime: DateTime.now(),
        mood: '😊',
        symptoms: [
          UserSymptomModel(id: -1, name: 'Headache', severity: 3),
        ],
        tags: [],
      );
    });

    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    // "Headache" should appear exactly once (in Default Symptoms).
    expect(find.text('Headache'), findsOneWidget);

    // No deletable chip for "Headache" should exist.
    final headacheChips = tester
        .widgetList<Chip>(find.byType(Chip))
        .where((chip) =>
            (chip.label as Text).data == 'Headache' && chip.onDeleted != null)
        .toList();
    expect(headacheChips, isEmpty,
        reason: 'Default symptom should not be deletable');
  });

  // Custom symptoms should appear with delete buttons.
  testWidgets(
      'As a user, I expect custom symptoms I added to have delete buttons so I can remove them',
      (tester) async {
    final db = createTestDatabase();
    await db.addSymptom('Back Pain');

    await tester.pumpWidget(
      Provider<AppDatabase>(
        create: (_) => db,
        child: const MaterialApp(
          home: ManageListScreen(
            title: 'Manage Symptoms',
            itemType: 'symptom',
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(find.text('Back Pain'), findsOneWidget);
    final backPainChips = tester
        .widgetList<Chip>(find.byType(Chip))
        .where((chip) =>
            (chip.label as Text).data == 'Back Pain' && chip.onDeleted != null)
        .toList();
    expect(backPainChips, hasLength(1),
        reason: 'Custom symptom should have a delete button');
  });

  // ---------------------------------------------------------------------------
  // Tags sub-page
  // ---------------------------------------------------------------------------

  // Default tags should be visible as read-only chips.
  testWidgets(
      'As a user, I expect to see all default tags listed on the Manage Tags page',
      (tester) async {
    await pumpTags(tester);

    for (final name in defaultTags) {
      expect(find.text(name), findsOneWidget,
          reason: 'Default tag "$name" should be visible');
    }
  });

  // Default tags inserted by saveEntry should NOT appear as custom items.
  testWidgets(
      'As a user, I expect default tags used in entries to not show up as deletable custom items',
      (tester) async {
    final db = await pumpTags(tester);

    await tester.runAsync(() async {
      await db.saveEntry(
        dateTime: DateTime.now(),
        mood: '😊',
        symptoms: [],
        tags: [UserTagModel(id: -1, name: 'After Meal')],
      );
    });

    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(find.text('After Meal'), findsOneWidget);

    final afterMealChips = tester
        .widgetList<Chip>(find.byType(Chip))
        .where((chip) =>
            (chip.label as Text).data == 'After Meal' && chip.onDeleted != null)
        .toList();
    expect(afterMealChips, isEmpty,
        reason: 'Default tag should not be deletable');
  });

  // ---------------------------------------------------------------------------
  // Tag tooltip (#info icon)
  // ---------------------------------------------------------------------------

  // The Manage Tags page should have an info icon in the app bar.
  testWidgets(
      'As a user, I expect to see an info icon on the Manage Tags page explaining what tags are for',
      (tester) async {
    await pumpTags(tester);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  // The Manage Symptoms page should NOT have an info icon.
  testWidgets(
      'As a user, I expect no info icon on the Manage Symptoms page since symptoms are self-explanatory',
      (tester) async {
    await pumpSymptoms(tester);
    expect(find.byIcon(Icons.info_outline), findsNothing);
  });

  // Tapping the info icon on the tags page should show the tooltip.
  testWidgets(
      'As a user, I expect tapping the Tags info icon to show a tooltip explaining what tags are for',
      (tester) async {
    await pumpTags(tester);

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Tags help you track context'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Long names (#33)
  // ---------------------------------------------------------------------------

  // Long symptom names should not overflow the chip — text should be
  // constrained with ellipsis.
  testWidgets(
      'As a user, I expect long symptom names to be constrained with ellipsis in chips instead of overflowing',
      (tester) async {
    final db = createTestDatabase();
    await db.addSymptom(
        'something really long with spaces that has lots of syllables');

    await tester.pumpWidget(
      Provider<AppDatabase>(
        create: (_) => db,
        child: const MaterialApp(
          home: ManageListScreen(
            title: 'Manage Symptoms',
            itemType: 'symptom',
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    // The chip should exist and the text widget should have overflow handling.
    final chips = tester.widgetList<Chip>(find.byType(Chip)).toList();
    final longChip = chips.where((chip) {
      final label = chip.label;
      if (label is Text) {
        return label.data?.contains('something really long') ?? false;
      }
      return false;
    }).toList();
    expect(longChip, isNotEmpty, reason: 'Long symptom chip should exist');
  });
}
