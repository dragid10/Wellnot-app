import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symptom_tracker_app/services/database.dart';
import 'package:symptom_tracker_app/models/symptom_models.dart';
import 'package:symptom_tracker_app/services/export_service.dart';
import 'package:symptom_tracker_app/services/import_service.dart';

import '../../helpers/test_database.dart';

void main() {
  group('ImportService', () {
    late AppDatabase database;

    setUp(() {
      database = createTestDatabase();
    });

    tearDown(() async {
      await database.close();
    });

    // -----------------------------------------------------------------------
    // Validation
    // -----------------------------------------------------------------------

    group('validate', () {
      test(
          'As a user, I expect validation to pass when the JSON matches the export format',
          () {
        final json = _makeValidJson();
        final result = ImportService.validate(json);
        expect(result.isValid, isTrue);
        expect(result.entryCount, 2);
        expect(result.errors, isEmpty);
      });

      test('As a user, I expect validation to fail when the JSON is malformed',
          () {
        final result = ImportService.validate('not valid json {{{');
        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
      });

      test(
          'As a user, I expect validation to fail when the entries key is missing',
          () {
        final json = jsonEncode({'exported_at': '2026-03-15T14:30:00.000'});
        final result = ImportService.validate(json);
        expect(result.isValid, isFalse);
        expect(result.errors, contains(contains('entries')));
      });

      test('As a user, I expect validation to fail when entries is not a list',
          () {
        final json = jsonEncode({
          'exported_at': '2026-03-15T14:30:00.000',
          'entries': 'not a list',
        });
        final result = ImportService.validate(json);
        expect(result.isValid, isFalse);
      });

      test(
          'As a user, I expect validation to fail when an entry is missing date_time',
          () {
        final json = jsonEncode({
          'exported_at': '2026-03-15T14:30:00.000',
          'entries': [
            {'mood': 'Happy', 'symptoms': [], 'tags': []},
          ],
        });
        final result = ImportService.validate(json);
        expect(result.isValid, isFalse);
        expect(result.errors, contains(contains('date_time')));
      });

      test(
          'As a user, I expect validation to fail when an entry is missing mood',
          () {
        final json = jsonEncode({
          'exported_at': '2026-03-15T14:30:00.000',
          'entries': [
            {
              'date_time': '2026-03-10T09:30:00.000',
              'symptoms': [],
              'tags': [],
            },
          ],
        });
        final result = ImportService.validate(json);
        expect(result.isValid, isFalse);
        expect(result.errors, contains(contains('mood')));
      });

      test(
          'As a user, I expect validation to fail when date_time is not parseable',
          () {
        final json = jsonEncode({
          'exported_at': '2026-03-15T14:30:00.000',
          'entries': [
            {
              'date_time': 'not-a-date',
              'mood': 'Happy',
              'symptoms': [],
              'tags': [],
            },
          ],
        });
        final result = ImportService.validate(json);
        expect(result.isValid, isFalse);
        expect(result.errors, contains(contains('date_time')));
      });

      test(
          'As a user, I expect validation to pass when entries have optional fields missing',
          () {
        final json = jsonEncode({
          'exported_at': '2026-03-15T14:30:00.000',
          'entries': [
            {
              'date_time': '2026-03-10T09:30:00.000',
              'mood': '\u{1F60A}',
              'symptoms': [
                {'name': 'Headache', 'severity': 3},
              ],
              // notes and tags are optional
            },
          ],
        });
        final result = ImportService.validate(json);
        expect(result.isValid, isTrue);
        expect(result.entryCount, 1);
      });

      test('As a user, I expect validation to report the correct entry count',
          () {
        final json = _makeJsonWithEntryCount(5);
        final result = ImportService.validate(json);
        expect(result.isValid, isTrue);
        expect(result.entryCount, 5);
      });

      test('As a user, I expect validation to pass for an empty entries list',
          () {
        final json = jsonEncode({
          'exported_at': '2026-03-15T14:30:00.000',
          'entries': [],
        });
        final result = ImportService.validate(json);
        expect(result.isValid, isTrue);
        expect(result.entryCount, 0);
      });
    });

    // -----------------------------------------------------------------------
    // Import
    // -----------------------------------------------------------------------

    group('importFromJson', () {
      test(
          'As a user, I expect all entries to be imported into an empty database',
          () async {
        final json = _makeValidJson();
        final result = await ImportService.importFromJson(database, json);

        expect(result.importedCount, 2);
        expect(result.skippedCount, 0);

        final entries = await database.getAllEntriesWithDetails();
        expect(entries.length, 2);
      });

      test('As a user, I expect imported entries to preserve mood values',
          () async {
        final json = _makeValidJson();
        await ImportService.importFromJson(database, json);

        final entries = await database.getAllEntriesWithDetails();
        final moods = entries.map((entry) => entry.mood).toSet();
        expect(moods, containsAll(['\u{1F60A}', '\u{1F622}']));
      });

      test('As a user, I expect imported entries to preserve notes', () async {
        final json = _makeValidJson();
        await ImportService.importFromJson(database, json);

        final entries = await database.getAllEntriesWithDetails();
        final withNotes =
            entries.where((entry) => entry.notes == 'Feeling good today');
        expect(withNotes.length, 1);

        final withoutNotes = entries.where((entry) => entry.notes == null);
        expect(withoutNotes.length, 1);
      });

      test(
          'As a user, I expect imported entries to preserve symptom names and severities',
          () async {
        final json = _makeValidJson();
        await ImportService.importFromJson(database, json);

        final entries = await database.getAllEntriesWithDetails();
        final firstEntry = entries.firstWhere(
          (entry) => entry.dateTime == DateTime(2026, 3, 10, 9, 30),
        );

        expect(firstEntry.symptoms.length, 2);
        final headache = firstEntry.symptoms.firstWhere(
          (symptom) => symptom.name == 'Headache',
        );
        expect(headache.severity, 3);

        final fatigue = firstEntry.symptoms.firstWhere(
          (symptom) => symptom.name == 'Fatigue',
        );
        expect(fatigue.severity, 2);
      });

      test('As a user, I expect imported entries to preserve tag names',
          () async {
        final json = _makeValidJson();
        await ImportService.importFromJson(database, json);

        final entries = await database.getAllEntriesWithDetails();
        final firstEntry = entries.firstWhere(
          (entry) => entry.dateTime == DateTime(2026, 3, 10, 9, 30),
        );

        expect(firstEntry.tags.length, 2);
        final tagNames = firstEntry.tags.map((tag) => tag.name).toSet();
        expect(tagNames, containsAll(['After Meal', 'Exercise']));
      });

      test(
          'As a user, I expect imported entries to preserve date and time values',
          () async {
        final json = _makeValidJson();
        await ImportService.importFromJson(database, json);

        final entries = await database.getAllEntriesWithDetails();
        final dateTimes = entries.map((entry) => entry.dateTime).toSet();
        expect(dateTimes, contains(DateTime(2026, 3, 10, 9, 30)));
        expect(dateTimes, contains(DateTime(2026, 3, 11, 14, 0)));
      });

      test(
          'As a user, I expect duplicate entries to be skipped when re-importing the same file',
          () async {
        // Import once.
        final json = _makeValidJson();
        await ImportService.importFromJson(database, json);

        // Import the same data again.
        final result = await ImportService.importFromJson(database, json);
        expect(result.importedCount, 0);
        expect(result.skippedCount, 2);

        // Should still be only 2 entries total.
        final entries = await database.getAllEntriesWithDetails();
        expect(entries.length, 2);
      });

      test(
          'As a user, I expect only new entries to be imported when some already exist',
          () async {
        // Import first batch.
        final json = _makeValidJson();
        await ImportService.importFromJson(database, json);

        // Import with one new entry added.
        final jsonWithExtra = _makeJsonWithExtraEntry();
        final result =
            await ImportService.importFromJson(database, jsonWithExtra);
        expect(result.importedCount, 1);
        expect(result.skippedCount, 2);

        final entries = await database.getAllEntriesWithDetails();
        expect(entries.length, 3);
      });

      test(
          'As a user, I expect symptoms to be deduplicated by name when importing',
          () async {
        // Pre-create a symptom that will appear in the import.
        await database.addSymptom('Headache');

        final json = _makeValidJson();
        await ImportService.importFromJson(database, json);

        // Should reuse the existing "Headache" symptom, not create a duplicate.
        final symptoms = await database.getAllSymptoms();
        final headacheCount =
            symptoms.where((symptom) => symptom.name == 'Headache').length;
        expect(headacheCount, 1);
      });

      test('As a user, I expect tags to be deduplicated by name when importing',
          () async {
        // Pre-create a tag that will appear in the import.
        await database.addTag('Exercise');

        final json = _makeValidJson();
        await ImportService.importFromJson(database, json);

        // Should reuse the existing "Exercise" tag, not create a duplicate.
        final tags = await database.getAllTags();
        final exerciseCount =
            tags.where((tag) => tag.name == 'Exercise').length;
        expect(exerciseCount, 1);
      });

      test('As a user, I expect import to skip entries with no symptoms',
          () async {
        final json = jsonEncode({
          'exported_at': '2026-03-15T14:30:00.000',
          'entries': [
            {
              'date_time': '2026-03-10T09:30:00.000',
              'mood': '\u{1F60A}',
              'notes': null,
              'symptoms': [],
              'tags': [],
            },
          ],
        });
        final result = await ImportService.importFromJson(database, json);
        expect(result.importedCount, 0);
        expect(result.skippedCount, 1);

        final entries = await database.getAllEntriesWithDetails();
        expect(entries, isEmpty);
      });

      test(
          'As a user, I expect import to skip entries with missing symptoms key',
          () async {
        final json = jsonEncode({
          'exported_at': '2026-03-15T14:30:00.000',
          'entries': [
            {
              'date_time': '2026-03-10T09:30:00.000',
              'mood': '\u{1F60A}',
              // No symptoms or tags keys at all.
            },
          ],
        });
        final result = await ImportService.importFromJson(database, json);
        expect(result.importedCount, 0);
        expect(result.skippedCount, 1);

        final entries = await database.getAllEntriesWithDetails();
        expect(entries, isEmpty);
      });

      test(
          'As a user, I expect import to use default severity when severity is missing from a symptom',
          () async {
        final json = jsonEncode({
          'exported_at': '2026-03-15T14:30:00.000',
          'entries': [
            {
              'date_time': '2026-03-10T09:30:00.000',
              'mood': '\u{1F60A}',
              'symptoms': [
                {'name': 'Headache'},
              ],
              'tags': [],
            },
          ],
        });
        final result = await ImportService.importFromJson(database, json);
        expect(result.importedCount, 1);

        final entries = await database.getAllEntriesWithDetails();
        expect(entries.first.symptoms.first.severity, 3);
      });

      test(
          'As a user, I expect the import result to report zero entries for an empty import',
          () async {
        final json = jsonEncode({
          'exported_at': '2026-03-15T14:30:00.000',
          'entries': [],
        });
        final result = await ImportService.importFromJson(database, json);
        expect(result.importedCount, 0);
        expect(result.skippedCount, 0);
      });

      test(
          'As a user, I expect import to clamp severity values outside 1-5 range',
          () async {
        final json = jsonEncode({
          'exported_at': '2026-03-15T14:30:00.000',
          'entries': [
            {
              'date_time': '2026-03-10T09:30:00.000',
              'mood': '\u{1F60A}',
              'symptoms': [
                {'name': 'Headache', 'severity': 0},
                {'name': 'Fatigue', 'severity': 10},
              ],
              'tags': [],
            },
          ],
        });
        await ImportService.importFromJson(database, json);

        final entries = await database.getAllEntriesWithDetails();
        final headache = entries.first.symptoms
            .firstWhere((symptom) => symptom.name == 'Headache');
        final fatigue = entries.first.symptoms
            .firstWhere((symptom) => symptom.name == 'Fatigue');
        expect(headache.severity, 1);
        expect(fatigue.severity, 5);
      });
    });

    // -----------------------------------------------------------------------
    // ZIP extraction
    // -----------------------------------------------------------------------

    group('extractJsonFromZip', () {
      test(
          'As a user, I expect JSON to be extracted from a valid Wellnot export ZIP',
          () async {
        final jsonContent = _makeValidJson();
        final zipBytes = _makeZipWithJson(jsonContent);

        final extracted = await ImportService.extractJsonFromZip(zipBytes);
        expect(extracted, isNotNull);
        expect(extracted, jsonContent);
      });

      test('As a user, I expect null when the ZIP contains no JSON file',
          () async {
        final archive = Archive();
        final csvBytes = utf8.encode('Date/Time,Mood\n2026-03-10,Happy');
        archive.addFile(ArchiveFile('data.csv', csvBytes.length, csvBytes));
        final zipBytes = ZipEncoder().encode(archive);

        final extracted = await ImportService.extractJsonFromZip(zipBytes);
        expect(extracted, isNull);
      });

      test('As a user, I expect null when the ZIP bytes are invalid', () async {
        final extracted =
            await ImportService.extractJsonFromZip([0, 1, 2, 3, 4]);
        expect(extracted, isNull);
      });
    });

    // -----------------------------------------------------------------------
    // Round-trip: export then import
    // -----------------------------------------------------------------------

    group('export-import round trip', () {
      test(
          'As a user, I expect data to survive an export-then-import cycle with all fields intact',
          () async {
        // Create entries in the source database.
        await database.saveEntry(
          dateTime: DateTime(2026, 3, 10, 9, 30),
          mood: '\u{1F60A}',
          notes: 'Round trip test',
          symptoms: [
            UserSymptomModel(id: 0, name: 'Headache', severity: 4),
            UserSymptomModel(id: 0, name: 'Fatigue', severity: 1),
          ],
          tags: [
            UserTagModel(id: 0, name: 'Morning'),
            UserTagModel(id: 0, name: 'Exercise'),
          ],
        );
        await database.saveEntry(
          dateTime: DateTime(2026, 3, 11, 14, 0),
          mood: '\u{1F622}',
          notes: null,
          symptoms: [
            UserSymptomModel(id: 0, name: 'Nausea', severity: 5),
          ],
          tags: [],
        );

        // Export from source.
        final sourceEntries = await database.getAllEntriesWithDetails();
        final jsonStr = ExportService.toJson(sourceEntries);

        // Import into a fresh database.
        final targetDatabase = createTestDatabase();
        try {
          final result =
              await ImportService.importFromJson(targetDatabase, jsonStr);
          expect(result.importedCount, 2);

          // Verify all entries survived.
          final targetEntries = await targetDatabase.getAllEntriesWithDetails();
          expect(targetEntries.length, 2);

          // Find the entry with notes and verify all fields.
          final roundTripped = targetEntries.firstWhere(
            (entry) => entry.dateTime == DateTime(2026, 3, 10, 9, 30),
          );
          expect(roundTripped.mood, '\u{1F60A}');
          expect(roundTripped.notes, 'Round trip test');
          expect(roundTripped.symptoms.length, 2);
          expect(roundTripped.tags.length, 2);

          final headache = roundTripped.symptoms
              .firstWhere((symptom) => symptom.name == 'Headache');
          expect(headache.severity, 4);

          final fatigue = roundTripped.symptoms
              .firstWhere((symptom) => symptom.name == 'Fatigue');
          expect(fatigue.severity, 1);

          final tagNames = roundTripped.tags.map((tag) => tag.name).toSet();
          expect(tagNames, containsAll(['Morning', 'Exercise']));

          // Verify the null-notes entry.
          final noNotes = targetEntries.firstWhere(
            (entry) => entry.dateTime == DateTime(2026, 3, 11, 14, 0),
          );
          expect(noNotes.notes, isNull);
          expect(noNotes.mood, '\u{1F622}');
          expect(noNotes.symptoms.length, 1);
          expect(noNotes.symptoms.first.name, 'Nausea');
          expect(noNotes.symptoms.first.severity, 5);
        } finally {
          await targetDatabase.close();
        }
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Test data helpers
// ---------------------------------------------------------------------------

/// Generates a valid Wellnot export JSON string with two entries.
String _makeValidJson() {
  return const JsonEncoder.withIndent('  ').convert({
    'exported_at': '2026-03-15T14:30:00.000',
    'entries': [
      {
        'date_time': '2026-03-10T09:30:00.000',
        'mood': '\u{1F60A}',
        'notes': 'Feeling good today',
        'symptoms': [
          {'name': 'Headache', 'severity': 3, 'severity_label': 'Moderate'},
          {'name': 'Fatigue', 'severity': 2, 'severity_label': 'Mild'},
        ],
        'tags': ['After Meal', 'Exercise'],
      },
      {
        'date_time': '2026-03-11T14:00:00.000',
        'mood': '\u{1F622}',
        'notes': null,
        'symptoms': [
          {'name': 'Nausea', 'severity': 4, 'severity_label': 'Severe'},
        ],
        'tags': [],
      },
    ],
  });
}

/// Generates a valid JSON with the two standard entries plus one extra.
String _makeJsonWithExtraEntry() {
  return const JsonEncoder.withIndent('  ').convert({
    'exported_at': '2026-03-16T10:00:00.000',
    'entries': [
      {
        'date_time': '2026-03-10T09:30:00.000',
        'mood': '\u{1F60A}',
        'notes': 'Feeling good today',
        'symptoms': [
          {'name': 'Headache', 'severity': 3, 'severity_label': 'Moderate'},
          {'name': 'Fatigue', 'severity': 2, 'severity_label': 'Mild'},
        ],
        'tags': ['After Meal', 'Exercise'],
      },
      {
        'date_time': '2026-03-11T14:00:00.000',
        'mood': '\u{1F622}',
        'notes': null,
        'symptoms': [
          {'name': 'Nausea', 'severity': 4, 'severity_label': 'Severe'},
        ],
        'tags': [],
      },
      {
        'date_time': '2026-03-12T08:00:00.000',
        'mood': '\u{1F60A}',
        'notes': 'New entry',
        'symptoms': [
          {'name': 'Dizziness', 'severity': 2, 'severity_label': 'Mild'},
        ],
        'tags': ['Morning'],
      },
    ],
  });
}

/// Generates a valid JSON with [count] entries, each with a unique date_time.
String _makeJsonWithEntryCount(int count) {
  final entries = List.generate(count, (index) {
    return {
      'date_time': DateTime(2026, 3, 10 + index, 9, 0).toIso8601String(),
      'mood': '\u{1F60A}',
      'symptoms': [
        {'name': 'Headache', 'severity': 3},
      ],
      'tags': [],
    };
  });
  return jsonEncode({
    'exported_at': '2026-03-15T14:30:00.000',
    'entries': entries,
  });
}

/// Creates a ZIP archive containing a JSON file (matching the export format).
List<int> _makeZipWithJson(String jsonContent) {
  final archive = Archive();
  final contentBytes = utf8.encode(jsonContent);
  archive.addFile(
    ArchiveFile('wellnot-data.json', contentBytes.length, contentBytes),
  );
  return ZipEncoder().encode(archive);
}
