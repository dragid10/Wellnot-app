import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart' as raw_sqlite;
import 'package:symptom_tracker_app/constants/defaults.dart';
import 'package:symptom_tracker_app/models/symptom_models.dart';
import 'package:symptom_tracker_app/services/database.dart';
import 'package:symptom_tracker_app/services/export_service.dart';
import 'package:symptom_tracker_app/services/import_service.dart';
import 'package:symptom_tracker_app/services/preferences_service.dart';

void _ensureSqlite3() {
  if (Platform.isLinux) {
    DynamicLibrary.open('libsqlite3.so.0');
  } else if (Platform.isMacOS) {
    DynamicLibrary.open('libsqlite3.dylib');
  }
}

void main() {
  _ensureSqlite3();

  group('Encryption migration failure recovery', () {
    late Directory tempDir;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('wellnot_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
      PreferencesService.encryptionMigrationFailedNotifier.value =
          defaultEncryptionMigrationFailed;
    });

    test(
        'As a user, I expect the migration failure flag to be false by default',
        () async {
      await PreferencesService.loadEncryptionMigrationFailed();
      expect(
        PreferencesService.encryptionMigrationFailedNotifier.value,
        isFalse,
      );
    });

    test(
        'As a user, I expect saving the migration failure flag to update the notifier',
        () async {
      await PreferencesService.saveEncryptionMigrationFailed(true);
      expect(
        PreferencesService.encryptionMigrationFailedNotifier.value,
        isTrue,
      );

      await PreferencesService.saveEncryptionMigrationFailed(false);
      expect(
        PreferencesService.encryptionMigrationFailedNotifier.value,
        isFalse,
      );
    });

    test(
        'As a user, I expect a plaintext database to be readable after migration failure',
        () async {
      // Create a plaintext SQLite DB with the app's schema.
      final dbPath = '${tempDir.path}/test.sqlite';
      final rawDb = raw_sqlite.sqlite3.open(dbPath);
      rawDb.execute('''
        CREATE TABLE symptom_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entry_date_time INTEGER NOT NULL,
          mood TEXT NOT NULL,
          notes TEXT
        )
      ''');
      rawDb.execute('''
        CREATE TABLE user_symptoms (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');
      rawDb.execute('''
        CREATE TABLE user_tags (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');
      rawDb.execute('''
        CREATE TABLE symptom_entry_with_symptom (
          symptom_entry_id INTEGER NOT NULL REFERENCES symptom_entries(id),
          user_symptom_id INTEGER NOT NULL REFERENCES user_symptoms(id),
          severity INTEGER NOT NULL DEFAULT 3
        )
      ''');
      rawDb.execute('''
        CREATE TABLE symptom_entry_with_tag (
          symptom_entry_id INTEGER NOT NULL REFERENCES symptom_entries(id),
          user_tag_id INTEGER NOT NULL REFERENCES user_tags(id)
        )
      ''');
      // Set schema version to 2 (current).
      rawDb.execute('PRAGMA user_version = 2');

      // Insert test data.
      rawDb.execute("INSERT INTO user_symptoms (name) VALUES ('Headache')");
      rawDb.execute("INSERT INTO user_tags (name) VALUES ('Work')");
      rawDb.execute("INSERT INTO symptom_entries (entry_date_time, mood) "
          "VALUES (${DateTime.now().millisecondsSinceEpoch ~/ 1000}, "
          "'\u{1F60A}')");
      rawDb.execute('INSERT INTO symptom_entry_with_symptom '
          '(symptom_entry_id, user_symptom_id, severity) VALUES (1, 1, 3)');
      rawDb.execute('INSERT INTO symptom_entry_with_tag '
          '(symptom_entry_id, user_tag_id) VALUES (1, 1)');
      rawDb.close();

      // Verify the file is plaintext (has standard SQLite header).
      final file = File(dbPath);
      final header = file.readAsBytesSync().sublist(0, 16);
      final expectedHeader = 'SQLite format 3\x00'.codeUnits;
      expect(header, equals(expectedHeader));

      // Open it as a Drift database (simulating the fallback path).
      final db = AppDatabase.forTesting(NativeDatabase(file));
      final entries = await db.getAllEntriesWithDetails();

      expect(entries.length, equals(1));
      expect(entries.first.mood, equals('\u{1F60A}'));
      expect(entries.first.symptoms.length, equals(1));
      expect(entries.first.symptoms.first.name, equals('Headache'));
      expect(entries.first.symptoms.first.severity, equals(3));
      expect(entries.first.tags.length, equals(1));
      expect(entries.first.tags.first.name, equals('Work'));

      await db.close();
    });

    test(
        'As a user, I expect my data to survive the full export-reset-import cycle',
        () async {
      // Create a DB with test data.
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.saveEntry(
        dateTime: DateTime(2026, 4, 18, 10, 30),
        mood: '\u{1F60A}',
        notes: 'Test entry for recovery',
        symptoms: [
          UserSymptomModel(id: 0, name: 'Headache', severity: 4),
          UserSymptomModel(id: 0, name: 'Fatigue', severity: 2),
        ],
        tags: [
          UserTagModel(id: 0, name: 'Work'),
          UserTagModel(id: 0, name: 'Stress'),
        ],
      );
      await db.saveEntry(
        dateTime: DateTime(2026, 4, 17, 8, 0),
        mood: '\u{1F622}',
        notes: 'Second test entry',
        symptoms: [
          UserSymptomModel(id: 0, name: 'Nausea', severity: 5),
        ],
        tags: [
          UserTagModel(id: 0, name: 'Travel'),
        ],
      );

      // Export to JSON.
      final entries = await db.getAllEntriesWithDetails();
      expect(entries.length, equals(2));

      final jsonString = ExportService.toJson(entries);
      await db.close();

      // Create a fresh DB (simulating post-reset state).
      final freshDb = AppDatabase.forTesting(NativeDatabase.memory());

      // Validate first.
      final validation = ImportService.validate(jsonString);
      expect(validation.isValid, isTrue,
          reason: 'Validation errors: ${validation.errors}');
      expect(validation.entryCount, equals(2));

      // Import the exported data.
      final result = await ImportService.importFromJson(freshDb, jsonString);
      expect(result.importedCount, equals(2),
          reason: 'Skipped: ${result.skippedCount}');

      // Verify all data survived the round-trip.
      final restored = await freshDb.getAllEntriesWithDetails();
      expect(restored.length, equals(2));

      final entry1 = restored
          .firstWhere((entry) => entry.notes == 'Test entry for recovery');
      expect(entry1.mood, equals('\u{1F60A}'));
      expect(entry1.symptoms.length, equals(2));
      expect(
        entry1.symptoms.map((symptom) => symptom.name).toSet(),
        equals({'Headache', 'Fatigue'}),
      );
      expect(
        entry1.symptoms
            .firstWhere((symptom) => symptom.name == 'Headache')
            .severity,
        equals(4),
      );
      expect(
        entry1.tags.map((tag) => tag.name).toSet(),
        equals({'Work', 'Stress'}),
      );

      final entry2 =
          restored.firstWhere((entry) => entry.notes == 'Second test entry');
      expect(entry2.mood, equals('\u{1F622}'));
      expect(entry2.symptoms.length, equals(1));
      expect(entry2.symptoms.first.name, equals('Nausea'));
      expect(entry2.symptoms.first.severity, equals(5));
      expect(entry2.tags.length, equals(1));
      expect(entry2.tags.first.name, equals('Travel'));

      await freshDb.close();
    });

    test(
        'As a user, I expect the migration failure flag to be cleared after recovery',
        () async {
      // Set the flag.
      await PreferencesService.saveEncryptionMigrationFailed(true);
      expect(
        PreferencesService.encryptionMigrationFailedNotifier.value,
        isTrue,
      );

      // Clear it (simulating successful recovery).
      await PreferencesService.saveEncryptionMigrationFailed(false);
      expect(
        PreferencesService.encryptionMigrationFailedNotifier.value,
        isFalse,
      );

      // Verify it persists as false after reload.
      await PreferencesService.loadEncryptionMigrationFailed();
      expect(
        PreferencesService.encryptionMigrationFailedNotifier.value,
        isFalse,
      );
    });
  });
}
