// symptom_models.dart: Data models for symptom tracking
//
// This file defines the structures used to represent symptom entries, symptoms,
// and tags throughout the app. These are plain Dart classes — not Drift-generated.
//
// Default symptom, tag, and mood lists live in constants/defaults.dart — models
// represent data shape only, not default values.
//
// Cross-ref:
//   - Used by all screens (calendar, entry, detail, manage_items)
//   - Returned by helper methods in services/database.dart
//   - severityLabel() is consumed by widgets/severity_selector.dart
//   - Default lists: constants/defaults.dart

/// Data model for a single symptom entry, representing one log by the user.
///
/// Named `SymptomEntryModel` to avoid collision with the Drift-generated
/// `SymptomEntry` data class in `database.g.dart`.
class SymptomEntryModel {
  final int id;
  final DateTime dateTime;
  final String mood;
  final String? notes;
  final List<UserSymptomModel> symptoms;
  final List<UserTagModel> tags;

  SymptomEntryModel({
    required this.id,
    required this.dateTime,
    required this.mood,
    this.notes,
    required this.symptoms,
    required this.tags,
  });
}

/// Data model for a user-defined symptom, including severity.
class UserSymptomModel {
  final int id;
  final String name;

  /// Severity rating on a 1–5 scale (default 3 = Moderate).
  final int severity;

  UserSymptomModel({
    required this.id,
    required this.name,
    this.severity = 3,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSymptomModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          severity == other.severity;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ severity.hashCode;

  /// Returns the canonical severity label for this symptom's severity.
  String get severityText => severityLabel(severity);

  /// Maps a severity integer (1–5) to a human-readable label.
  ///
  /// Canonical labels: Very Mild, Mild, Moderate, Severe, Very Severe.
  /// Used by this model and by `widgets/severity_selector.dart`.
  static String severityLabel(int severity) {
    switch (severity) {
      case 1:
        return 'Very Mild';
      case 2:
        return 'Mild';
      case 3:
        return 'Moderate';
      case 4:
        return 'Severe';
      case 5:
        return 'Very Severe';
      default:
        return 'Unknown';
    }
  }

  /// Creates a copy of this symptom with updated fields.
  UserSymptomModel copyWith({int? severity}) {
    return UserSymptomModel(
      id: id,
      name: name,
      severity: severity ?? this.severity,
    );
  }
}

/// Data model for a user-defined tag.
class UserTagModel {
  final int id;
  final String name;

  UserTagModel({
    required this.id,
    required this.name,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserTagModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
