import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symptom_tracker_app/widgets/severity_selector.dart';

/// Widget tests for `lib/widgets/severity_selector.dart`.
///
/// SeveritySelector has two UI modes (slider and dropdown) controlled by
/// [showAsSlider]. Both use canonical labels from UserSymptomModel.severityLabel().
///
/// Cross-ref:
///   - Widget under test: lib/widgets/severity_selector.dart
///   - Labels: lib/models/symptom_models.dart (UserSymptomModel.severityLabel)
///   - Consumed by: lib/widgets/symptom_entry_widget.dart
void main() {
  group('SeveritySelector — slider mode', () {
    // The slider should display the current severity as a text label so the
    // user knows what the numeric value means (e.g., "Severity: Moderate").
    testWidgets(
        'As a user, I expect to see the current severity label (e.g. "Severity: Moderate") when viewing the severity slider',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeveritySelector(
              currentSeverity: 3,
              onSeverityChanged: (_) {},
              showAsSlider: true,
            ),
          ),
        ),
      );

      expect(find.text('Severity: Moderate'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    // Dragging the slider should invoke the callback with a new severity
    // value, allowing the parent widget to update state.
    testWidgets(
        'As a user, I expect dragging the severity slider to update the severity value',
        (tester) async {
      int? receivedSeverity;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeveritySelector(
              currentSeverity: 1,
              onSeverityChanged: (val) => receivedSeverity = val,
              showAsSlider: true,
            ),
          ),
        ),
      );

      // Drag slider toward max (right).
      await tester.drag(find.byType(Slider), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(receivedSeverity, isNotNull);
      expect(receivedSeverity, greaterThan(1));
    });
  });

  group('SeveritySelector — dropdown mode', () {
    // The dropdown should render a DropdownButtonFormField with options for
    // all 5 severity levels (1–5).
    testWidgets(
        'As a user, I expect to see a dropdown with severity options when using dropdown mode',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeveritySelector(
              currentSeverity: 3,
              onSeverityChanged: (_) {},
              showAsSlider: false,
            ),
          ),
        ),
      );

      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    });
  });
}
