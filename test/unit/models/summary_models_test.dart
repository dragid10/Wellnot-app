import 'package:flutter_test/flutter_test.dart';
import 'package:symptom_tracker_app/models/summary_models.dart';
import 'package:symptom_tracker_app/models/symptom_models.dart';

/// Unit tests for `lib/models/summary_models.dart`.
///
/// These test the pure-Dart [DateRangeSummary.fromEntries] computation logic
/// without any database or widget dependencies.
///
/// Cross-ref:
///   - Model under test: lib/models/summary_models.dart
///   - Entry model: lib/models/symptom_models.dart
void main() {
  final from = DateTime(2026, 3, 1);
  final to = DateTime(2026, 3, 7);

  group('DateRangeSummary.fromEntries', () {
    test(
        'As a user, I expect the summary to show the correct total entry count for a date range',
        () {
      final entries = [
        SymptomEntryModel(
          id: 1,
          dateTime: DateTime(2026, 3, 1, 10, 0),
          mood: '😊',
          symptoms: [],
          tags: [],
        ),
        SymptomEntryModel(
          id: 2,
          dateTime: DateTime(2026, 3, 2, 14, 0),
          mood: '😢',
          symptoms: [],
          tags: [],
        ),
        SymptomEntryModel(
          id: 3,
          dateTime: DateTime(2026, 3, 3, 8, 0),
          mood: '😊',
          symptoms: [],
          tags: [],
        ),
      ];

      final summary = DateRangeSummary.fromEntries(entries, from, to);

      expect(summary.totalEntries, 3);
      expect(summary.from, from);
      expect(summary.to, to);
    });

    test(
        'As a user, I expect an empty summary when there are no entries in the date range',
        () {
      final summary = DateRangeSummary.fromEntries([], from, to);

      expect(summary.totalEntries, 0);
      expect(summary.symptomFrequencies, isEmpty);
      expect(summary.tagFrequencies, isEmpty);
      expect(summary.moodDistribution, isEmpty);
    });

    test(
        'As a user, I expect symptoms to be ranked by frequency in the summary',
        () {
      final entries = [
        SymptomEntryModel(
          id: 1,
          dateTime: DateTime(2026, 3, 1),
          mood: '😊',
          symptoms: [
            UserSymptomModel(id: 1, name: 'Headache', severity: 3),
            UserSymptomModel(id: 2, name: 'Nausea', severity: 2),
          ],
          tags: [],
        ),
        SymptomEntryModel(
          id: 2,
          dateTime: DateTime(2026, 3, 2),
          mood: '😢',
          symptoms: [
            UserSymptomModel(id: 1, name: 'Headache', severity: 4),
          ],
          tags: [],
        ),
        SymptomEntryModel(
          id: 3,
          dateTime: DateTime(2026, 3, 3),
          mood: '😐',
          symptoms: [
            UserSymptomModel(id: 1, name: 'Headache', severity: 5),
            UserSymptomModel(id: 2, name: 'Nausea', severity: 3),
            UserSymptomModel(id: 3, name: 'Fatigue', severity: 1),
          ],
          tags: [],
        ),
      ];

      final summary = DateRangeSummary.fromEntries(entries, from, to);

      expect(summary.symptomFrequencies, hasLength(3));
      // Headache appears 3 times (most frequent).
      expect(summary.symptomFrequencies[0].name, 'Headache');
      expect(summary.symptomFrequencies[0].count, 3);
      // Nausea appears 2 times.
      expect(summary.symptomFrequencies[1].name, 'Nausea');
      expect(summary.symptomFrequencies[1].count, 2);
      // Fatigue appears 1 time.
      expect(summary.symptomFrequencies[2].name, 'Fatigue');
      expect(summary.symptomFrequencies[2].count, 1);
    });

    test(
        'As a user, I expect the summary to show the correct average severity for each symptom',
        () {
      final entries = [
        SymptomEntryModel(
          id: 1,
          dateTime: DateTime(2026, 3, 1),
          mood: '😊',
          symptoms: [
            UserSymptomModel(id: 1, name: 'Headache', severity: 2),
          ],
          tags: [],
        ),
        SymptomEntryModel(
          id: 2,
          dateTime: DateTime(2026, 3, 2),
          mood: '😢',
          symptoms: [
            UserSymptomModel(id: 1, name: 'Headache', severity: 4),
          ],
          tags: [],
        ),
      ];

      final summary = DateRangeSummary.fromEntries(entries, from, to);

      expect(summary.symptomFrequencies, hasLength(1));
      // Average of 2 and 4 = 3.0
      expect(summary.symptomFrequencies[0].averageSeverity, 3.0);
      expect(summary.symptomFrequencies[0].averageSeverityLabel, 'Moderate');
    });

    test(
        'As a user, I expect a symptom used once with severity 5 to show average severity 5.0',
        () {
      final entries = [
        SymptomEntryModel(
          id: 1,
          dateTime: DateTime(2026, 3, 1),
          mood: '😊',
          symptoms: [
            UserSymptomModel(id: 1, name: 'Migraine', severity: 5),
          ],
          tags: [],
        ),
      ];

      final summary = DateRangeSummary.fromEntries(entries, from, to);

      expect(summary.symptomFrequencies[0].averageSeverity, 5.0);
      expect(summary.symptomFrequencies[0].averageSeverityLabel, 'Very Severe');
    });

    test(
        'As a user, I expect moods to be counted correctly in the summary distribution',
        () {
      final entries = [
        SymptomEntryModel(
          id: 1,
          dateTime: DateTime(2026, 3, 1),
          mood: '😊',
          symptoms: [],
          tags: [],
        ),
        SymptomEntryModel(
          id: 2,
          dateTime: DateTime(2026, 3, 2),
          mood: '😊',
          symptoms: [],
          tags: [],
        ),
        SymptomEntryModel(
          id: 3,
          dateTime: DateTime(2026, 3, 3),
          mood: '😢',
          symptoms: [],
          tags: [],
        ),
      ];

      final summary = DateRangeSummary.fromEntries(entries, from, to);

      expect(summary.moodDistribution, hasLength(2));
      // Sorted by count descending.
      expect(summary.moodDistribution[0].emoji, '😊');
      expect(summary.moodDistribution[0].count, 2);
      expect(summary.moodDistribution[1].emoji, '😢');
      expect(summary.moodDistribution[1].count, 1);
    });

    test('As a user, I expect tags to be ranked by frequency in the summary',
        () {
      final entries = [
        SymptomEntryModel(
          id: 1,
          dateTime: DateTime(2026, 3, 1),
          mood: '😊',
          symptoms: [],
          tags: [
            UserTagModel(id: 1, name: 'After Meal'),
            UserTagModel(id: 2, name: 'At Work'),
          ],
        ),
        SymptomEntryModel(
          id: 2,
          dateTime: DateTime(2026, 3, 2),
          mood: '😢',
          symptoms: [],
          tags: [
            UserTagModel(id: 1, name: 'After Meal'),
          ],
        ),
      ];

      final summary = DateRangeSummary.fromEntries(entries, from, to);

      expect(summary.tagFrequencies, hasLength(2));
      expect(summary.tagFrequencies[0].name, 'After Meal');
      expect(summary.tagFrequencies[0].count, 2);
      expect(summary.tagFrequencies[1].name, 'At Work');
      expect(summary.tagFrequencies[1].count, 1);
    });

    test(
        'As a user, I expect symptoms with equal frequency to be sorted alphabetically',
        () {
      final entries = [
        SymptomEntryModel(
          id: 1,
          dateTime: DateTime(2026, 3, 1),
          mood: '😊',
          symptoms: [
            UserSymptomModel(id: 1, name: 'Nausea', severity: 3),
            UserSymptomModel(id: 2, name: 'Fatigue', severity: 2),
            UserSymptomModel(id: 3, name: 'Headache', severity: 4),
          ],
          tags: [],
        ),
      ];

      final summary = DateRangeSummary.fromEntries(entries, from, to);

      // All have count 1, so should be alphabetical.
      expect(summary.symptomFrequencies[0].name, 'Fatigue');
      expect(summary.symptomFrequencies[1].name, 'Headache');
      expect(summary.symptomFrequencies[2].name, 'Nausea');
    });

    test(
        'As a user, I expect symptoms appearing in multiple entries to be aggregated correctly',
        () {
      final entries = [
        SymptomEntryModel(
          id: 1,
          dateTime: DateTime(2026, 3, 1),
          mood: '😊',
          symptoms: [
            UserSymptomModel(id: 1, name: 'Headache', severity: 1),
            UserSymptomModel(id: 2, name: 'Headache', severity: 3),
          ],
          tags: [],
        ),
      ];

      final summary = DateRangeSummary.fromEntries(entries, from, to);

      // Same symptom name appears twice in one entry — both should be counted.
      expect(summary.symptomFrequencies[0].name, 'Headache');
      expect(summary.symptomFrequencies[0].count, 2);
      expect(summary.symptomFrequencies[0].averageSeverity, 2.0);
    });
  });

  group('SymptomFrequency', () {
    test(
        'As a user, I expect the severity label to reflect the rounded average severity',
        () {
      // averageSeverity 2.4 rounds to 2 → "Mild"
      final sf = SymptomFrequency(
        name: 'Test',
        count: 5,
        averageSeverity: 2.4,
      );
      expect(sf.averageSeverityLabel, 'Mild');

      // averageSeverity 2.6 rounds to 3 → "Moderate"
      final sf2 = SymptomFrequency(
        name: 'Test',
        count: 5,
        averageSeverity: 2.6,
      );
      expect(sf2.averageSeverityLabel, 'Moderate');
    });
  });

  group('DateRangeOption', () {
    test(
        'As a user, I expect each date range option to have a human-readable label',
        () {
      expect(DateRangeOption.last7Days.label, 'Last 7 days');
      expect(DateRangeOption.last30Days.label, 'Last 30 days');
      expect(DateRangeOption.thisMonth.label, 'This month');
      expect(DateRangeOption.custom.label, 'Custom');
    });
  });
}
