import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symptom_tracker_app/constants/defaults.dart' as defaults;
import 'package:symptom_tracker_app/models/symptom_models.dart';
import 'package:symptom_tracker_app/services/database.dart';

import '../../helpers/test_database.dart';

/// Unit tests for `lib/services/database.dart`.
///
/// These tests exercise the Drift-backed AppDatabase using an in-memory SQLite
/// instance (via `createTestDatabase()`), so they are fast and require no
/// emulator. Each test gets a fresh database to avoid cross-test contamination.
///
/// Cross-ref:
///   - Test helper: test/helpers/test_database.dart
///   - Schema + helpers under test: lib/services/database.dart
///   - Models used as return types: lib/models/symptom_models.dart
void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // Legacy helpers — getOrCreateSymptom / getOrCreateTag
  // ---------------------------------------------------------------------------

  group('getOrCreateSymptom', () {
    // Should insert a new row and return its positive auto-increment ID.
    test(
        'As a user, I expect a new symptom to be created and assigned an id when I add it for the first time',
        () async {
      final id = await db.getOrCreateSymptom('Headache');
      expect(id, isPositive);
    });

    // Calling twice with the same name should return the same ID (idempotent).
    test(
        'As a user, I expect adding the same symptom twice to return the existing one instead of creating a duplicate',
        () async {
      final id1 = await db.getOrCreateSymptom('Headache');
      final id2 = await db.getOrCreateSymptom('Headache');
      expect(id1, equals(id2));
    });
  });

  group('getOrCreateTag', () {
    test(
        'As a user, I expect a new tag to be created and assigned an id when I add it for the first time',
        () async {
      final id = await db.getOrCreateTag('Work');
      expect(id, isPositive);
    });

    test(
        'As a user, I expect adding the same tag twice to return the existing one instead of creating a duplicate',
        () async {
      final id1 = await db.getOrCreateTag('Work');
      final id2 = await db.getOrCreateTag('Work');
      expect(id1, equals(id2));
    });
  });

  // ---------------------------------------------------------------------------
  // Basic CRUD — low-level Drift operations
  // ---------------------------------------------------------------------------

  group('basic CRUD', () {
    test(
        'As a user, I expect my logged entry to be saved and retrievable from the database',
        () async {
      final now = DateTime.now();
      final id = await db.into(db.symptomEntries).insert(
            SymptomEntriesCompanion(
              entryDateTime: Value(now),
              mood: const Value('😊'),
              notes: const Value('Test note'),
            ),
          );

      final entries = await db.select(db.symptomEntries).get();
      expect(entries, hasLength(1));
      expect(entries.first.id, id);
      expect(entries.first.mood, '😊');
      expect(entries.first.notes, 'Test note');
    });

    test(
        'As a user, I expect deleting an entry to remove it completely from the database',
        () async {
      final id = await db.into(db.symptomEntries).insert(
            SymptomEntriesCompanion(
              entryDateTime: Value(DateTime.now()),
              mood: const Value('😐'),
            ),
          );

      await (db.delete(db.symptomEntries)..where((tbl) => tbl.id.equals(id)))
          .go();

      final entries = await db.select(db.symptomEntries).get();
      expect(entries, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Join tables — raw link verification
  // ---------------------------------------------------------------------------

  group('join tables', () {
    test(
        'As a user, I expect symptoms attached to an entry to be retrievable through the join table',
        () async {
      final entryId = await db.into(db.symptomEntries).insert(
            SymptomEntriesCompanion(
              entryDateTime: Value(DateTime.now()),
              mood: const Value('😊'),
            ),
          );
      final symptomId = await db.getOrCreateSymptom('Nausea');

      await db.into(db.symptomEntryWithSymptom).insert(
            SymptomEntryWithSymptomCompanion(
              symptomEntryId: Value(entryId),
              userSymptomId: Value(symptomId),
            ),
          );

      final links = await db.select(db.symptomEntryWithSymptom).get();
      expect(links, hasLength(1));
      expect(links.first.symptomEntryId, entryId);
      expect(links.first.userSymptomId, symptomId);
    });

    test(
        'As a user, I expect tags attached to an entry to be retrievable through the join table',
        () async {
      final entryId = await db.into(db.symptomEntries).insert(
            SymptomEntriesCompanion(
              entryDateTime: Value(DateTime.now()),
              mood: const Value('😊'),
            ),
          );
      final tagId = await db.getOrCreateTag('Exercise');

      await db.into(db.symptomEntryWithTag).insert(
            SymptomEntryWithTagCompanion(
              symptomEntryId: Value(entryId),
              userTagId: Value(tagId),
            ),
          );

      final links = await db.select(db.symptomEntryWithTag).get();
      expect(links, hasLength(1));
      expect(links.first.symptomEntryId, entryId);
      expect(links.first.userTagId, tagId);
    });
  });

  // ---------------------------------------------------------------------------
  // addSymptom / addTag — new helper methods
  // ---------------------------------------------------------------------------

  group('addSymptom', () {
    // Success case: first insert returns a positive ID.
    test(
        'As a user, I expect adding a custom symptom to save it and return its id',
        () async {
      final id = await db.addSymptom('Migraine');
      expect(id, isPositive);
    });

    // Duplicate case: returns -1 due to unique constraint.
    test('As a user, I expect adding a duplicate symptom name to be rejected',
        () async {
      await db.addSymptom('Migraine');
      final id2 = await db.addSymptom('Migraine');
      expect(id2, -1);
    });
  });

  group('addTag', () {
    test('As a user, I expect adding a custom tag to save it and return its id',
        () async {
      final id = await db.addTag('Morning');
      expect(id, isPositive);
    });

    test('As a user, I expect adding a duplicate tag name to be rejected',
        () async {
      await db.addTag('Morning');
      final id2 = await db.addTag('Morning');
      expect(id2, -1);
    });
  });

  // ---------------------------------------------------------------------------
  // deleteSymptom / deleteTag — cleanup + join-table link removal
  // ---------------------------------------------------------------------------

  group('deleteSymptom', () {
    // Deleting a custom symptom should also remove its join-table links.
    test(
        'As a user, I expect deleting a symptom to also remove it from all entries that referenced it',
        () async {
      final symptomId = await db.addSymptom('Migraine');
      final entryId = await db.into(db.symptomEntries).insert(
            SymptomEntriesCompanion(
              entryDateTime: Value(DateTime.now()),
              mood: const Value('😊'),
            ),
          );
      await db.into(db.symptomEntryWithSymptom).insert(
            SymptomEntryWithSymptomCompanion(
              symptomEntryId: Value(entryId),
              userSymptomId: Value(symptomId),
            ),
          );

      await db.deleteSymptom(symptomId);

      final symptoms = await db.select(db.userSymptoms).get();
      expect(symptoms, isEmpty);
      final links = await db.select(db.symptomEntryWithSymptom).get();
      expect(links, isEmpty);
    });
  });

  group('deleteTag', () {
    test(
        'As a user, I expect deleting a tag to also remove it from all entries that referenced it',
        () async {
      final tagId = await db.addTag('Work');
      final entryId = await db.into(db.symptomEntries).insert(
            SymptomEntriesCompanion(
              entryDateTime: Value(DateTime.now()),
              mood: const Value('😊'),
            ),
          );
      await db.into(db.symptomEntryWithTag).insert(
            SymptomEntryWithTagCompanion(
              symptomEntryId: Value(entryId),
              userTagId: Value(tagId),
            ),
          );

      await db.deleteTag(tagId);

      final tags = await db.select(db.userTags).get();
      expect(tags, isEmpty);
      final links = await db.select(db.symptomEntryWithTag).get();
      expect(links, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // saveEntry — the main transactional write method
  // ---------------------------------------------------------------------------

  group('saveEntry', () {
    // Verify that a new entry creates the correct rows in all tables.
    test(
        'As a user, I expect saving a new entry to store the mood, symptoms with severity, and tags',
        () async {
      final symptoms = [
        UserSymptomModel(id: -1, name: 'Headache', severity: 4),
        UserSymptomModel(id: -2, name: 'Nausea', severity: 2),
      ];
      final tags = [
        UserTagModel(id: -1, name: 'After Meal'),
      ];
      final now = DateTime.now();

      final entryId = await db.saveEntry(
        dateTime: now,
        mood: '😊',
        notes: 'Test',
        symptoms: symptoms,
        tags: tags,
      );

      expect(entryId, isPositive);

      // Verify the entry row.
      final entries = await db.select(db.symptomEntries).get();
      expect(entries, hasLength(1));
      expect(entries.first.mood, '😊');

      // Verify symptom links with severity.
      final symptomLinks = await db.select(db.symptomEntryWithSymptom).get();
      expect(symptomLinks, hasLength(2));

      // Verify tag links.
      final tagLinks = await db.select(db.symptomEntryWithTag).get();
      expect(tagLinks, hasLength(1));
    });

    // Updating an entry should replace old links with new ones.
    test(
        'As a user, I expect editing an entry to replace the old symptoms and tags with the updated ones',
        () async {
      final entryId = await db.saveEntry(
        dateTime: DateTime.now(),
        mood: '😊',
        symptoms: [UserSymptomModel(id: -1, name: 'Headache', severity: 3)],
        tags: [UserTagModel(id: -1, name: 'Work')],
      );

      // Update with different symptoms/tags.
      await db.saveEntry(
        existingId: entryId,
        dateTime: DateTime.now(),
        mood: '😢',
        symptoms: [UserSymptomModel(id: -1, name: 'Nausea', severity: 5)],
        tags: [],
      );

      final entries = await db.select(db.symptomEntries).get();
      expect(entries, hasLength(1));
      expect(entries.first.mood, '😢');

      final symptomLinks = await db.select(db.symptomEntryWithSymptom).get();
      expect(symptomLinks, hasLength(1));
      // The Nausea symptom should have severity 5.
      expect(symptomLinks.first.severity, 5);

      final tagLinks = await db.select(db.symptomEntryWithTag).get();
      expect(tagLinks, isEmpty);
    });

    // **Regression test for severity data-loss bug:** severity set in the UI
    // must survive the round-trip through saveEntry → getAllEntriesWithDetails.
    test(
        'As a user, I expect the severity I set for a symptom to be preserved after saving and reloading — regression test for severity data-loss bug',
        () async {
      await db.saveEntry(
        dateTime: DateTime.now(),
        mood: '😊',
        symptoms: [
          UserSymptomModel(id: -1, name: 'Headache', severity: 5),
        ],
        tags: [],
      );

      final entries = await db.getAllEntriesWithDetails();
      expect(entries, hasLength(1));
      expect(entries.first.symptoms.first.severity, 5);
    });
  });

  // ---------------------------------------------------------------------------
  // deleteEntry — transactional entry removal
  // ---------------------------------------------------------------------------

  group('deleteEntry', () {
    // Deleting should remove the entry row and all associated join-table rows.
    test(
        'As a user, I expect deleting an entry to remove it along with all its symptom and tag associations',
        () async {
      final entryId = await db.saveEntry(
        dateTime: DateTime.now(),
        mood: '😊',
        symptoms: [UserSymptomModel(id: -1, name: 'Headache', severity: 3)],
        tags: [UserTagModel(id: -1, name: 'Work')],
      );

      await db.deleteEntry(entryId);

      expect(await db.select(db.symptomEntries).get(), isEmpty);
      expect(await db.select(db.symptomEntryWithSymptom).get(), isEmpty);
      expect(await db.select(db.symptomEntryWithTag).get(), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // getAllEntriesWithDetails
  // ---------------------------------------------------------------------------

  group('getAllEntriesWithDetails', () {
    // Should return fully-populated SymptomEntryModel objects.
    test(
        'As a user, I expect loading my entries to include all details: mood, notes, symptoms with severity, and tags',
        () async {
      await db.saveEntry(
        dateTime: DateTime(2024, 1, 15, 10, 30),
        mood: '😊',
        notes: 'Morning entry',
        symptoms: [
          UserSymptomModel(id: -1, name: 'Headache', severity: 4),
          UserSymptomModel(id: -2, name: 'Nausea', severity: 2),
        ],
        tags: [
          UserTagModel(id: -1, name: 'After Meal'),
          UserTagModel(id: -2, name: 'At Work'),
        ],
      );

      final entries = await db.getAllEntriesWithDetails();
      expect(entries, hasLength(1));

      final entry = entries.first;
      expect(entry.mood, '😊');
      expect(entry.notes, 'Morning entry');
      expect(entry.symptoms, hasLength(2));
      expect(entry.tags, hasLength(2));
      expect(entry.symptoms.any((s) => s.name == 'Headache' && s.severity == 4),
          isTrue);
      expect(entry.symptoms.any((s) => s.name == 'Nausea' && s.severity == 2),
          isTrue);
    });

    // An empty database should return an empty list, not throw.
    test('As a user, I expect an empty list when I have no logged entries',
        () async {
      final entries = await db.getAllEntriesWithDetails();
      expect(entries, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // getAllSymptoms / getAllTags
  // ---------------------------------------------------------------------------

  group('getAllSymptoms', () {
    test('As a user, I expect loading symptoms to return proper model objects',
        () async {
      await db.addSymptom('Headache');
      await db.addSymptom('Nausea');

      final symptoms = await db.getAllSymptoms();
      expect(symptoms, hasLength(2));
      expect(symptoms.first, isA<UserSymptomModel>());
    });
  });

  group('getAllTags', () {
    test('As a user, I expect loading tags to return proper model objects',
        () async {
      await db.addTag('Work');
      await db.addTag('Exercise');

      final tags = await db.getAllTags();
      expect(tags, hasLength(2));
      expect(tags.first, isA<UserTagModel>());
    });
  });

  // ---------------------------------------------------------------------------
  // clearAllData
  // ---------------------------------------------------------------------------

  group('clearAllData', () {
    // Clearing should remove everything: entries, links, symptoms, and tags.
    test(
        'As a user, I expect Clear All Data to remove everything: entries, symptoms, tags, and all associations',
        () async {
      await db.saveEntry(
        dateTime: DateTime.now(),
        mood: '😊',
        symptoms: [UserSymptomModel(id: -1, name: 'Headache', severity: 3)],
        tags: [UserTagModel(id: -1, name: 'Work')],
      );

      await db.clearAllData();

      expect(await db.select(db.symptomEntries).get(), isEmpty);
      expect(await db.select(db.symptomEntryWithSymptom).get(), isEmpty);
      expect(await db.select(db.symptomEntryWithTag).get(), isEmpty);
      expect(await db.select(db.userSymptoms).get(), isEmpty);
      expect(await db.select(db.userTags).get(), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // deleteSymptom / deleteTag — default item protection (issue #8)
  // ---------------------------------------------------------------------------

  group('deleteSymptom — default item protection', () {
    // Default symptoms inserted via saveEntry should not be deletable.
    test(
        'As a user, I expect default symptoms to be protected from deletion so the app always has a baseline set',
        () async {
      // Use a known default symptom name.
      final defaultName = defaults.defaultSymptoms.first;
      final symptomId = await db.getOrCreateSymptom(defaultName);

      await db.deleteSymptom(symptomId);

      // The symptom should still exist after the delete attempt.
      final symptoms = await db.select(db.userSymptoms).get();
      expect(symptoms, hasLength(1));
      expect(symptoms.first.name, defaultName);
    });

    // Custom (non-default) symptoms should still be deletable.
    test('As a user, I expect to be able to delete custom symptoms I\'ve added',
        () async {
      final id = await db.addSymptom('CustomSymptom');

      await db.deleteSymptom(id);

      final symptoms = await db.select(db.userSymptoms).get();
      expect(symptoms, isEmpty);
    });
  });

  group('deleteTag — default item protection', () {
    // Default tags inserted via saveEntry should not be deletable.
    test(
        'As a user, I expect default tags to be protected from deletion so the app always has a baseline set',
        () async {
      final defaultName = defaults.defaultTags.first;
      final tagId = await db.getOrCreateTag(defaultName);

      await db.deleteTag(tagId);

      // The tag should still exist after the delete attempt.
      final tags = await db.select(db.userTags).get();
      expect(tags, hasLength(1));
      expect(tags.first.name, defaultName);
    });

    // Custom (non-default) tags should still be deletable.
    test('As a user, I expect to be able to delete custom tags I\'ve added',
        () async {
      final id = await db.addTag('CustomTag');

      await db.deleteTag(id);

      final tags = await db.select(db.userTags).get();
      expect(tags, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // getCustomSymptoms / getCustomTags — exclude defaults (issue #8)
  // ---------------------------------------------------------------------------

  group('getCustomSymptoms', () {
    // Should exclude symptoms whose names match defaults.
    test(
        'As a user, I expect the custom symptoms list to only show items I\'ve personally added, not defaults',
        () async {
      // Insert a default symptom via getOrCreate (simulates saveEntry flow).
      await db.getOrCreateSymptom(defaults.defaultSymptoms.first);
      // Insert a truly custom symptom.
      await db.addSymptom('CustomSymptom');

      final customs = await db.getCustomSymptoms();
      expect(customs, hasLength(1));
      expect(customs.first.name, 'CustomSymptom');
    });

    // An empty database should return an empty list.
    test(
        'As a user, I expect no custom symptoms to appear when I haven\'t added any',
        () async {
      for (final name in defaults.defaultSymptoms) {
        await db.getOrCreateSymptom(name);
      }

      final customs = await db.getCustomSymptoms();
      expect(customs, isEmpty);
    });
  });

  group('getCustomTags', () {
    // Should exclude tags whose names match defaults.
    test(
        'As a user, I expect the custom tags list to only show items I\'ve personally added, not defaults',
        () async {
      await db.getOrCreateTag(defaults.defaultTags.first);
      await db.addTag('CustomTag');

      final customs = await db.getCustomTags();
      expect(customs, hasLength(1));
      expect(customs.first.name, 'CustomTag');
    });

    test(
        'As a user, I expect no custom tags to appear when I haven\'t added any',
        () async {
      for (final name in defaults.defaultTags) {
        await db.getOrCreateTag(name);
      }

      final customs = await db.getCustomTags();
      expect(customs, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // getSummaryForDateRange (#45)
  // ---------------------------------------------------------------------------

  group('getSummaryForDateRange', () {
    test(
        'As a user, I expect the summary to only include entries within the specified date range',
        () async {
      // Entry inside range.
      await db.saveEntry(
        dateTime: DateTime(2026, 3, 3, 10, 0),
        mood: '😊',
        symptoms: [UserSymptomModel(id: -1, name: 'Headache', severity: 3)],
        tags: [UserTagModel(id: -1, name: 'At Work')],
      );
      // Entry outside range (before).
      await db.saveEntry(
        dateTime: DateTime(2026, 2, 15, 10, 0),
        mood: '😢',
        symptoms: [UserSymptomModel(id: -1, name: 'Nausea', severity: 4)],
        tags: [],
      );
      // Entry outside range (after).
      await db.saveEntry(
        dateTime: DateTime(2026, 4, 1, 10, 0),
        mood: '😐',
        symptoms: [UserSymptomModel(id: -1, name: 'Fatigue', severity: 2)],
        tags: [],
      );

      final summary = await db.getSummaryForDateRange(
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 31, 23, 59, 59),
      );

      expect(summary.totalEntries, 1);
      expect(summary.symptomFrequencies, hasLength(1));
      expect(summary.symptomFrequencies[0].name, 'Headache');
      expect(summary.tagFrequencies, hasLength(1));
      expect(summary.tagFrequencies[0].name, 'At Work');
    });

    test(
        'As a user, I expect an empty summary when no entries exist in the date range',
        () async {
      await db.saveEntry(
        dateTime: DateTime(2026, 1, 15, 10, 0),
        mood: '😊',
        symptoms: [UserSymptomModel(id: -1, name: 'Headache', severity: 3)],
        tags: [],
      );

      final summary = await db.getSummaryForDateRange(
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 31, 23, 59, 59),
      );

      expect(summary.totalEntries, 0);
      expect(summary.symptomFrequencies, isEmpty);
      expect(summary.moodDistribution, isEmpty);
      expect(summary.tagFrequencies, isEmpty);
    });

    test(
        'As a user, I expect the summary to correctly aggregate data from multiple entries',
        () async {
      await db.saveEntry(
        dateTime: DateTime(2026, 3, 1, 10, 0),
        mood: '😊',
        symptoms: [
          UserSymptomModel(id: -1, name: 'Headache', severity: 2),
          UserSymptomModel(id: -1, name: 'Nausea', severity: 3),
        ],
        tags: [UserTagModel(id: -1, name: 'After Meal')],
      );
      await db.saveEntry(
        dateTime: DateTime(2026, 3, 5, 14, 0),
        mood: '😢',
        symptoms: [
          UserSymptomModel(id: -1, name: 'Headache', severity: 4),
        ],
        tags: [UserTagModel(id: -1, name: 'After Meal')],
      );
      await db.saveEntry(
        dateTime: DateTime(2026, 3, 7, 8, 0),
        mood: '😊',
        symptoms: [],
        tags: [],
      );

      final summary = await db.getSummaryForDateRange(
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 7, 23, 59, 59),
      );

      expect(summary.totalEntries, 3);

      // Headache: 2 occurrences, avg severity (2+4)/2 = 3.0
      expect(summary.symptomFrequencies[0].name, 'Headache');
      expect(summary.symptomFrequencies[0].count, 2);
      expect(summary.symptomFrequencies[0].averageSeverity, 3.0);

      // Nausea: 1 occurrence
      expect(summary.symptomFrequencies[1].name, 'Nausea');
      expect(summary.symptomFrequencies[1].count, 1);

      // Mood distribution: 2 happy, 1 sad
      expect(summary.moodDistribution[0].emoji, '😊');
      expect(summary.moodDistribution[0].count, 2);
      expect(summary.moodDistribution[1].emoji, '😢');
      expect(summary.moodDistribution[1].count, 1);

      // Tag: After Meal appears 2 times
      expect(summary.tagFrequencies[0].name, 'After Meal');
      expect(summary.tagFrequencies[0].count, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // getLastSeverities (#48)
  // ---------------------------------------------------------------------------
  group('getLastSeverities', () {
    test(
        'As a user, I expect the app to remember the most recent severity I used for each symptom',
        () async {
      await db.saveEntry(
        dateTime: DateTime(2026, 3, 1, 10, 0),
        mood: '😊',
        symptoms: [UserSymptomModel(id: -1, name: 'Headache', severity: 2)],
        tags: [],
      );
      await db.saveEntry(
        dateTime: DateTime(2026, 3, 5, 10, 0),
        mood: '😢',
        symptoms: [UserSymptomModel(id: -1, name: 'Headache', severity: 4)],
        tags: [],
      );

      final severities = await db.getLastSeverities();
      expect(severities['Headache'], 4);
    });

    test(
        'As a user, I expect no severity history when I have no logged entries',
        () async {
      final severities = await db.getLastSeverities();
      expect(severities, isEmpty);
    });

    test(
        'As a user, I expect severity history to track multiple symptoms independently',
        () async {
      await db.saveEntry(
        dateTime: DateTime(2026, 3, 1, 10, 0),
        mood: '😊',
        symptoms: [
          UserSymptomModel(id: -1, name: 'Headache', severity: 3),
          UserSymptomModel(id: -1, name: 'Fatigue', severity: 1),
        ],
        tags: [],
      );

      final severities = await db.getLastSeverities();
      expect(severities['Headache'], 3);
      expect(severities['Fatigue'], 1);
    });
  });
}
