// export_service.dart: Data export to CSV and JSON formats
//
// Converts symptom entry data into CSV or JSON strings, packages the result
// into a zip file, and opens the system save dialog so the user can choose
// where to save it (defaults to Downloads on Android, Files app on iOS).
//
// Cross-ref:
//   - Models: models/symptom_models.dart (SymptomEntryModel, UserSymptomModel)
//   - Database: services/database.dart (getAllEntriesWithDetails)
//   - UI trigger: screens/settings/export_data_screen.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../models/symptom_models.dart';

/// Supported export formats.
enum ExportFormat { csv, json }

/// Converts symptom entry data to CSV or JSON, packages into a zip file,
/// and opens the system save dialog for the user to choose a save location.
class ExportService {
  /// Converts entries to a CSV string.
  ///
  /// Format: Date, Time, Mood, Notes, Symptoms, Tags
  /// Symptoms are formatted as "Name (Severity Label)" separated by semicolons.
  /// Tags are semicolon-separated.
  static String toCsv(List<SymptomEntryModel> entries) {
    final buffer = StringBuffer();
    buffer.writeln('Date/Time,Mood,Notes,Symptoms,Tags');

    for (final entry in entries) {
      final dateTime = entry.dateTime.toIso8601String();

      final symptoms = entry.symptoms
          .map((s) => '${s.name} (${s.severity} - ${s.severityText})')
          .join('; ');

      final tags = entry.tags.map((t) => t.name).join('; ');

      buffer.writeln([
        _csvEscape(dateTime),
        _csvEscape(entry.mood),
        _csvEscape(entry.notes ?? ''),
        _csvEscape(symptoms),
        _csvEscape(tags),
      ].join(','));
    }

    return buffer.toString().trimRight();
  }

  /// Converts entries to a JSON string.
  ///
  /// Structure:
  /// ```json
  /// {
  ///   "exported_at": "2026-03-15T14:30:00.000",
  ///   "entries": [
  ///     {
  ///       "date": "2026-03-15",
  ///       "time": "14:30",
  ///       "mood": "...",
  ///       "notes": "...",
  ///       "symptoms": [{"name": "...", "severity": 3, "severity_label": "Moderate"}],
  ///       "tags": ["Tag1", "Tag2"]
  ///     }
  ///   ]
  /// }
  /// ```
  static String toJson(List<SymptomEntryModel> entries) {
    final data = {
      'exported_at': DateTime.now().toIso8601String(),
      'entries': entries.map((entry) {
        return {
          'date_time': entry.dateTime.toIso8601String(),
          'mood': entry.mood,
          'notes': entry.notes,
          'symptoms': entry.symptoms.map((s) {
            return {
              'name': s.name,
              'severity': s.severity,
              'severity_label': s.severityText,
            };
          }).toList(),
          'tags': entry.tags.map((t) => t.name).toList(),
        };
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Creates a zip file containing the exported data and opens the system
  /// save dialog so the user can choose where to save it (defaults to
  /// Downloads on Android, Files app on iOS).
  ///
  /// The zip file is named `wellnot-export-YYYY-MM-DD_HHmmss.zip` and
  /// contains a single file named `wellnot-data.csv` or `wellnot-data.json`.
  ///
  /// Returns the saved file path, or `null` if the user cancelled the dialog.
  static Future<String?> exportAndSave(
    List<SymptomEntryModel> entries,
    ExportFormat format,
  ) async {
    final content = switch (format) {
      ExportFormat.csv => toCsv(entries),
      ExportFormat.json => toJson(entries),
    };

    final extension = switch (format) {
      ExportFormat.csv => 'csv',
      ExportFormat.json => 'json',
    };

    final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    final innerFileName = 'wellnot-data.$extension';
    final zipName = 'wellnot-export-$extension-$timestamp.zip';

    final archive = Archive();
    final contentBytes = utf8.encode(content);
    archive.addFile(
      ArchiveFile(innerFileName, contentBytes.length, contentBytes),
    );

    final zipBytes = ZipEncoder().encode(archive);

    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Wellnot Export',
      fileName: zipName,
      bytes: Uint8List.fromList(zipBytes),
    );

    return savedPath;
  }

  /// Escapes a field for CSV output per RFC 4180.
  ///
  /// Wraps in double quotes if the field contains commas, quotes, or newlines.
  /// Internal double quotes are escaped by doubling them.
  static String _csvEscape(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
