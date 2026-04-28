// detail_screen.dart: Displays details for a single symptom entry
//
// Shows all information for a selected entry, allows editing and deletion.
// Symptom chips now include severity labels (e.g., "Headache (Severe)").
//
// Cross-ref:
//   - Receives SymptomEntryModel from calendar_screen.dart
//   - Navigates to entry_screen.dart for editing
//   - Uses AppDatabase.deleteEntry() from services/database.dart
//   - Database obtained via Provider (see main.dart)
//   - Layout constants: constants/layout.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/layout.dart';
import '../models/symptom_models.dart';
import '../services/database.dart';
import 'entry_screen.dart';

class SymptomDetailScreen extends StatelessWidget {
  final SymptomEntryModel entry;
  const SymptomDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat.yMMMd().format(entry.dateTime)),
        actions: [
          // Edit button in AppBar — iOS only (iOS doesn't use FABs).
          // Android uses a FloatingActionButton instead (see below).
          if (Theme.of(context).platform == TargetPlatform.iOS)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SymptomEntryScreen(entry: entry),
                  ),
                );
                if (result == true && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
          // "Log Similar" button — opens a new entry pre-filled with
          // the same symptoms, mood, and tags but with the current
          // date/time and empty notes. Creates a new entry, not an edit.
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Log Similar',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SymptomEntryScreen(
                    entry: entry,
                    duplicate: true,
                  ),
                ),
              );
              // Pop back to calendar if the duplicate was saved,
              // so the calendar refreshes with the new entry.
              if (result == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
          // Delete button — shows confirmation dialog.
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              // Capture DB reference before async gap to satisfy
              // use_build_context_synchronously lint.
              final database = context.read<AppDatabase>();
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog.adaptive(
                  title: const Text('Delete Entry?'),
                  content: const Text('This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await database.deleteEntry(entry.id);
                  if (context.mounted) Navigator.of(context).pop(true);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete entry: $e')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(spacingLg),
          children: [
            _buildDetailRow(
              'Time',
              DateFormat.jm().format(entry.dateTime),
              context,
            ),
            _buildDetailRow('Mood', entry.mood, context, isEmoji: true),
            _buildSymptomSection(context),
            if (entry.tags.isNotEmpty)
              _buildDetailSection(
                context,
                'Tags',
                entry.tags.map((t) => t.name).toList(),
              ),
            if (entry.notes != null && entry.notes!.isNotEmpty)
              _buildDetailRow('Notes', entry.notes!, context),
          ],
        ),
      ),
      // Edit FAB — Android only (Material Design pattern).
      // iOS uses an AppBar button instead (see above).
      floatingActionButton: Theme.of(context).platform == TargetPlatform.iOS
          ? null
          : FloatingActionButton(
              child: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SymptomEntryScreen(entry: entry),
                  ),
                );
                if (result == true && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
    );
  }

  /// Builds the symptoms section with severity labels shown on each chip.
  Widget _buildSymptomSection(BuildContext context) {
    if (entry.symptoms.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Symptoms', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: spacingSm),
        Wrap(
          spacing: chipSpacing,
          runSpacing: spacingXs,
          children: entry.symptoms.map((s) {
            return Chip(label: Text('${s.name} (${s.severityText})'));
          }).toList(),
        ),
        const SizedBox(height: spacingLg),
      ],
    );
  }

  Widget _buildDetailSection(
    BuildContext context,
    String title,
    List<String> items,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: spacingSm),
        Wrap(
          spacing: chipSpacing,
          runSpacing: spacingXs,
          children: items.map((item) => Chip(label: Text(item))).toList(),
        ),
        const SizedBox(height: spacingLg),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String displayValue,
    BuildContext context, {
    bool isEmoji = false,
  }) {
    final defaultFontSize =
        Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Use IntrinsicWidth so the label column sizes to its content
          // rather than a fixed pixel width. This scales across screen sizes.
          IntrinsicWidth(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: spacingLg * 4),
              child: Padding(
                padding: const EdgeInsets.only(right: spacingLg),
                child:
                    Text(label, style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: isEmoji
                  ? TextStyle(fontSize: defaultFontSize * emojiScaleSmall)
                  : Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
