// filtered_entries_screen.dart: Shows entries matching a summary filter
//
// Displays a list of symptom entries filtered by a specific symptom or tag
// from the date range summary. Entries are passed in directly (pre-filtered
// by the summary screen) to avoid an extra DB query.
//
// Cross-ref:
//   - Navigated to from screens/summary_screen.dart
//   - Navigates to screens/detail_screen.dart on entry tap
//   - Entry model: models/symptom_models.dart (SymptomEntryModel)
//   - Layout constants: constants/layout.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/layout.dart';
import '../models/symptom_models.dart';
import 'detail_screen.dart';

/// Screen showing entries filtered by a specific symptom or tag.
///
/// Takes pre-filtered entries from the summary screen rather than
/// re-querying the database.
class FilteredEntriesScreen extends StatelessWidget {
  final String filterName;
  final List<SymptomEntryModel> entries;

  const FilteredEntriesScreen({
    super.key,
    required this.filterName,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(filterName),
      ),
      body: SafeArea(
        top: false,
        child: entries.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(spacingXl),
                  child: Text(
                    'No entries found.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              )
            : ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return ListTile(
                    leading: Text(
                      DateFormat.yMMMd().format(entry.dateTime),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    title: Text(
                      '${entry.mood} - ${entry.symptoms.map((s) => s.name).join(', ')}',
                    ),
                    subtitle: entry.tags.isNotEmpty
                        ? Text(
                            entry.tags.map((t) => t.name).join(', '),
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        : null,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SymptomDetailScreen(entry: entry),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
