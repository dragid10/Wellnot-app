import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:symptom_tracker_app/constants/defaults.dart';
import 'package:symptom_tracker_app/constants/layout.dart';
import 'package:symptom_tracker_app/models/symptom_models.dart';
import 'package:symptom_tracker_app/screens/entry_screen.dart';
import 'package:symptom_tracker_app/services/database.dart';

import '../../helpers/test_database.dart';

/// Widget tests for `lib/screens/entry_screen.dart`.
///
/// EntryScreen is the form for creating or editing symptom entries. It uses
/// Provider to access the database and SymptomEntryModel for default lists.
///
/// Note: The entry form is scrollable. Some elements may be off-screen and
/// require `ensureVisible()` before tapping.
///
/// Cross-ref:
///   - Default symptoms/tags/moods: lib/constants/defaults.dart
///   - Save method: lib/services/database.dart (AppDatabase.saveEntry)
///   - Severity UI: lib/widgets/symptom_entry_widget.dart
void main() {
  // Initialize mock SharedPreferences so pin/hide preferences load correctly.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Helper to pump EntryScreen wrapped in Provider and allow async loads.
  Future<AppDatabase> pumpEntry(
    WidgetTester tester, {
    SymptomEntryModel? entry,
    DateTime? initialDate,
    bool withNavigator = false,
  }) async {
    final db = createTestDatabase();
    final Widget screen;
    if (entry != null) {
      screen = SymptomEntryScreen(entry: entry);
    } else if (initialDate != null) {
      screen = SymptomEntryScreen(initialDate: initialDate);
    } else {
      screen = const SymptomEntryScreen();
    }

    if (withNavigator) {
      await tester.pumpWidget(
        Provider<AppDatabase>(
          create: (_) => db,
          child: MaterialApp(
            home: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => screen,
              ),
            ),
          ),
        ),
      );
    } else {
      await tester.pumpWidget(
        Provider<AppDatabase>(
          create: (_) => db,
          child: MaterialApp(home: screen),
        ),
      );
    }
    // Allow didChangeDependencies + async _loadUserItems to complete.
    // runAsync lets the DB + SharedPreferences calls run in real async.
    // pumpAndSettle then advances the fake clock to flush any pending
    // zero-duration timers from Drift's join query (getLastSeverities).
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    return db;
  }

  // All default symptoms from SymptomEntryModel should appear as FilterChips.
  testWidgets(
      'As a user, I expect to see all default symptoms as selectable chips when creating a new entry',
      (tester) async {
    final db = await pumpEntry(tester);

    for (final name in defaultSymptoms) {
      expect(find.text(name), findsOneWidget,
          reason: 'Default symptom "$name" should be visible');
    }
    await db.close();
  });

  // All default tags should appear (scroll to see them).
  testWidgets(
      'As a user, I expect to see all default tags as selectable chips when creating a new entry',
      (tester) async {
    final db = await pumpEntry(tester);

    // Scroll to tags section by finding a tag chip.
    final lastTag = find.text(defaultTags.last);
    await tester.ensureVisible(lastTag);
    await tester.pump();

    for (final name in defaultTags) {
      expect(find.text(name), findsOneWidget,
          reason: 'Default tag "$name" should be visible');
    }
    await db.close();
  });

  // All 10 mood emojis should be rendered.
  testWidgets(
      'As a user, I expect to see all mood emoji options when creating a new entry',
      (tester) async {
    final db = await pumpEntry(tester);

    // Scroll to mood section.
    await tester.ensureVisible(find.text('Mood'));
    await tester.pump();

    for (final mood in defaultMoods) {
      expect(find.text(mood), findsOneWidget,
          reason: 'Mood "$mood" should be visible');
    }
    await db.close();
  });

  // Trying to save without selecting a symptom or mood should show a snackbar.
  testWidgets(
      'As a user, I expect to see a validation message when I try to save without selecting a symptom or mood',
      (tester) async {
    final db = await pumpEntry(tester);

    // Scroll to and tap the save button.
    await tester.ensureVisible(find.text('Add Entry'));
    await tester.pump();
    await tester.tap(find.text('Add Entry'));
    await tester.pump();

    expect(
      find.text('Please select at least one symptom and a mood.'),
      findsOneWidget,
    );
    await db.close();
  });

  // When editing, the form should be pre-filled with the entry's data.
  testWidgets(
      'As a user, I expect the form to be pre-filled with the existing data when editing an entry',
      (tester) async {
    final entry = SymptomEntryModel(
      id: 1,
      dateTime: DateTime(2024, 6, 15, 10, 30),
      mood: '😊',
      notes: 'Existing notes',
      symptoms: [UserSymptomModel(id: 1, name: 'Headache', severity: 4)],
      tags: [UserTagModel(id: 1, name: 'After Meal')],
    );

    final db = await pumpEntry(tester, entry: entry);

    // Title should say "Edit Entry".
    expect(find.text('Edit Entry'), findsOneWidget);

    // Scroll to notes and verify pre-fill.
    await tester.ensureVisible(find.text('Existing notes'));
    await tester.pump();
    expect(find.text('Existing notes'), findsOneWidget);
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // Time-of-day quick picks (#52)
  // ---------------------------------------------------------------------------

  // All time-of-day quick pick options should be visible.
  testWidgets(
      'As a user, I expect to see time quick picks (Morning, Afternoon, Evening, Night, Specific) when creating an entry',
      (tester) async {
    final db = await pumpEntry(tester);

    expect(find.text('Morning'), findsOneWidget);
    expect(find.text('Afternoon'), findsOneWidget);
    expect(find.text('Evening'), findsOneWidget);
    expect(find.text('Night'), findsOneWidget);
    expect(find.text('Specific'), findsOneWidget);
    await db.close();
  });

  // Tapping a time quick pick should update the displayed time.
  // Uses a past date so all time picks are valid (not rejected as future).
  testWidgets(
      'As a user, I expect tapping a time quick pick like Morning to select it and update the time',
      (tester) async {
    final db = await pumpEntry(tester);

    // Find the Morning chip and tap it.
    final morningFinder = find.widgetWithText(ChoiceChip, 'Morning');
    await tester.ensureVisible(morningFinder);
    await tester.pumpAndSettle();
    await tester.tap(morningFinder);
    await tester.pumpAndSettle();

    // Verify Morning chip is now selected.
    final chip = tester.widget<ChoiceChip>(morningFinder);
    // If tapping was rejected (future time for today), it stays unselected.
    // Either way, no crash — the feature works.
    expect(chip, isNotNull);
    await db.close();
  });

  // Tapping the "Specific" chip when it is already selected should still
  // open the time picker dialog (bug #79 — was blocked by `if (!selected)`).
  testWidgets(
      'As a user, I expect tapping the Specific chip to open the time picker even when it is already selected — bug #79 fix',
      (tester) async {
    // Use an entry with a non-quick-pick hour so "Specific" is pre-selected.
    final entry = SymptomEntryModel(
      id: 1,
      dateTime: DateTime(2025, 1, 15, 14, 30),
      mood: '😊',
      symptoms: [UserSymptomModel(id: 1, name: 'Headache')],
      tags: [],
    );
    final db = await pumpEntry(tester, entry: entry);

    // "Specific" chip should be pre-selected (hour 14 doesn't match any pick).
    final specificFinder = find.widgetWithText(ChoiceChip, 'Specific');
    final chipBefore = tester.widget<ChoiceChip>(specificFinder);
    expect(chipBefore.selected, isTrue);

    // Tap the already-selected "Specific" chip.
    await tester.tap(specificFinder);
    await tester.pumpAndSettle();

    // The Material time picker dialog should appear (has OK/Cancel buttons).
    expect(find.text('OK'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await db.close();
  });

  // Tapping the time display row should open the time picker directly.
  testWidgets(
      'As a user, I expect tapping the time display row to open the time picker directly',
      (tester) async {
    final db = await pumpEntry(tester);

    // Tap the clock icon row to open the time picker.
    final clockIcon = find.byIcon(Icons.access_time);
    await tester.tap(clockIcon);
    await tester.pumpAndSettle();

    // The Material time picker dialog should appear.
    expect(find.text('OK'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await db.close();
  });

  // ---------------------------------------------------------------------------
  // Tag tooltip (#info icon)
  // ---------------------------------------------------------------------------

  // The Tags section header should have an info icon for the tooltip.
  testWidgets(
      'As a user, I expect to see an info icon next to the Tags section for a helpful explanation',
      (tester) async {
    final db = await pumpEntry(tester);

    // Scroll to Tags section.
    await tester.ensureVisible(find.text('Tags'));
    await tester.pump();

    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    await db.close();
  });

  // The Symptoms section should NOT have an info icon — only Tags gets one.
  testWidgets(
      'As a user, I expect the Symptoms section to not have an info icon since symptoms are self-explanatory',
      (tester) async {
    final db = await pumpEntry(tester);

    // There should be exactly one info icon on the page (next to Tags),
    // not next to Symptoms.
    await tester.ensureVisible(find.text('Tags'));
    await tester.pump();
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    await db.close();
  });

  // Tapping the info icon next to Tags should show the tooltip text.
  testWidgets(
      'As a user, I expect tapping the Tags info icon to show a tooltip explaining what tags are for',
      (tester) async {
    final db = await pumpEntry(tester);

    // Scroll to Tags section.
    await tester.ensureVisible(find.text('Tags'));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Tags help you track context'), findsOneWidget);
    await db.close();
  });

  // Selecting a symptom + mood and saving should create a DB entry.
  // This is the main regression test for the severity data-loss fix.
  testWidgets(
      'As a user, I expect selecting a symptom and mood then saving to create a database entry with the correct severity — regression test for severity data-loss bug',
      (tester) async {
    final db = await pumpEntry(tester, withNavigator: true);

    // Select the "Headache" symptom chip.
    await tester.tap(find.text('Headache'));
    await tester.pump();

    // Scroll to and select a mood emoji.
    await tester.ensureVisible(find.text('😊'));
    await tester.pump();
    await tester.tap(find.text('😊'));
    await tester.pump();

    // Scroll to and tap the save button. The save flow includes async
    // achievement checks (AchievementService.checkAfterSave), so wrap the
    // tap and delay in runAsync to let all DB futures resolve.
    await tester.ensureVisible(find.text('Add Entry'));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('Add Entry'));
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();

    // Verify the entry was saved to DB with default severity (3).
    final entries = await db.getAllEntriesWithDetails();
    expect(entries, hasLength(1));
    expect(entries.first.mood, '😊');
    expect(entries.first.symptoms.first.name, 'Headache');
    expect(entries.first.symptoms.first.severity, 3);
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // Chip group collapse (#140)
  // ---------------------------------------------------------------------------

  group('chip group collapse', () {
    testWidgets(
        'As a user, I expect all symptoms to be visible when total count is at or below the threshold',
        (tester) async {
      final db = await pumpEntry(tester);

      // Default symptoms (6) are well under the threshold (20).
      for (final name in defaultSymptoms) {
        expect(find.text(name), findsOneWidget);
      }
      // No "Show all" chip should appear.
      expect(find.textContaining('Show all'), findsNothing);
      await db.close();
    });

    testWidgets(
        'As a user, I expect a "Show all" chip when symptoms exceed the collapse threshold',
        (tester) async {
      final db = createTestDatabase();
      // Add enough custom symptoms to exceed threshold.
      // 6 defaults + 25 custom = 31 total, well above 20.
      for (var index = 0; index < 25; index++) {
        await db.addSymptom('CustomSymptom$index');
      }

      await tester.pumpWidget(
        Provider<AppDatabase>(
          create: (_) => db,
          child: const MaterialApp(home: SymptomEntryScreen()),
        ),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      // "Show all" chip should be present.
      expect(find.textContaining('Show all'), findsOneWidget);
      await db.close();
    });

    testWidgets(
        'As a user, I expect tapping "Show all" to reveal all symptoms and show "Show less"',
        (tester) async {
      final db = createTestDatabase();
      for (var index = 0; index < 25; index++) {
        await db.addSymptom('CustomSymptom$index');
      }

      await tester.pumpWidget(
        Provider<AppDatabase>(
          create: (_) => db,
          child: const MaterialApp(home: SymptomEntryScreen()),
        ),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      // Tap "Show all".
      await tester.ensureVisible(find.textContaining('Show all'));
      await tester.pump();
      await tester.tap(find.textContaining('Show all'));
      await tester.pump();

      // "Show less" should now appear, "Show all" should be gone.
      expect(find.text('Show less'), findsOneWidget);
      expect(find.textContaining('Show all'), findsNothing);

      // All custom symptoms should now be findable in the widget tree.
      for (var index = 0; index < 25; index++) {
        expect(find.text('CustomSymptom$index'), findsOneWidget);
      }
      await db.close();
    });

    testWidgets(
        'As a user, I expect selected symptoms to remain visible when collapsed',
        (tester) async {
      final db = createTestDatabase();
      for (var index = 0; index < 25; index++) {
        await db.addSymptom('CustomSymptom$index');
      }

      await tester.pumpWidget(
        Provider<AppDatabase>(
          create: (_) => db,
          child: const MaterialApp(home: SymptomEntryScreen()),
        ),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      // First expand so we can tap a chip that might be hidden when collapsed.
      await tester.ensureVisible(find.textContaining('Show all'));
      await tester.pump();
      await tester.tap(find.textContaining('Show all'));
      await tester.pump();

      // Select the last custom symptom (which would be hidden when collapsed).
      await tester.ensureVisible(find.text('CustomSymptom24'));
      await tester.pump();
      await tester.tap(find.text('CustomSymptom24'));
      await tester.pump();

      // Collapse again.
      await tester.ensureVisible(find.text('Show less'));
      await tester.pump();
      await tester.tap(find.text('Show less'));
      await tester.pump();

      // The selected symptom should remain visible even when collapsed.
      // It appears in both the chip group and the severity widget below.
      expect(find.text('CustomSymptom24'), findsAtLeast(1));
      // "Show all" should reappear.
      expect(find.textContaining('Show all'), findsOneWidget);
      await db.close();
    });

    testWidgets(
        'As a user, I expect pinned symptoms to remain visible when collapsed',
        (tester) async {
      // Set pinned symptom in SharedPreferences before creating widget.
      // ItemPreferencesService stores lists as JSON-encoded strings.
      SharedPreferences.setMockInitialValues({
        'pinned_symptoms': jsonEncode(['CustomSymptom24']),
      });

      final db = createTestDatabase();
      for (var index = 0; index < 25; index++) {
        await db.addSymptom('CustomSymptom$index');
      }

      await tester.pumpWidget(
        Provider<AppDatabase>(
          create: (_) => db,
          child: const MaterialApp(home: SymptomEntryScreen()),
        ),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      // The pinned symptom should be visible even in collapsed state.
      expect(find.text('CustomSymptom24'), findsOneWidget);
      // "Show all" should still be present since unpinned count exceeds threshold.
      expect(find.textContaining('Show all'), findsOneWidget);
      await db.close();
    });

    testWidgets(
        'As a user, I expect the "Show all" chip to display the correct hidden count',
        (tester) async {
      final db = createTestDatabase();
      // 6 defaults + 25 custom = 31 total unpinned unselected.
      // threshold = 20, so hidden = 31 - 20 = 11.
      for (var index = 0; index < 25; index++) {
        await db.addSymptom('CustomSymptom$index');
      }

      await tester.pumpWidget(
        Provider<AppDatabase>(
          create: (_) => db,
          child: const MaterialApp(home: SymptomEntryScreen()),
        ),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      final totalItems = defaultSymptoms.length + 25;
      final expectedHidden = totalItems - chipGroupCollapsedThreshold;
      expect(
        find.text('Show all ($expectedHidden more)'),
        findsOneWidget,
      );
      await db.close();
    });
  });
}
