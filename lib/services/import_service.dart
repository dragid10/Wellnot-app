// import_service.dart: Data import from Wellnot JSON export format
//
// Parses JSON strings matching the format produced by ExportService.toJson(),
// validates the structure, and writes entries into the Drift database.
// Handles deduplication by date_time — entries with a matching timestamp in the
// database are skipped.
//
// Cross-ref:
//   - Export format: services/export_service.dart (toJson)
//   - Database writes: services/database.dart (saveEntry, getOrCreateSymptom/Tag)
//   - Models: models/symptom_models.dart (UserSymptomModel, UserTagModel)
//   - UI trigger: screens/settings/import_data_screen.dart

import 'dart:convert';

import 'package:archive/archive.dart';

import '../constants/defaults.dart';
import '../models/symptom_models.dart';
import 'database.dart';

/// Result of a JSON validation check.
class ImportValidation {
  /// Whether the JSON is valid and can be imported.
  final bool isValid;

  /// Number of entries found in the JSON.
  final int entryCount;

  /// Human-readable error messages (empty when valid).
  final List<String> errors;

  const ImportValidation({
    required this.isValid,
    required this.entryCount,
    required this.errors,
  });
}

/// Result of an import operation.
class ImportResult {
  /// Number of entries successfully imported.
  final int importedCount;

  /// Number of entries skipped (duplicates).
  final int skippedCount;

  const ImportResult({
    required this.importedCount,
    required this.skippedCount,
  });
}

/// Parses and imports Wellnot JSON export data into the database.
///
/// The expected JSON format matches [ExportService.toJson]:
/// ```json
/// {
///   "exported_at": "ISO8601",
///   "entries": [
///     {
///       "date_time": "ISO8601",
///       "mood": "...",
///       "notes": "...",
///       "symptoms": [{"name": "...", "severity": 1-5, "severity_label": "..."}],
///       "tags": ["Tag1", "Tag2"]
///     }
///   ]
/// }
/// ```
class ImportService {
  /// Decodes JSON and extracts the top-level `entries` list.
  ///
  /// Returns `(entries, errors)` — if the JSON structure is invalid, `entries`
  /// is `null` and `errors` describes the problems. Used by both [validate]
  /// and [importFromJson] to avoid duplicating parse logic.
  static (List<dynamic>?, List<String>) _decodeEntries(String jsonString) {
    final dynamic parsed;
    try {
      parsed = jsonDecode(jsonString);
    } on FormatException {
      return (null, const ['Invalid JSON format.']);
    }

    if (parsed is! Map<String, dynamic>) {
      return (null, const ['Expected a JSON object at the top level.']);
    }

    if (!parsed.containsKey('entries')) {
      return (null, const ['Missing required key: entries']);
    }

    final entriesRaw = parsed['entries'];
    if (entriesRaw is! List) {
      return (null, const ['The entries key must be a list.']);
    }

    return (entriesRaw, const []);
  }

  /// Validates a single entry map and returns a list of error strings.
  ///
  /// Checks all fields that the app enforces during manual entry creation:
  /// required date_time (parseable, not in the future), required mood (must be
  /// a known emoji), at least one symptom, and name length limits on symptoms
  /// and tags.
  static List<String> _validateEntry(
    Map<String, dynamic> entry,
    int index,
  ) {
    final errors = <String>[];

    // date_time is required, must be parseable, and must not be in the future.
    if (!entry.containsKey('date_time') || entry['date_time'] is! String) {
      errors.add('Entry $index: missing or invalid date_time');
    } else {
      final dateTimeParsed = DateTime.tryParse(entry['date_time'] as String);
      if (dateTimeParsed == null) {
        errors.add('Entry $index: date_time is not a valid ISO 8601 date');
      } else if (dateTimeParsed.isAfter(DateTime.now())) {
        errors.add('Entry $index: date_time is in the future');
      }
    }

    // mood is required and must be a known emoji from defaultMoods.
    if (!entry.containsKey('mood') || entry['mood'] is! String) {
      errors.add('Entry $index: missing or invalid mood');
    } else {
      final mood = entry['mood'] as String;
      if (!defaultMoods.contains(mood)) {
        errors.add('Entry $index: unrecognized mood "$mood"');
      }
    }

    // At least one symptom is required (matches in-app entry requirement).
    final symptoms = entry['symptoms'];
    if (symptoms == null || symptoms is! List || symptoms.isEmpty) {
      errors.add('Entry $index: at least one symptom is required');
    } else {
      // Validate symptom name lengths.
      for (var symptomIndex = 0;
          symptomIndex < symptoms.length;
          symptomIndex++) {
        final symptom = symptoms[symptomIndex];
        if (symptom is Map<String, dynamic> && symptom.containsKey('name')) {
          final name = symptom['name'] as String;
          if (name.length > maxItemNameLength) {
            errors.add(
              'Entry $index, symptom $symptomIndex: '
              'name exceeds $maxItemNameLength characters',
            );
          }
        }
      }
    }

    // Validate tag name lengths.
    final tags = entry['tags'];
    if (tags is List) {
      for (var tagIndex = 0; tagIndex < tags.length; tagIndex++) {
        final tag = tags[tagIndex];
        if (tag is String && tag.length > maxItemNameLength) {
          errors.add(
            'Entry $index, tag $tagIndex: '
            'name exceeds $maxItemNameLength characters',
          );
        }
      }
    }

    return errors;
  }

  /// Validates a JSON string against the expected Wellnot export format.
  ///
  /// Checks for:
  /// - Valid JSON syntax
  /// - Required top-level `entries` key (must be a list)
  /// - Required fields on each entry: `date_time` (parseable, not future),
  ///   `mood` (known emoji), at least one symptom
  /// - Name length limits on symptoms and tags
  ///
  /// Returns an [ImportValidation] with [isValid], [entryCount], and any
  /// [errors] found.
  static ImportValidation validate(String jsonString) {
    final (entriesRaw, parseErrors) = _decodeEntries(jsonString);
    if (entriesRaw == null) {
      return ImportValidation(
        isValid: false,
        entryCount: 0,
        errors: parseErrors,
      );
    }

    // Validate each entry.
    final List<String> errors = [];
    for (var index = 0; index < entriesRaw.length; index++) {
      final entry = entriesRaw[index];
      if (entry is! Map<String, dynamic>) {
        errors.add('Entry $index: expected a JSON object.');
        continue;
      }

      errors.addAll(_validateEntry(entry, index));
    }

    return ImportValidation(
      isValid: errors.isEmpty,
      entryCount: entriesRaw.length,
      errors: errors,
    );
  }

  /// Imports entries from a Wellnot JSON export string into [database].
  ///
  /// Entries with a `date_time` that already exists in the database are
  /// skipped (duplicate detection). Symptoms and tags are created
  /// automatically if they don't already exist (via [AppDatabase.saveEntry]
  /// which calls [AppDatabase.getOrCreateSymptom] / [getOrCreateTag]).
  ///
  /// Call [validate] first to check the JSON structure before importing.
  static Future<ImportResult> importFromJson(
    AppDatabase database,
    String jsonString,
  ) async {
    final (entriesRaw, _) = _decodeEntries(jsonString);
    if (entriesRaw == null || entriesRaw.isEmpty) {
      return const ImportResult(importedCount: 0, skippedCount: 0);
    }

    // Build a set of (dateTime, mood, notes) fingerprints for duplicate detection.
    // Multiple entries at the same date_time are valid (different moods/symptoms),
    // but re-importing the exact same entry should be skipped.
    final existingEntries = await database.getAllEntriesWithDetails();
    final existingFingerprints = existingEntries
        .map(
          (entry) => _entryFingerprint(
            dateTime: entry.dateTime,
            mood: entry.mood,
            symptomNames: entry.symptoms.map((s) => s.name).toList(),
            tagNames: entry.tags.map((t) => t.name).toList(),
            notes: entry.notes,
          ),
        )
        .toSet();

    var importedCount = 0;
    var skippedCount = 0;

    for (var index = 0; index < entriesRaw.length; index++) {
      final entryMap = entriesRaw[index] as Map<String, dynamic>;

      // Skip entries that fail validation (future dates, bad moods, etc.).
      final entryErrors = _validateEntry(entryMap, index);
      if (entryErrors.isNotEmpty) {
        skippedCount++;
        continue;
      }

      final dateTime = DateTime.parse(entryMap['date_time'] as String);
      final mood = entryMap['mood'] as String;
      final notes = entryMap['notes'] as String?;

      // Parse symptoms (already validated as non-empty by _validateEntry).
      final symptomsRaw = entryMap['symptoms'] as List;
      final symptoms = symptomsRaw.map((symptomRaw) {
        final symptomMap = symptomRaw as Map<String, dynamic>;
        final name = symptomMap['name'] as String;
        final rawSeverity = symptomMap['severity'] as int? ?? 3;
        final severity = rawSeverity.clamp(1, 5);
        return UserSymptomModel(id: 0, name: name, severity: severity);
      }).toList();

      // Parse tags (gracefully handle missing key).
      final tagsRaw = entryMap['tags'] as List? ?? [];
      final tags = tagsRaw
          .map((tagName) => UserTagModel(id: 0, name: tagName as String))
          .toList();

      // Skip duplicates (same date_time + mood + symptoms + tags + notes).
      final fingerprint = _entryFingerprint(
        dateTime: dateTime,
        mood: mood,
        symptomNames: symptoms.map((s) => s.name).toList(),
        tagNames: tags.map((t) => t.name).toList(),
        notes: notes,
      );
      if (existingFingerprints.contains(fingerprint)) {
        skippedCount++;
        continue;
      }

      await database.saveEntry(
        dateTime: dateTime,
        mood: mood,
        notes: notes,
        symptoms: symptoms,
        tags: tags,
      );

      existingFingerprints.add(fingerprint);
      importedCount++;
    }

    return ImportResult(
      importedCount: importedCount,
      skippedCount: skippedCount,
    );
  }

  /// Creates a fingerprint string for duplicate detection.
  ///
  /// Combines all entry fields (date_time, mood, symptoms, tags, notes) so
  /// that only truly identical entries are considered duplicates.
  static String _entryFingerprint({
    required DateTime dateTime,
    required String mood,
    required List<String> symptomNames,
    required List<String> tagNames,
    String? notes,
  }) {
    final normalizedNotes =
        (notes == null || notes.trim().isEmpty) ? '' : notes;
    final sortedSymptoms = List<String>.from(symptomNames)..sort();
    final sortedTags = List<String>.from(tagNames)..sort();
    return '${dateTime.toIso8601String()}|$mood|${sortedSymptoms.join(',')}|${sortedTags.join(',')}|$normalizedNotes';
  }

  /// Extracts the first `.json` file from a ZIP archive.
  ///
  /// Returns the JSON content as a string, or `null` if no `.json` file is
  /// found or the ZIP is invalid.
  static Future<String?> extractJsonFromZip(List<int> bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive.files) {
        if (file.name.endsWith('.json') && file.isFile) {
          return utf8.decode(file.content as List<int>);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
