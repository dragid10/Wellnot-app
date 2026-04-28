import 'package:flutter_test/flutter_test.dart';
import 'package:symptom_tracker_app/constants/defaults.dart';
import 'package:symptom_tracker_app/models/symptom_models.dart';

/// Unit tests for the plain Dart model classes in `lib/models/symptom_models.dart`.
///
/// These models are the app-level data objects used by screens and services.
/// They are intentionally separate from Drift-generated classes.
void main() {
  // ---------------------------------------------------------------------------
  // UserSymptomModel
  // ---------------------------------------------------------------------------
  group('UserSymptomModel', () {
    // Verify the constructor default so callers don't need to specify severity.
    test(
        'As a user, I expect new symptoms to default to Moderate (3) severity when no severity is specified',
        () {
      final symptom = UserSymptomModel(id: 1, name: 'Headache');
      expect(symptom.severity, 3);
    });

    // Equality is based on all three fields — important for list operations
    // like `contains()` and `indexOf()` used in entry_screen.dart.
    test(
        'As a user, I expect two symptoms with the same id, name, and severity to be treated as equal',
        () {
      final a = UserSymptomModel(id: 1, name: 'Headache', severity: 2);
      final b = UserSymptomModel(id: 1, name: 'Headache', severity: 2);
      final c = UserSymptomModel(id: 1, name: 'Headache', severity: 4);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    // Hash-based collections (Set, Map keys) rely on consistent hashCode.
    test(
        'As a user, I expect equal symptoms to work correctly in collections — consistent hashCode with equality',
        () {
      final a = UserSymptomModel(id: 1, name: 'Headache', severity: 2);
      final b = UserSymptomModel(id: 1, name: 'Headache', severity: 2);

      expect(a.hashCode, equals(b.hashCode));
    });

    // copyWith is used in symptom_entry_widget.dart when the user adjusts severity.
    test(
        'As a user, I expect adjusting a symptom\'s severity to preserve its name and id',
        () {
      final original = UserSymptomModel(id: 1, name: 'Headache', severity: 2);
      final copy = original.copyWith(severity: 5);

      expect(copy.id, 1);
      expect(copy.name, 'Headache');
      expect(copy.severity, 5);
    });

    // Calling copyWith() without arguments should return an equivalent object.
    test(
        'As a user, I expect copying a symptom without changes to produce an identical copy',
        () {
      final original = UserSymptomModel(id: 1, name: 'Headache', severity: 2);
      final copy = original.copyWith();

      expect(copy, equals(original));
    });

    // severityText delegates to severityLabel(); both must agree and cover 1–5.
    test(
        'As a user, I expect severity levels 1-5 to display as Very Mild, Mild, Moderate, Severe, Very Severe',
        () {
      expect(UserSymptomModel(id: 1, name: 'T', severity: 1).severityText,
          'Very Mild');
      expect(
          UserSymptomModel(id: 1, name: 'T', severity: 2).severityText, 'Mild');
      expect(UserSymptomModel(id: 1, name: 'T', severity: 3).severityText,
          'Moderate');
      expect(UserSymptomModel(id: 1, name: 'T', severity: 4).severityText,
          'Severe');
      expect(UserSymptomModel(id: 1, name: 'T', severity: 5).severityText,
          'Very Severe');
    });

    // Static helper used by severity_selector.dart — must match severityText.
    test(
        'As a user, I expect the static severity label helper to return the same canonical labels for 1-5',
        () {
      expect(UserSymptomModel.severityLabel(1), 'Very Mild');
      expect(UserSymptomModel.severityLabel(2), 'Mild');
      expect(UserSymptomModel.severityLabel(3), 'Moderate');
      expect(UserSymptomModel.severityLabel(4), 'Severe');
      expect(UserSymptomModel.severityLabel(5), 'Very Severe');
    });

    // Out-of-range severity should return 'Unknown' rather than crashing.
    test(
        'As a user, I expect out-of-range severity values to display as Unknown instead of crashing',
        () {
      expect(UserSymptomModel.severityLabel(0), 'Unknown');
      expect(UserSymptomModel.severityLabel(6), 'Unknown');
    });
  });

  // ---------------------------------------------------------------------------
  // UserTagModel
  // ---------------------------------------------------------------------------
  group('UserTagModel', () {
    // Tags are compared by id + name; used for chip selection state in UI.
    test(
        'As a user, I expect two tags with the same id and name to be treated as equal',
        () {
      final a = UserTagModel(id: 1, name: 'Work');
      final b = UserTagModel(id: 1, name: 'Work');
      final c = UserTagModel(id: 2, name: 'Exercise');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test(
        'As a user, I expect equal tags to work correctly in collections — consistent hashCode with equality',
        () {
      final a = UserTagModel(id: 1, name: 'Work');
      final b = UserTagModel(id: 1, name: 'Work');

      expect(a.hashCode, equals(b.hashCode));
    });
  });

  // ---------------------------------------------------------------------------
  // SymptomEntryModel
  // ---------------------------------------------------------------------------
  group('SymptomEntryModel', () {
    // Verify all fields are stored correctly after construction.
    test(
        'As a user, I expect all entry fields (id, date, mood, notes, symptoms, tags) to be stored when creating an entry',
        () {
      final symptoms = [
        UserSymptomModel(id: 1, name: 'Headache', severity: 4),
      ];
      final tags = [UserTagModel(id: 1, name: 'Work')];
      final now = DateTime.now();

      final entry = SymptomEntryModel(
        id: 1,
        dateTime: now,
        mood: '😊',
        notes: 'Feeling okay',
        symptoms: symptoms,
        tags: tags,
      );

      expect(entry.id, 1);
      expect(entry.dateTime, now);
      expect(entry.mood, '😊');
      expect(entry.notes, 'Feeling okay');
      expect(entry.symptoms, symptoms);
      expect(entry.tags, tags);
    });

    // Notes are optional — make sure null is preserved.
    test(
        'As a user, I expect entries without notes to work correctly since notes are optional',
        () {
      final entry = SymptomEntryModel(
        id: 1,
        dateTime: DateTime.now(),
        mood: '😐',
        symptoms: [],
        tags: [],
      );

      expect(entry.notes, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Default constants (from constants/defaults.dart)
  // ---------------------------------------------------------------------------
  group('Default constants', () {
    // Default symptom list should contain the expected built-in symptoms.
    test(
        'As a user, I expect to see a predefined set of default symptoms sorted alphabetically',
        () {
      expect(defaultSymptoms, contains('Headache'));
      expect(defaultSymptoms, contains('Nausea'));
      expect(defaultSymptoms, contains('Fatigue'));
      expect(defaultSymptoms, contains('Dizziness'));
      expect(defaultSymptoms, contains('Dry mouth'));
      expect(defaultSymptoms, contains('Fever'));
      expect(defaultSymptoms.length, 6);
      // Verify sorted order.
      final sorted = List<String>.from(defaultSymptoms)..sort();
      expect(defaultSymptoms, equals(sorted));
    });

    // Default tag list should contain the expected built-in tags.
    test(
        'As a user, I expect to see a predefined set of default tags sorted alphabetically',
        () {
      expect(defaultTags, contains('After Meal'));
      expect(defaultTags, contains('Exercise'));
      expect(defaultTags, contains('Took Medication'));
      expect(defaultTags, contains('Poor Sleep'));
      expect(defaultTags, contains('High Stress'));
      expect(defaultTags, contains('Dehydrated'));
      expect(defaultTags, contains('Travel'));
      expect(defaultTags, isNot(contains('Chronic')));
      expect(defaultTags, isNot(contains('Urgent')));
      expect(defaultTags.length, 19);
      final sorted = List<String>.from(defaultTags)..sort();
      expect(defaultTags, equals(sorted));
    });

    // Moods list should have all 17 emojis.
    test(
        'As a user, I expect to see 17 mood emoji options including common emotions',
        () {
      expect(defaultMoods.length, 17);
      expect(defaultMoods, contains('😊'));
      expect(defaultMoods, contains('😐'));
      expect(defaultMoods, contains('😰'));
      expect(defaultMoods, contains('🤕'));
      expect(defaultMoods, contains('🙃'));
    });
  });
}
