// loading_overlay_test.dart: Widget tests for the LoadingOverlay widget
//
// Verifies that the overlay shows/hides the loading indicator and message
// correctly, and that the modal barrier blocks interaction when active.
//
// Cross-ref:
//   - Widget under test: lib/widgets/loading_overlay.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symptom_tracker_app/widgets/loading_overlay.dart';

void main() {
  // Helper to pump a LoadingOverlay with a simple child widget.
  Future<void> pumpOverlay(
    WidgetTester tester, {
    required bool isLoading,
    String? message,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoadingOverlay(
          isLoading: isLoading,
          message: message,
          child: const Scaffold(
            body: Center(
              child: Text('Child Content'),
            ),
          ),
        ),
      ),
    );
  }

  /// Finds the overlay's ModalBarrier (non-dismissible, with a color).
  ///
  /// Scaffold adds its own ModalBarrier, so we filter for the one that
  /// has dismissible=false, which is the LoadingOverlay's barrier.
  Finder findOverlayBarrier() {
    return find.byWidgetPredicate(
      (widget) =>
          widget is ModalBarrier && !widget.dismissible && widget.color != null,
    );
  }

  // The child content should always be visible, regardless of loading state,
  // because it sits beneath the overlay in the Stack.
  testWidgets(
      'As a user, I expect to see the child content when the overlay is not active',
      (tester) async {
    await pumpOverlay(tester, isLoading: false);

    expect(find.text('Child Content'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(findOverlayBarrier(), findsNothing);
  });

  // When loading, the spinner should appear overlaid on top of the child.
  testWidgets(
      'As a user, I expect to see a loading indicator when the overlay is active',
      (tester) async {
    await pumpOverlay(tester, isLoading: true);

    expect(find.text('Child Content'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  // When a message is provided alongside isLoading, it should be displayed
  // below the spinner inside the overlay card.
  testWidgets(
      'As a user, I expect to see a message when one is provided with the overlay',
      (tester) async {
    await pumpOverlay(tester, isLoading: true, message: 'Please wait...');

    expect(find.text('Please wait...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  // The ModalBarrier should prevent the user from interacting with the child
  // content while the overlay is active.
  testWidgets(
      'As a user, I expect the child content to be blocked by a modal barrier when the overlay is active',
      (tester) async {
    await pumpOverlay(tester, isLoading: true);

    // The overlay's ModalBarrier should be present in the widget tree.
    expect(findOverlayBarrier(), findsOneWidget);

    // Verify the barrier is non-dismissible.
    final barrierWidget = tester.widget<ModalBarrier>(findOverlayBarrier());
    expect(barrierWidget.dismissible, isFalse);
  });

  // When message is null, no Text widget for the message should appear,
  // but the spinner should still be visible.
  testWidgets('As a user, I expect no message text when message is null',
      (tester) async {
    await pumpOverlay(tester, isLoading: true, message: null);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // The only text in the tree should be "Child Content" from the child.
    // No message text should be rendered.
    expect(find.text('Child Content'), findsOneWidget);

    // Verify the Column inside the Card only has the spinner (no message).
    final cardFinder = find.byType(Card);
    expect(cardFinder, findsOneWidget);
    final columnFinder = find.descendant(
      of: cardFinder,
      matching: find.byType(Column),
    );
    expect(columnFinder, findsOneWidget);
    final column = tester.widget<Column>(columnFinder);
    // When message is null, the Column should only contain the spinner.
    expect(column.children.length, equals(1));
  });

  // When isLoading transitions from true to false, the overlay should
  // disappear completely.
  testWidgets(
      'As a user, I expect the overlay to disappear when isLoading changes from true to false',
      (tester) async {
    // Start with loading active.
    await pumpOverlay(tester, isLoading: true, message: 'Loading...');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading...'), findsOneWidget);
    expect(findOverlayBarrier(), findsOneWidget);

    // Rebuild with loading inactive.
    await pumpOverlay(tester, isLoading: false);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Loading...'), findsNothing);
    expect(findOverlayBarrier(), findsNothing);
  });
}
