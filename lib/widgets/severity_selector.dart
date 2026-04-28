// severity_selector.dart: Widget for selecting symptom severity
//
// Provides either a slider or dropdown for severity selection (1–5), using
// canonical labels from UserSymptomModel.severityLabel(). Two UI modes are
// offered because the slider is better for inline editing (entry form) while
// the dropdown is better for compact/form-field contexts.
//
// Cross-ref:
//   - Labels come from: models/symptom_models.dart (UserSymptomModel.severityLabel)
//   - Layout constants: constants/layout.dart
//   - Consumed by: widgets/symptom_entry_widget.dart
//   - Which is used in: screens/entry_screen.dart

import 'package:flutter/material.dart';
import '../constants/layout.dart';
import '../models/symptom_models.dart';

/// Number of severity levels (1–5).
const int _severityLevels = 5;

/// A reusable widget for selecting a severity level from 1 (Very Mild)
/// to 5 (Very Severe).
///
/// Set [showAsSlider] to `true` for an interactive slider with endpoint
/// labels, or `false` (default) for a compact dropdown.
class SeveritySelector extends StatelessWidget {
  /// The current severity value (1–5).
  final int currentSeverity;

  /// Called when the user changes the severity.
  final Function(int) onSeverityChanged;

  /// If `true`, renders a slider with labels; if `false`, renders a dropdown.
  final bool showAsSlider;

  const SeveritySelector({
    super.key,
    required this.currentSeverity,
    required this.onSeverityChanged,
    this.showAsSlider = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showAsSlider) {
      return _buildSlider(context);
    } else {
      return _buildDropdown();
    }
  }

  /// Builds a slider with a bold label ("Severity: Moderate") and endpoint
  /// labels ("Very Mild" / "Very Severe") at the bottom.
  Widget _buildSlider(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Severity: ${UserSymptomModel.severityLabel(currentSeverity)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: spacingSm),
        Slider.adaptive(
          value: currentSeverity.toDouble(),
          min: 1,
          max: _severityLevels.toDouble(),
          divisions: _severityLevels - 1,
          label: UserSymptomModel.severityLabel(currentSeverity),
          onChanged: (value) => onSeverityChanged(value.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Very Mild', style: Theme.of(context).textTheme.labelSmall),
            Text('Very Severe', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ],
    );
  }

  /// Builds a dropdown form field with all 5 severity options labeled
  /// as "1 - Very Mild", "2 - Mild", etc.
  Widget _buildDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: currentSeverity,
      decoration: const InputDecoration(
        labelText: 'Severity',
        border: OutlineInputBorder(),
      ),
      items: List.generate(_severityLevels, (index) {
        final severity = index + 1;
        return DropdownMenuItem<int>(
          value: severity,
          child:
              Text('$severity - ${UserSymptomModel.severityLabel(severity)}'),
        );
      }),
      onChanged: (value) => onSeverityChanged(value ?? 1),
    );
  }
}
