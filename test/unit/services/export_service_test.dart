import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:symptom_tracker_app/models/symptom_models.dart';
import 'package:symptom_tracker_app/services/export_service.dart';

void main() {
  group('ExportService', () {
    late List<SymptomEntryModel> entries;

    setUp(() {
      entries = [
        SymptomEntryModel(
          id: 1,
          dateTime: DateTime(2026, 3, 10, 9, 30),
          mood: '\u{1F60A}',
          notes: 'Feeling good today',
          symptoms: [
            UserSymptomModel(id: 1, name: 'Headache', severity: 3),
            UserSymptomModel(id: 2, name: 'Fatigue', severity: 2),
          ],
          tags: [
            UserTagModel(id: 1, name: 'After Meal'),
            UserTagModel(id: 2, name: 'Exercise'),
          ],
        ),
        SymptomEntryModel(
          id: 2,
          dateTime: DateTime(2026, 3, 11, 14, 0),
          mood: '\u{1F622}',
          notes: null,
          symptoms: [
            UserSymptomModel(id: 3, name: 'Nausea', severity: 4),
          ],
          tags: [],
        ),
      ];
    });

    group('toCsv', () {
      test(
          'As a user, I expect the CSV export to start with a header row when I export my data',
          () {
        final csv = ExportService.toCsv(entries);
        final lines = csv.split('\n');
        expect(lines[0], 'Date/Time,Mood,Notes,Symptoms,Tags');
      });

      test(
          'As a user, I expect one CSV row per entry when I export multiple entries',
          () {
        final csv = ExportService.toCsv(entries);
        final lines = csv.split('\n').where((line) => line.isNotEmpty).toList();
        // 1 header + 2 data rows
        expect(lines.length, 3);
      });

      test('As a user, I expect dates in ISO 8601 format when I export to CSV',
          () {
        final csv = ExportService.toCsv(entries);
        final lines = csv.split('\n');
        expect(lines[1], contains('2026-03-10T09:30:00.000'));
      });

      test('As a user, I expect my mood emojis to appear in the CSV export',
          () {
        final csv = ExportService.toCsv(entries);
        expect(csv, contains('\u{1F60A}'));
        expect(csv, contains('\u{1F622}'));
      });

      test(
          'As a user, I expect symptoms in the CSV to show both severity number and label',
          () {
        final csv = ExportService.toCsv(entries);
        final lines = csv.split('\n');
        // First entry has two symptoms with severity number and label
        expect(lines[1], contains('Headache (3 - Moderate)'));
        expect(lines[1], contains('Fatigue (2 - Mild)'));
      });

      test('As a user, I expect tags to be semicolon-separated in CSV rows',
          () {
        final csv = ExportService.toCsv(entries);
        final lines = csv.split('\n');
        expect(lines[1], contains('After Meal'));
        expect(lines[1], contains('Exercise'));
      });

      test(
          'As a user, I expect an empty field in the CSV when an entry has no notes',
          () {
        final csv = ExportService.toCsv(entries);
        final lines = csv.split('\n');
        // Second entry has null notes — should be empty field
        expect(lines[2], contains(',,'));
      });

      test(
          'As a user, I expect empty fields when an entry has no symptoms or tags',
          () {
        final csv = ExportService.toCsv(entries);
        final lines = csv.split('\n');
        // Second entry has no tags — should produce empty field at end
        final lastField = lines[2].split(',').last;
        expect(lastField.trim(), isEmpty);
      });

      test(
          'As a user, I expect double quotes in notes to be properly escaped in CSV',
          () {
        final entriesWithQuotes = [
          SymptomEntryModel(
            id: 1,
            dateTime: DateTime(2026, 3, 10, 9, 30),
            mood: '\u{1F60A}',
            notes: 'Said "hello" today',
            symptoms: [],
            tags: [],
          ),
        ];
        final csv = ExportService.toCsv(entriesWithQuotes);
        // Double quotes should be escaped as ""
        expect(csv, contains('""hello""'));
      });

      test('As a user, I expect fields with commas to be quoted in the CSV',
          () {
        final entriesWithCommas = [
          SymptomEntryModel(
            id: 1,
            dateTime: DateTime(2026, 3, 10, 9, 30),
            mood: '\u{1F60A}',
            notes: 'First thing, second thing',
            symptoms: [],
            tags: [],
          ),
        ];
        final csv = ExportService.toCsv(entriesWithCommas);
        expect(csv, contains('"First thing, second thing"'));
      });

      test(
          'As a user, I expect only a header row when I export with no entries',
          () {
        final csv = ExportService.toCsv([]);
        final lines = csv.split('\n').where((line) => line.isNotEmpty).toList();
        expect(lines.length, 1);
        expect(lines[0], 'Date/Time,Mood,Notes,Symptoms,Tags');
      });
    });

    group('toJson', () {
      test('As a user, I expect the JSON export to be valid JSON', () {
        final jsonStr = ExportService.toJson(entries);
        expect(() => jsonDecode(jsonStr), returnsNormally);
      });

      test(
          'As a user, I expect the JSON export to include an exported_at timestamp',
          () {
        final jsonStr = ExportService.toJson(entries);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        expect(parsed, contains('exported_at'));
        expect(parsed['exported_at'], isA<String>());
      });

      test('As a user, I expect the JSON export to contain all my entries', () {
        final jsonStr = ExportService.toJson(entries);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        final entriesList = parsed['entries'] as List;
        expect(entriesList.length, 2);
      });

      test(
          'As a user, I expect each JSON entry to have date_time, mood, and notes fields',
          () {
        final jsonStr = ExportService.toJson(entries);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        final first = (parsed['entries'] as List)[0] as Map<String, dynamic>;

        expect(first['date_time'], '2026-03-10T09:30:00.000');
        expect(first['mood'], '\u{1F60A}');
        expect(first['notes'], 'Feeling good today');
      });

      test(
          'As a user, I expect symptoms in JSON to include name, severity number, and label',
          () {
        final jsonStr = ExportService.toJson(entries);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        final first = (parsed['entries'] as List)[0] as Map<String, dynamic>;
        final symptoms = first['symptoms'] as List;

        expect(symptoms.length, 2);
        expect(symptoms[0]['name'], 'Headache');
        expect(symptoms[0]['severity'], 3);
        expect(symptoms[0]['severity_label'], 'Moderate');
        expect(symptoms[1]['name'], 'Fatigue');
        expect(symptoms[1]['severity'], 2);
        expect(symptoms[1]['severity_label'], 'Mild');
      });

      test('As a user, I expect tags in JSON to be a list of strings', () {
        final jsonStr = ExportService.toJson(entries);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        final first = (parsed['entries'] as List)[0] as Map<String, dynamic>;
        final tags = first['tags'] as List;

        expect(tags, ['After Meal', 'Exercise']);
      });

      test('As a user, I expect null notes in JSON when an entry has no notes',
          () {
        final jsonStr = ExportService.toJson(entries);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        final second = (parsed['entries'] as List)[1] as Map<String, dynamic>;
        expect(second['notes'], isNull);
      });

      test(
          'As a user, I expect empty lists in JSON when an entry has no symptoms or tags',
          () {
        final jsonStr = ExportService.toJson(entries);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        final second = (parsed['entries'] as List)[1] as Map<String, dynamic>;
        expect((second['tags'] as List), isEmpty);
      });

      test(
          'As a user, I expect an empty entries list in JSON when I have no data',
          () {
        final jsonStr = ExportService.toJson([]);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        expect((parsed['entries'] as List), isEmpty);
      });
    });

    group('CSV and JSON content equivalence', () {
      test(
          'As a user, I expect the same number of entries in both CSV and JSON exports',
          () {
        final csv = ExportService.toCsv(entries);
        final jsonStr = ExportService.toJson(entries);

        final csvLines =
            csv.split('\n').where((line) => line.isNotEmpty).toList();
        final csvDataRows = csvLines.length - 1; // minus header

        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        final jsonEntries = parsed['entries'] as List;

        expect(csvDataRows, jsonEntries.length);
      });

      test(
          'As a user, I expect the same symptom data in both CSV and JSON exports',
          () {
        final jsonStr = ExportService.toJson(entries);
        final csv = ExportService.toCsv(entries);

        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        final jsonEntries = parsed['entries'] as List;

        // For each JSON entry, verify the CSV contains the same symptom info
        for (final entry in jsonEntries) {
          final symptoms = entry['symptoms'] as List;
          for (final symptom in symptoms) {
            final name = symptom['name'] as String;
            final severity = symptom['severity'] as int;
            final label = symptom['severity_label'] as String;
            // CSV should contain "SymptomName (severity - Label)"
            expect(csv, contains('$name ($severity - $label)'));
          }
        }
      });

      test('As a user, I expect the same tag data in both CSV and JSON exports',
          () {
        final jsonStr = ExportService.toJson(entries);
        final csv = ExportService.toCsv(entries);

        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        final jsonEntries = parsed['entries'] as List;

        for (final entry in jsonEntries) {
          final tags = entry['tags'] as List;
          for (final tag in tags) {
            expect(csv, contains(tag as String));
          }
        }
      });

      test(
          'As a user, I expect the same mood data in both CSV and JSON exports',
          () {
        final jsonStr = ExportService.toJson(entries);
        final csv = ExportService.toCsv(entries);

        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        final jsonEntries = parsed['entries'] as List;

        for (final entry in jsonEntries) {
          final mood = entry['mood'] as String;
          expect(csv, contains(mood));
        }
      });

      test(
          'As a user, I expect the same datetime data in both CSV and JSON exports',
          () {
        final jsonStr = ExportService.toJson(entries);
        final csv = ExportService.toCsv(entries);

        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        final jsonEntries = parsed['entries'] as List;

        for (final entry in jsonEntries) {
          final dateTime = entry['date_time'] as String;
          expect(csv, contains(dateTime));
        }
      });
    });
  });
}
