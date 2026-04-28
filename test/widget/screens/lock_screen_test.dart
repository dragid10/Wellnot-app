// lock_screen_test.dart: Widget tests for the LockScreen overlay.
//
// Tests cover: lock screen layout (title, icon, unlock button), callback
// invocation on Unlock tap, and conditional error message display.
//
// Cross-ref:
//   - Screen under test: lib/screens/lock_screen.dart
//   - Controlled by: app.dart (Stack overlay based on lock state)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symptom_tracker_app/screens/lock_screen.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Layout
  // ---------------------------------------------------------------------------

  // Shows the lock title text.
  testWidgets(
      'As a user, I expect to see "Wellnot is Locked" text when the lock screen is displayed',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LockScreen(
          onUnlockRequested: () {},
        ),
      ),
    );

    expect(find.text('Wellnot is Locked'), findsOneWidget);
  });

  // Shows the subtitle instruction text.
  testWidgets(
      'As a user, I expect to see instructions to authenticate when the lock screen is displayed',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LockScreen(
          onUnlockRequested: () {},
        ),
      ),
    );

    expect(find.text('Authenticate to access your data'), findsOneWidget);
  });

  // Shows the lock icon.
  testWidgets(
      'As a user, I expect to see a lock icon when the lock screen is displayed',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LockScreen(
          onUnlockRequested: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  // Shows the Unlock button.
  testWidgets(
      'As a user, I expect to see an "Unlock" button when the lock screen is displayed',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LockScreen(
          onUnlockRequested: () {},
        ),
      ),
    );

    expect(find.text('Unlock'), findsOneWidget);
  });

  // Shows the fingerprint icon on the Unlock button.
  testWidgets(
      'As a user, I expect to see a fingerprint icon on the Unlock button',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LockScreen(
          onUnlockRequested: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Interactions
  // ---------------------------------------------------------------------------

  // Tapping Unlock calls onUnlockRequested callback.
  testWidgets(
      'As a user, I expect tapping the Unlock button to trigger authentication',
      (tester) async {
    bool callbackCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: LockScreen(
          onUnlockRequested: () {
            callbackCalled = true;
          },
        ),
      ),
    );

    await tester.tap(find.text('Unlock'));
    await tester.pump();

    expect(callbackCalled, true);
  });

  // ---------------------------------------------------------------------------
  // Error message
  // ---------------------------------------------------------------------------

  // Shows error message when errorMessage is provided.
  testWidgets(
      'As a user, I expect to see an error message when authentication fails',
      (tester) async {
    const errorText = 'Authentication failed. Please try again.';

    await tester.pumpWidget(
      MaterialApp(
        home: LockScreen(
          onUnlockRequested: () {},
          errorMessage: errorText,
        ),
      ),
    );

    expect(find.text(errorText), findsOneWidget);
  });

  // Does NOT show error message when errorMessage is null.
  testWidgets(
      'As a user, I expect no error message to be shown when there is no authentication error',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LockScreen(
          onUnlockRequested: () {},
          errorMessage: null,
        ),
      ),
    );

    // The error message text should not exist anywhere in the widget tree.
    // Verify that only the expected texts are present (title, subtitle, button).
    expect(find.text('Wellnot is Locked'), findsOneWidget);
    expect(find.text('Authenticate to access your data'), findsOneWidget);
    expect(find.text('Unlock'), findsOneWidget);

    // There should be exactly 3 Text widgets in the Column (title, subtitle,
    // button label) plus the icon. No extra Text for error.
    final textWidgets = find.byType(Text);
    // Title + subtitle + button label = 3 Text widgets
    // (The Icon widget is separate, not a Text.)
    expect(textWidgets, findsNWidgets(3));
  });

  // Error message with empty string is still displayed.
  testWidgets(
      'As a user, I expect an error message widget to be present even when the error text is empty',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LockScreen(
          onUnlockRequested: () {},
          errorMessage: '',
        ),
      ),
    );

    // With an empty string errorMessage, the error Text widget is still in
    // the tree (errorMessage != null) — it just has empty content.
    final textWidgets = find.byType(Text);
    // Title + subtitle + button label + empty error = 4 Text widgets
    expect(textWidgets, findsNWidgets(4));
  });
}
