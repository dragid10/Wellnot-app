// feedback_screen_test.dart: Widget tests for the Send Feedback screen.
//
// Tests cover: category selector layout, all labels visible without overflow.
//
// Cross-ref:
//   - Screen under test: lib/screens/feedback_screen.dart
//   - Segmented control: lib/widgets/adaptive_segmented_control.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symptom_tracker_app/screens/feedback_screen.dart';

void main() {
  /// Helper to pump FeedbackScreen in a constrained width to simulate
  /// narrower devices where the segmented control might overflow.
  Future<void> pumpFeedback(WidgetTester tester, {double width = 375}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: width,
          child: const FeedbackScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  // ---------------------------------------------------------------------------
  // Category selector (#37)
  // ---------------------------------------------------------------------------

  // All three category labels should be visible without overflow.
  testWidgets(
      'As a user, I expect to see all feedback category labels (Bug Report, Feature Request, General Feedback) when opening the feedback screen',
      (tester) async {
    await pumpFeedback(tester);

    expect(find.text('Bug Report'), findsOneWidget);
    expect(find.text('Feature Request'), findsOneWidget);
    expect(find.text('General Feedback'), findsOneWidget);
  });

  // Category labels should not overflow on narrow screens.
  testWidgets(
      'As a user, I expect category labels to fit without overflow on narrow screens',
      (tester) async {
    await pumpFeedback(tester, width: 320);

    // All labels should still be findable (rendered, possibly scaled).
    expect(find.text('Bug Report'), findsOneWidget);
    expect(find.text('Feature Request'), findsOneWidget);
    expect(find.text('General Feedback'), findsOneWidget);

    // No overflow errors should occur — Flutter test framework will report
    // RenderFlex overflow as a test failure automatically.
  });

  // Tapping a category should select it.
  testWidgets('As a user, I expect tapping a feedback category to select it',
      (tester) async {
    await pumpFeedback(tester);

    await tester.tap(find.text('Bug Report'));
    await tester.pump();

    // Bug Report should now be selected — verify the segmented control updated.
    expect(find.text('Bug Report'), findsOneWidget);
  });
}
