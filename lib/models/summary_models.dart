// summary_models.dart: Data models for the date range summary feature
//
// These models represent aggregated data computed from symptom entries
// over a date range. They are plain Dart classes — not Drift-generated.
//
// Cross-ref:
//   - Computed by DateRangeSummary.fromEntries() from entry data
//   - Consumed by screens/summary_screen.dart
//   - Consumed by services/database.dart (getSummaryForDateRange)
//   - Symptom severity labels: models/symptom_models.dart (UserSymptomModel.severityLabel)

import 'symptom_models.dart';

/// Aggregated summary of symptom entries within a date range.
///
/// Use [fromEntries] to compute a summary from a list of entries.
/// The summary includes symptom frequencies with average severity,
/// mood distribution, and tag frequencies — all ranked by count.
class DateRangeSummary {
  final DateTime from;
  final DateTime to;
  final int totalEntries;
  final List<SymptomFrequency> symptomFrequencies;
  final List<TagFrequency> tagFrequencies;
  final List<MoodCount> moodDistribution;

  DateRangeSummary({
    required this.from,
    required this.to,
    required this.totalEntries,
    required this.symptomFrequencies,
    required this.tagFrequencies,
    required this.moodDistribution,
  });

  /// Computes a summary from a list of entries within [from]..[to].
  ///
  /// Static factory so the computation logic can be unit-tested
  /// without a database instance.
  static DateRangeSummary fromEntries(
    List<SymptomEntryModel> entries,
    DateTime from,
    DateTime to,
  ) {
    // Symptom aggregation: name → (count, totalSeverity)
    final Map<String, _SymptomAccumulator> symptomMap = {};
    for (final entry in entries) {
      for (final symptom in entry.symptoms) {
        final acc = symptomMap.putIfAbsent(
          symptom.name,
          () => _SymptomAccumulator(),
        );
        acc.count++;
        acc.totalSeverity += symptom.severity;
      }
    }

    final symptomFrequencies = symptomMap.entries.map((e) {
      return SymptomFrequency(
        name: e.key,
        count: e.value.count,
        averageSeverity: e.value.totalSeverity / e.value.count,
      );
    }).toList();
    // Sort by count descending, then alphabetically for ties.
    symptomFrequencies.sort((a, b) {
      final countCmp = b.count.compareTo(a.count);
      if (countCmp != 0) return countCmp;
      return a.name.compareTo(b.name);
    });

    // Mood aggregation: emoji → count
    final Map<String, int> moodMap = {};
    for (final entry in entries) {
      moodMap[entry.mood] = (moodMap[entry.mood] ?? 0) + 1;
    }

    final moodDistribution = moodMap.entries.map((e) {
      return MoodCount(emoji: e.key, count: e.value);
    }).toList();
    // Sort by count descending.
    moodDistribution.sort((a, b) => b.count.compareTo(a.count));

    // Tag aggregation: name → count
    final Map<String, int> tagMap = {};
    for (final entry in entries) {
      for (final tag in entry.tags) {
        tagMap[tag.name] = (tagMap[tag.name] ?? 0) + 1;
      }
    }

    final tagFrequencies = tagMap.entries.map((e) {
      return TagFrequency(name: e.key, count: e.value);
    }).toList();
    // Sort by count descending, then alphabetically for ties.
    tagFrequencies.sort((a, b) {
      final countCmp = b.count.compareTo(a.count);
      if (countCmp != 0) return countCmp;
      return a.name.compareTo(b.name);
    });

    return DateRangeSummary(
      from: from,
      to: to,
      totalEntries: entries.length,
      symptomFrequencies: symptomFrequencies,
      tagFrequencies: tagFrequencies,
      moodDistribution: moodDistribution,
    );
  }
}

/// Accumulator for symptom frequency and severity totals.
class _SymptomAccumulator {
  int count = 0;
  int totalSeverity = 0;
}

/// A symptom's frequency and average severity across a date range.
class SymptomFrequency {
  final String name;
  final int count;
  final double averageSeverity;

  SymptomFrequency({
    required this.name,
    required this.count,
    required this.averageSeverity,
  });

  /// Returns the canonical severity label for the rounded average.
  String get averageSeverityLabel =>
      UserSymptomModel.severityLabel(averageSeverity.round());
}

/// A tag's frequency across a date range.
class TagFrequency {
  final String name;
  final int count;

  TagFrequency({
    required this.name,
    required this.count,
  });
}

/// A mood emoji and its count across a date range.
class MoodCount {
  final String emoji;
  final int count;

  MoodCount({
    required this.emoji,
    required this.count,
  });
}

/// Predefined date range options for the summary picker.
enum DateRangeOption {
  last7Days('Last 7 days'),
  last30Days('Last 30 days'),
  thisMonth('This month'),
  custom('Custom');

  final String label;
  const DateRangeOption(this.label);
}
