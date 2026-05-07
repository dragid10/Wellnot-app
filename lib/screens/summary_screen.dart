// summary_screen.dart: Date range summary view (#45)
//
// Shows aggregated statistics for a user-selected date range: total entries,
// mood distribution, top symptoms with average severity, and top tags.
// Tapping a symptom or tag navigates to a filtered entry list.
//
// Cross-ref:
//   - Navigated to from screens/calendar_screen.dart (insights button)
//   - Uses AppDatabase.getSummaryForDateRange() from services/database.dart
//   - Models: models/summary_models.dart (DateRangeSummary, etc.)
//   - Navigates to screens/filtered_entries_screen.dart on item tap
//   - Database obtained via Provider (see main.dart)
//   - Layout constants: constants/layout.dart, constants/summary.dart
//   - Date picker: widgets/adaptive_pickers.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../constants/layout.dart';
import '../constants/summary.dart';
import '../models/summary_models.dart';
import '../models/symptom_models.dart';
import '../services/achievement_service.dart';
import '../services/database.dart';
import '../services/preferences_service.dart';
import '../widgets/adaptive_pickers.dart';
import '../widgets/adaptive_segmented_control.dart';
import 'filtered_entries_screen.dart';

/// Summary screen — shows aggregated entry statistics for a date range.
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  late AppDatabase _database;
  bool _initialized = false;

  DateRangeOption _selectedRange = DateRangeOption.last7Days;
  late DateTime _customFrom;
  late DateTime _customTo;

  DateRangeSummary? _summary;
  bool _isLoading = true;

  /// Cached entries for the current date range, used for filtered navigation.
  List<SymptomEntryModel> _entries = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _customFrom = DateTime(now.year, now.month, 1);
    _customTo = now;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _database = context.read<AppDatabase>();
      _initialized = true;
      _loadSummary();
      _checkSummaryAchievement();
    }
  }

  /// Checks whether viewing the summary screen unlocks the Insight Seeker
  /// achievement.
  Future<void> _checkSummaryAchievement() async {
    if (!PreferencesService.achievementsEnabledNotifier.value) return;
    final unlocked = await AchievementService.checkAfterSummaryView(_database);
    if (unlocked.isNotEmpty) {
      notifyAchievementsUnlocked(unlocked);
    }
  }

  /// Resolves the current [_selectedRange] into a (from, to) pair.
  (DateTime, DateTime) _resolveDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selectedRange) {
      case DateRangeOption.last7Days:
        final from = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        return (from, today);
      case DateRangeOption.last30Days:
        final from = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 29));
        return (from, today);
      case DateRangeOption.thisMonth:
        final from = DateTime(now.year, now.month, 1);
        return (from, today);
      case DateRangeOption.custom:
        final toEnd = DateTime(
          _customTo.year,
          _customTo.month,
          _customTo.day,
          23,
          59,
          59,
        );
        return (_customFrom, toEnd);
    }
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);

    try {
      final (from, to) = _resolveDateRange();
      final entries = await _database.getEntriesForDateRange(from, to);
      final summary = DateRangeSummary.fromEntries(entries, from, to);

      if (mounted) {
        setState(() {
          _summary = summary;
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load summary: $e')),
        );
      }
    }
  }

  void _onRangeChanged(DateRangeOption option) {
    setState(() => _selectedRange = option);
    _loadSummary();
  }

  Future<void> _pickCustomDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom ? _customFrom : _customTo;

    final picked = await showAdaptiveDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000, 1, 1),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _customFrom = picked;
          // Ensure from <= to.
          if (_customFrom.isAfter(_customTo)) {
            _customTo = _customFrom;
          }
        } else {
          _customTo = picked;
          // Ensure from <= to.
          if (_customTo.isBefore(_customFrom)) {
            _customFrom = _customTo;
          }
        }
      });
      _loadSummary();
    }
  }

  /// Returns entries that contain a symptom with [name].
  List<SymptomEntryModel> _entriesWithSymptom(String name) {
    return _entries
        .where((e) => e.symptoms.any((s) => s.name == name))
        .toList();
  }

  /// Returns entries that contain a tag with [name].
  List<SymptomEntryModel> _entriesWithTag(String name) {
    return _entries.where((e) => e.tags.any((t) => t.name == name)).toList();
  }

  /// Returns a contextual empty state message based on the selected range.
  String _emptyStateMessage() {
    if (_selectedRange == DateRangeOption.thisMonth) {
      final dayOfMonth = DateTime.now().day;
      if (dayOfMonth <= 3) {
        return 'No entries yet this month. '
            'Log some entries and check back later!';
      }
      return 'No entries this month.';
    }
    return 'No entries in this date range.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Date range selector.
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: spacingLg,
                vertical: spacingSm,
              ),
              child: AdaptiveSegmentedControl<DateRangeOption>(
                segments: {
                  for (final option in DateRangeOption.values)
                    option: option.label,
                },
                selected: _selectedRange,
                onChanged: _onRangeChanged,
              ),
            ),
            // Custom date pickers — shown only when "Custom" is selected.
            if (_selectedRange == DateRangeOption.custom)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: spacingLg,
                  vertical: spacingSm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(DateFormat.yMMMd().format(_customFrom)),
                        onPressed: () => _pickCustomDate(isFrom: true),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: spacingSm),
                      child: Text('to'),
                    ),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(DateFormat.yMMMd().format(_customTo)),
                        onPressed: () => _pickCustomDate(isFrom: false),
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1),
            // Summary content.
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final summary = _summary;
    if (summary == null || summary.totalEntries == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(spacingXl),
          child: Text(
            _emptyStateMessage(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCard(summary),
          const SizedBox(height: spacingLg),
          if (summary.moodDistribution.isNotEmpty) ...[
            _buildSectionHeader('Mood Distribution'),
            const SizedBox(height: spacingSm),
            _buildMoodDistribution(summary),
            const SizedBox(height: spacingLg),
          ],
          if (summary.symptomFrequencies.isNotEmpty) ...[
            _buildSectionHeader('Top Symptoms'),
            const SizedBox(height: spacingSm),
            _buildSymptomList(summary),
            const SizedBox(height: spacingLg),
          ],
          if (summary.tagFrequencies.isNotEmpty) ...[
            _buildSectionHeader('Top Tags'),
            const SizedBox(height: spacingSm),
            _buildTagList(summary),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewCard(DateRangeSummary summary) {
    final dateFormat = DateFormat.yMMMd();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${summary.totalEntries} ${summary.totalEntries == 1 ? 'entry' : 'entries'}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: spacingXs),
            Text(
              '${dateFormat.format(summary.from)} - ${dateFormat.format(summary.to)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }

  Widget _buildMoodDistribution(DateRangeSummary summary) {
    final maxCount = summary.moodDistribution.first.count;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(spacingLg),
        child: Column(
          children: summary.moodDistribution.map((mood) {
            final fraction = maxCount > 0 ? mood.count / maxCount : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: spacingXs),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      mood.emoji,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: spacingSm),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(summaryMoodBarRadius),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: summaryMoodBarHeight,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: spacingSm),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${mood.count}',
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSymptomList(DateRangeSummary summary) {
    final items = summary.symptomFrequencies.take(summaryTopItemCount);

    return Card(
      child: Column(
        children: items.map((symptom) {
          return ListTile(
            title: Text(symptom.name),
            subtitle: Text(
              'Avg: ${symptom.averageSeverityLabel}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${symptom.count}x',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(width: spacingXs),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            onTap: () {
              final filtered = _entriesWithSymptom(symptom.name);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FilteredEntriesScreen(
                    filterName: symptom.name,
                    entries: filtered,
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTagList(DateRangeSummary summary) {
    final items = summary.tagFrequencies.take(summaryTopItemCount);

    return Card(
      child: Column(
        children: items.map((tag) {
          return ListTile(
            title: Text(tag.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${tag.count}x',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(width: spacingXs),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            onTap: () {
              final filtered = _entriesWithTag(tag.name);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FilteredEntriesScreen(
                    filterName: tag.name,
                    entries: filtered,
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
