// symptom_entry_widget.dart: Widget for displaying and editing a symptom entry
//
// Shows the symptom name, allows severity adjustment, and optionally provides
// a remove button. Used in entry forms for editable contexts.
//
// Cross-ref:
//   - Layout constants: constants/layout.dart
//   - Severity selector: widgets/severity_selector.dart
//   - Models: models/symptom_models.dart
//   - Used in: screens/entry_screen.dart

import 'package:flutter/material.dart';
import '../constants/layout.dart';
import '../models/symptom_models.dart';
import 'severity_selector.dart';

class SymptomEntryWidget extends StatefulWidget {
  final UserSymptomModel symptom; // Symptom to display/edit
  final Function(UserSymptomModel)
      onSymptomUpdated; // Callback for severity change
  final VoidCallback onRemove; // Callback for removal
  final bool showRemoveButton; // Show remove button if true
  final bool showSeveritySelector; // Show severity selector if true

  /// The most recent severity for this symptom from a previous entry.
  /// When non-null, a "Previous: <label>" hint is shown next to the
  /// symptom name to give the user context about their recent history.
  final int? lastSeverity;

  const SymptomEntryWidget({
    super.key,
    required this.symptom,
    required this.onSymptomUpdated,
    required this.onRemove,
    this.showRemoveButton = true,
    this.showSeveritySelector = true,
    this.lastSeverity,
  });

  @override
  State<SymptomEntryWidget> createState() => _SymptomEntryWidgetState();
}

class _SymptomEntryWidgetState extends State<SymptomEntryWidget> {
  late int severity; // Current severity value

  @override
  void initState() {
    super.initState();
    severity = widget.symptom.severity; // Initialize severity
  }

  @override
  Widget build(BuildContext context) {
    // Card layout for the symptom entry
    return Card(
      margin: const EdgeInsets.symmetric(vertical: spacingXs),
      child: Padding(
        padding: const EdgeInsets.all(spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with symptom name, previous severity hint, and remove button.
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        widget.symptom.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (widget.lastSeverity != null) ...[
                        const SizedBox(width: spacingSm),
                        Text(
                          'Previous: ${UserSymptomModel.severityLabel(widget.lastSeverity!)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.showRemoveButton)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onRemove,
                  ),
              ],
            ),
            const SizedBox(height: spacingMd),
            // Severity selector (slider or dropdown) only if enabled
            if (widget.showSeveritySelector)
              SeveritySelector(
                currentSeverity: severity,
                showAsSlider: true, // Change to false for dropdown
                onSeverityChanged: (newSeverity) {
                  setState(() {
                    severity = newSeverity;
                  });
                  widget.onSymptomUpdated(
                    widget.symptom.copyWith(severity: severity),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
