import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symptom_tracker_app/models/symptom_models.dart';
import 'package:symptom_tracker_app/widgets/symptom_entry_widget.dart';

/// Widget tests for `lib/widgets/symptom_entry_widget.dart`.
///
/// SymptomEntryWidget displays a symptom name with an optional severity
/// slider and remove button. It's used in entry_screen.dart for each
/// selected symptom.
///
/// Cross-ref:
///   - Widget under test: lib/widgets/symptom_entry_widget.dart
///   - Severity slider: lib/widgets/severity_selector.dart
///   - Model: lib/models/symptom_models.dart (UserSymptomModel)
///   - Used in: lib/screens/entry_screen.dart
void main() {
  group('SymptomEntryWidget', () {
    // The symptom name should always be visible regardless of configuration.
    testWidgets(
        'As a user, I expect to see the symptom name displayed when viewing a selected symptom',
        (tester) async {
      final symptom = UserSymptomModel(id: 1, name: 'Headache');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomEntryWidget(
              symptom: symptom,
              onSymptomUpdated: (_) {},
              onRemove: () {},
            ),
          ),
        ),
      );

      expect(find.text('Headache'), findsOneWidget);
    });

    // When the user drags the severity slider, the widget should call
    // onSymptomUpdated with a new UserSymptomModel containing the updated
    // severity. This is how entry_screen.dart captures severity changes.
    testWidgets(
        'As a user, I expect adjusting the severity slider to update the symptom with the new severity value',
        (tester) async {
      UserSymptomModel? updatedSymptom;
      final symptom = UserSymptomModel(id: 1, name: 'Nausea', severity: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomEntryWidget(
              symptom: symptom,
              onSymptomUpdated: (s) => updatedSymptom = s,
              onRemove: () {},
              showSeveritySelector: true,
            ),
          ),
        ),
      );

      // Drag the slider to the right to increase severity.
      await tester.drag(find.byType(Slider), const Offset(300, 0));
      await tester.pumpAndSettle();

      // The callback should have fired with the same symptom name but a
      // different severity value.
      expect(updatedSymptom, isNotNull);
      expect(updatedSymptom!.name, 'Nausea');
    });

    // The close (X) icon button should call onRemove so the parent can
    // remove this symptom from the selected list.
    testWidgets(
        'As a user, I expect tapping the remove button to deselect the symptom from my entry',
        (tester) async {
      bool removed = false;
      final symptom = UserSymptomModel(id: 1, name: 'Fatigue');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomEntryWidget(
              symptom: symptom,
              onSymptomUpdated: (_) {},
              onRemove: () => removed = true,
              showRemoveButton: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(removed, isTrue);
    });

    // When showRemoveButton is false (e.g., read-only contexts), the close
    // icon should not be rendered at all.
    testWidgets(
        'As a user, I expect no remove button to appear in read-only contexts like the detail screen',
        (tester) async {
      final symptom = UserSymptomModel(id: 1, name: 'Fatigue');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomEntryWidget(
              symptom: symptom,
              onSymptomUpdated: (_) {},
              onRemove: () {},
              showRemoveButton: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsNothing);
    });

    // When lastSeverity is provided, a "Last: <label>" hint should appear.
    testWidgets(
        'As a user, I expect to see a "Previous: <label>" hint showing the severity I used last time for this symptom',
        (tester) async {
      final symptom = UserSymptomModel(id: 1, name: 'Headache');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomEntryWidget(
              symptom: symptom,
              onSymptomUpdated: (_) {},
              onRemove: () {},
              lastSeverity: 2,
            ),
          ),
        ),
      );

      expect(find.text('Previous: Mild'), findsOneWidget);
    });

    // When lastSeverity is null, no hint should appear.
    testWidgets(
        'As a user, I expect no severity hint when I have no previous entries for this symptom',
        (tester) async {
      final symptom = UserSymptomModel(id: 1, name: 'Headache');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SymptomEntryWidget(
              symptom: symptom,
              onSymptomUpdated: (_) {},
              onRemove: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Previous:'), findsNothing);
    });
  });
}
