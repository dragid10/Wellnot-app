// changelog_dialog_test.dart: Widget tests for the changelog modal
//
// Verifies that the dialog shows the correct title, entries, platform sections,
// and dismisses properly.
//
// Cross-ref:
//   - Widget under test: lib/widgets/changelog_dialog.dart
//   - Changelog data: lib/constants/changelog.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symptom_tracker_app/constants/changelog.dart';
import 'package:symptom_tracker_app/widgets/changelog_dialog.dart';

void main() {
  /// Test entries with mixed platforms used across section tests.
  const testEntries = [
    ChangelogEntry(
      description: 'Export your data to CSV',
      type: ChangelogEntryType.feature,
    ),
    ChangelogEntry(
      description: 'Quick Add notification',
      type: ChangelogEntryType.feature,
      platform: ChangelogPlatform.android,
    ),
    ChangelogEntry(
      description: 'Picker button clipping fixed',
      type: ChangelogEntryType.fix,
      platform: ChangelogPlatform.ios,
    ),
    ChangelogEntry(
      description: 'Auto-capitalized names',
      type: ChangelogEntryType.improvement,
    ),
  ];

  /// Helper to pump a scaffold and trigger the dialog.
  Future<void> pumpAndShowDialog(
    WidgetTester tester, {
    String version = '1.9.0',
    List<ChangelogEntry> entries = testEntries,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            // Show the dialog after the first frame.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showChangelogDialog(
                context: context,
                version: version,
                entries: entries,
              );
            });
            return const Scaffold();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Changelog dialog', () {
    testWidgets(
        'As a user, I expect to see "What\'s New in v1.9.0" as the dialog title',
        (tester) async {
      await pumpAndShowDialog(tester, version: '1.9.0');

      expect(find.text("What's New in v1.9.0"), findsOneWidget);
    });

    testWidgets(
        'As a user, I expect to see all changelog entry descriptions in the dialog',
        (tester) async {
      await pumpAndShowDialog(tester);

      for (final entry in testEntries) {
        expect(find.textContaining(entry.description), findsOneWidget);
      }
    });

    testWidgets(
        'As a user, I expect to see a "Got it" button to dismiss the dialog',
        (tester) async {
      await pumpAndShowDialog(tester);

      expect(find.text('Got it'), findsOneWidget);
    });

    testWidgets('As a user, I expect tapping "Got it" to close the dialog',
        (tester) async {
      await pumpAndShowDialog(tester);

      // Dialog is visible.
      expect(find.text("What's New in v1.9.0"), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      // Dialog is gone.
      expect(find.text("What's New in v1.9.0"), findsNothing);
    });

    testWidgets(
        'As a user, I expect each entry to be prefixed with a tag like [New], [Fix], or [Improved]',
        (tester) async {
      await pumpAndShowDialog(tester);

      // Two [New] tags (one general feature, one Android feature).
      expect(find.textContaining('[New]'), findsNWidgets(2));
      // One [Fix] tag (iOS fix entry).
      expect(find.textContaining('[Fix]'), findsOneWidget);
      // One [Improved] tag (general improvement entry).
      expect(find.textContaining('[Improved]'), findsOneWidget);
    });
  });

  group('Changelog dialog platform sections', () {
    testWidgets(
        'As a user, I expect Android-only changes to appear under an "Android" section header',
        (tester) async {
      await pumpAndShowDialog(tester);

      expect(find.text('Android'), findsOneWidget);
      expect(find.textContaining('Quick Add notification'), findsOneWidget);
    });

    testWidgets(
        'As a user, I expect iOS-only changes to appear under an "iOS" section header',
        (tester) async {
      await pumpAndShowDialog(tester);

      expect(find.text('iOS'), findsOneWidget);
      expect(
          find.textContaining('Picker button clipping fixed'), findsOneWidget);
    });

    testWidgets(
        'As a user, I expect no Android section header when there are no Android-specific changes',
        (tester) async {
      const noAndroidEntries = [
        ChangelogEntry(
          description: 'General change',
          type: ChangelogEntryType.feature,
        ),
        ChangelogEntry(
          description: 'iOS fix',
          type: ChangelogEntryType.fix,
          platform: ChangelogPlatform.ios,
        ),
      ];

      await pumpAndShowDialog(tester, entries: noAndroidEntries);

      expect(find.text('Android'), findsNothing);
      expect(find.text('iOS'), findsOneWidget);
    });

    testWidgets(
        'As a user, I expect no iOS section header when there are no iOS-specific changes',
        (tester) async {
      const noIosEntries = [
        ChangelogEntry(
          description: 'General change',
          type: ChangelogEntryType.feature,
        ),
        ChangelogEntry(
          description: 'Android improvement',
          type: ChangelogEntryType.improvement,
          platform: ChangelogPlatform.android,
        ),
      ];

      await pumpAndShowDialog(tester, entries: noIosEntries);

      expect(find.text('iOS'), findsNothing);
      expect(find.text('Android'), findsOneWidget);
    });

    testWidgets(
        'As a user, I expect no platform section headers when all changes are general',
        (tester) async {
      const allGeneralEntries = [
        ChangelogEntry(
          description: 'Feature one',
          type: ChangelogEntryType.feature,
        ),
        ChangelogEntry(
          description: 'Fix one',
          type: ChangelogEntryType.fix,
        ),
      ];

      await pumpAndShowDialog(tester, entries: allGeneralEntries);

      expect(find.text('Android'), findsNothing);
      expect(find.text('iOS'), findsNothing);
    });
  });
}
