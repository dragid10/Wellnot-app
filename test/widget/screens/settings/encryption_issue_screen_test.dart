// encryption_issue_screen_test.dart: Widget tests for the encryption recovery
// screen.
//
// Verifies that the screen displays explanation text, export and reset buttons,
// data loss warning, and the confirmation phrase gate for the destructive
// reset action.
//
// Cross-ref:
//   - Screen under test: lib/screens/settings/encryption_issue_screen.dart
//   - String constants: lib/constants/encryption_recovery.dart
//   - Recovery service: lib/services/encryption_recovery_service.dart

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:symptom_tracker_app/constants/encryption_recovery.dart';
import 'package:symptom_tracker_app/screens/settings/encryption_issue_screen.dart';
import 'package:symptom_tracker_app/services/database.dart';

import '../../../helpers/test_database.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Helper to pump the EncryptionIssueScreen with a test database.
  Future<AppDatabase> pumpEncryptionIssue(WidgetTester tester) async {
    final db = createTestDatabase();
    await tester.pumpWidget(
      Provider<AppDatabase>(
        create: (_) => db,
        child: const MaterialApp(home: EncryptionIssueScreen()),
      ),
    );
    await tester.pump();
    return db;
  }

  /// Scrolls until [finder] is visible, then pumps.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
  }

  // ---------------------------------------------------------------------------
  // Screen layout and content
  // ---------------------------------------------------------------------------

  // The screen title should identify this as the encryption issue flow.
  testWidgets(
      'As a user, I expect to see the screen title when opening the encryption issue screen',
      (tester) async {
    await pumpEncryptionIssue(tester);

    expect(find.text(encryptionRecoveryScreenTitle), findsOneWidget);
  });

  // The explanation text helps the user understand what happened and what
  // they need to do.
  testWidgets(
      'As a user, I expect to see the explanation text on the encryption issue screen',
      (tester) async {
    await pumpEncryptionIssue(tester);

    expect(find.text(encryptionRecoveryExplanation), findsOneWidget);
  });

  // Step 1 instructs the user to export their data before resetting.
  testWidgets(
      'As a user, I expect to see an Export Data button on the encryption issue screen',
      (tester) async {
    await pumpEncryptionIssue(tester);

    expect(find.text('Step 1: Export your data'), findsOneWidget);
    expect(find.text('Export Data'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });

  // The data loss warning card alerts the user that proceeding without
  // exporting will permanently delete their data.
  testWidgets(
      'As a user, I expect to see a warning about data loss on the encryption issue screen',
      (tester) async {
    await pumpEncryptionIssue(tester);

    await scrollTo(tester, find.text(encryptionRecoveryDataWarning));
    expect(find.text(encryptionRecoveryDataWarning), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Reset button — confirmation gate
  // ---------------------------------------------------------------------------

  // The Encrypt Database button should be disabled by default (before the user
  // types the confirmation phrase) to prevent accidental data loss.
  testWidgets(
      'As a user, I expect the Encrypt Database button to be disabled before typing the confirmation phrase',
      (tester) async {
    await pumpEncryptionIssue(tester);

    await scrollTo(tester, find.text('Encrypt Database'));

    final resetButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Encrypt Database'),
    );
    expect(resetButton.onPressed, isNull);
  });

  // Typing an incorrect phrase should keep the button disabled.
  testWidgets(
      'As a user, I expect the Encrypt Database button to remain disabled when I type an incorrect phrase',
      (tester) async {
    await pumpEncryptionIssue(tester);

    await scrollTo(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'wrong phrase');
    await tester.pump();

    final resetButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Encrypt Database'),
    );
    expect(resetButton.onPressed, isNull);
  });

  // Typing the exact confirmation phrase should enable the button.
  testWidgets(
      'As a user, I expect the Encrypt Database button to become enabled when I type the confirmation phrase',
      (tester) async {
    await pumpEncryptionIssue(tester);

    await scrollTo(tester, find.byType(TextField));
    await tester.enterText(
      find.byType(TextField),
      encryptionRecoveryConfirmationPhrase,
    );
    await tester.pump();

    final resetButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Encrypt Database'),
    );
    expect(resetButton.onPressed, isNotNull);
  });

  // The confirmation check should be case-insensitive so "i promise",
  // "I PROMISE", and "I Promise" all work.
  testWidgets(
      'As a user, I expect the confirmation to be case-insensitive when typing the phrase in lowercase',
      (tester) async {
    await pumpEncryptionIssue(tester);

    await scrollTo(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'i promise');
    await tester.pump();

    final resetButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Encrypt Database'),
    );
    expect(resetButton.onPressed, isNotNull);
  });

  testWidgets(
      'As a user, I expect the confirmation to be case-insensitive when typing the phrase in uppercase',
      (tester) async {
    await pumpEncryptionIssue(tester);

    await scrollTo(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'I PROMISE');
    await tester.pump();

    final resetButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Encrypt Database'),
    );
    expect(resetButton.onPressed, isNotNull);
  });

  testWidgets(
      'As a user, I expect the confirmation to be case-insensitive when typing the phrase in mixed case',
      (tester) async {
    await pumpEncryptionIssue(tester);

    await scrollTo(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'i PrOmIsE');
    await tester.pump();

    final resetButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Encrypt Database'),
    );
    expect(resetButton.onPressed, isNotNull);
  });

  // The confirmation should trim whitespace so " I promise " works.
  testWidgets(
      'As a user, I expect the confirmation to accept the phrase with leading and trailing whitespace',
      (tester) async {
    await pumpEncryptionIssue(tester);

    await scrollTo(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), '  I promise  ');
    await tester.pump();

    final resetButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Encrypt Database'),
    );
    expect(resetButton.onPressed, isNotNull);
  });

  // Partial matches should not enable the button.
  testWidgets(
      'As a user, I expect the Encrypt Database button to remain disabled when I type a partial match',
      (tester) async {
    await pumpEncryptionIssue(tester);

    await scrollTo(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'I promis');
    await tester.pump();

    final resetButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Encrypt Database'),
    );
    expect(resetButton.onPressed, isNull);
  });

  // The confirmation prompt label should instruct the user what to type.
  testWidgets(
      'As a user, I expect to see the confirmation prompt hint on the text field',
      (tester) async {
    await pumpEncryptionIssue(tester);

    await scrollTo(tester, find.byType(TextField));
    expect(find.text('Type "I Promise"'), findsOneWidget);
  });

  // Step 2 label should be visible above the confirmation section.
  testWidgets(
      'As a user, I expect to see the step 2 label for confirm and reset',
      (tester) async {
    await pumpEncryptionIssue(tester);

    await scrollTo(tester, find.text('Step 2: Confirm and encrypt'));
    expect(find.text('Step 2: Confirm and encrypt'), findsOneWidget);
  });
}
