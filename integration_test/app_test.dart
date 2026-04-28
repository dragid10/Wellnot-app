// integration_test/app_test.dart: End-to-end integration tests
//
// These tests exercise the full app on a real device/emulator using
// `IntegrationTestWidgetsFlutterBinding`. They require a running emulator.
//
// Run with: flutter test integration_test/
//
// Cross-ref:
//   - App entry point: lib/main.dart
//   - Database: lib/services/database.dart
//   - Screens: lib/screens/*.dart
//
// NOTE: Integration tests are NOT run by `flutter test` (which only runs
// unit + widget tests). They require `flutter test integration_test/` with
// a connected device/emulator.
//
// Platform-specific tests:
//   Use `skip:` to restrict tests to a specific platform. Prefer runtime
//   helpers (like `tapAddEntry`) for small UI differences in cross-platform
//   tests, and `skip:` for tests that are entirely platform-specific.
//
//   Examples:
//     testWidgets('...', skip: !Platform.isIOS, (tester) async { ... });
//     group('Android-only', skip: !Platform.isAndroid, () { ... });

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:symptom_tracker_app/constants/defaults.dart';
import 'package:symptom_tracker_app/constants/encryption_recovery.dart';
import 'package:symptom_tracker_app/constants/onboarding.dart';
import 'package:symptom_tracker_app/models/symptom_models.dart';
import 'package:symptom_tracker_app/screens/calendar_screen.dart';
import 'package:symptom_tracker_app/screens/onboarding_screen.dart';
import 'package:symptom_tracker_app/services/database.dart';
import 'package:symptom_tracker_app/services/preferences_service.dart';

import '../test/helpers/test_database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Taps the "add entry" button — FAB on Android, AppBar icon on iOS.
  Future<void> tapAddEntry(WidgetTester tester) async {
    if (Platform.isIOS) {
      // iOS uses an AppBar IconButton(Icons.add) instead of a FAB.
      final addButtons = find.byIcon(Icons.add);
      await tester.tap(addButtons.last);
    } else {
      await tester.tap(find.byType(FloatingActionButton));
    }
    await tester.pumpAndSettle();
  }

  /// Launches the app with an in-memory database.
  ///
  /// By default, suppresses the changelog modal by pre-setting the last-seen
  /// version. Pass [showChangelog] = true to allow the modal to appear.
  Future<AppDatabase> launchApp(
    WidgetTester tester, {
    bool showChangelog = false,
  }) async {
    PackageInfo.setMockInitialValues(
      appName: 'Wellnot',
      packageName: 'dev.alexo.symptom_tracker_app',
      version: '1.9.0',
      buildNumber: '23',
      buildSignature: '',
    );
    // Mark onboarding as seen so the changelog guard in _checkChangelog()
    // doesn't suppress the modal. Both the SharedPreferences mock and the
    // static notifier must be set — the guard reads the notifier, and
    // integration tests share static state across flows.
    PreferencesService.hasSeenOnboardingNotifier.value = true;
    if (showChangelog) {
      SharedPreferences.setMockInitialValues({
        prefKeyHasSeenOnboarding: true,
      });
    } else {
      SharedPreferences.setMockInitialValues({
        prefKeyLastSeenVersion: '1.9.0',
        prefKeyHasSeenOnboarding: true,
      });
    }

    final db = createTestDatabase();
    await tester.pumpWidget(
      Provider<AppDatabase>(
        create: (_) => db,
        child: MaterialApp(
          title: 'Symptom Tracker',
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.teal,
          ),
          home: const CalendarScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return db;
  }

  // -------------------------------------------------------------------------
  // Flow 1: Full entry lifecycle
  // Create → view on calendar → open detail → edit → delete
  // -------------------------------------------------------------------------
  group('Flow 1: Full entry lifecycle', () {
    testWidgets('create, view, edit, and delete an entry', (tester) async {
      final db = await launchApp(tester);

      // Tap FAB to create a new entry.
      await tapAddEntry(tester);

      // Select "Headache" symptom.
      expect(find.text('Headache'), findsOneWidget);
      await tester.tap(find.text('Headache'));
      await tester.pumpAndSettle();

      // Select a mood.
      await tester.ensureVisible(find.text('😊'));
      await tester.tap(find.text('😊'));
      await tester.pumpAndSettle();

      // Scroll to and tap Save.
      await tester.ensureVisible(find.text('Add Entry'));
      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      // Verify entry appears on calendar.
      expect(find.textContaining('Headache'), findsOneWidget);

      // Tap entry to open detail screen.
      await tester.tap(find.textContaining('Headache'));
      await tester.pumpAndSettle();

      // Verify severity is shown on detail screen.
      expect(find.textContaining('Moderate'), findsOneWidget);

      // Delete the entry.
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify entry is gone from calendar.
      expect(find.textContaining('Headache'), findsNothing);

      await db.close();
    });
  });

  // -------------------------------------------------------------------------
  // Flow 2: Custom items
  // Navigate to manage → add custom symptom → use in entry
  // -------------------------------------------------------------------------
  group('Flow 2: Custom items', () {
    testWidgets('add custom symptom and use in entry', (tester) async {
      final db = await launchApp(tester);

      // Navigate to Settings → Manage Symptoms sub-page.
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manage Symptoms'));
      await tester.pumpAndSettle();

      // Add a custom symptom.
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter symptom name'),
        'Migraine',
      );
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      expect(find.text('Migraine'), findsOneWidget);

      // Go back to Settings, then back to Calendar.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verify custom symptom is in DB.
      final symptoms = await db.getAllSymptoms();
      expect(symptoms.any((s) => s.name == 'Migraine'), isTrue);

      await db.close();
    });
  });

  // -------------------------------------------------------------------------
  // Flow 3: Tag tooltip
  // Entry screen → scroll to Tags → tap info icon → verify tooltip
  // Settings → Manage Tags page → verify info icon
  // -------------------------------------------------------------------------
  group('Flow 3: Tag tooltip', () {
    testWidgets('tag tooltip shows on entry screen and manage tags page',
        (tester) async {
      final db = await launchApp(tester);

      // Open new entry screen.
      await tapAddEntry(tester);

      // Scroll to Tags section and tap the info icon.
      await tester.ensureVisible(find.text('Tags'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      // Verify tooltip text appears.
      expect(
          find.textContaining('Tags help you track context'), findsOneWidget);

      // Dismiss tooltip by tapping elsewhere, then go back to calendar.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Navigate to Settings → Manage Tags.
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manage Tags'));
      await tester.pumpAndSettle();

      // Info icon should be in the app bar.
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      await db.close();
    });
  });

  // -------------------------------------------------------------------------
  // Flow 4: Data persistence
  // Create entry → verify data in DB with correct severity
  // -------------------------------------------------------------------------
  group('Flow 4: Data persistence', () {
    testWidgets('entry persists with correct severity in DB', (tester) async {
      final db = await launchApp(tester);

      // Create an entry.
      await tapAddEntry(tester);

      await tester.tap(find.text('Headache'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('😊'));
      await tester.tap(find.text('😊'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Add Entry'));
      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      // Verify directly in DB.
      final entries = await db.getAllEntriesWithDetails();
      expect(entries, hasLength(1));
      expect(entries.first.mood, '😊');
      expect(entries.first.symptoms.first.name, 'Headache');
      // Default severity should be 3 (Moderate).
      expect(entries.first.symptoms.first.severity, 3);

      await db.close();
    });
  });

  // -------------------------------------------------------------------------
  // Flow 5: Settings sub-page navigation
  // Navigate through each settings sub-page and verify they load
  // -------------------------------------------------------------------------
  group('Flow 5: Settings sub-page navigation', () {
    testWidgets('navigate through all settings sub-pages', (tester) async {
      final db = await launchApp(tester);

      // Navigate to Settings.
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Verify settings hub sections are visible.
      expect(find.text('Personalization'), findsOneWidget);

      // Theme sub-page.
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Calendar sub-page.
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
      expect(find.text('Week starts on'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Display sub-page.
      await tester.tap(find.text('Display'));
      await tester.pumpAndSettle();
      expect(find.text('Show tag preview'), findsOneWidget);
      expect(find.text('Show note preview'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Reminders sub-page.
      await tester.tap(find.text('Reminders'));
      await tester.pumpAndSettle();
      expect(find.text('Daily Reminder'), findsOneWidget);
      expect(find.text('Quick Add Notification'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // About sub-page.
      await tester.ensureVisible(find.text('About'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      expect(find.text('Wellnot'), findsOneWidget);
      expect(find.text('Open Source Licenses'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await db.close();
    });
  });

  // -------------------------------------------------------------------------
  // Flow 6: Clear & Reset
  // Navigate to Clear & Reset → verify options → confirm dialog chain
  // -------------------------------------------------------------------------
  group('Flow 6: Clear & Reset', () {
    testWidgets('clear logged data with two-step confirmation', (tester) async {
      final db = await launchApp(tester);

      // Create an entry first so there's data to clear.
      await tapAddEntry(tester);
      await tester.tap(find.text('Headache'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('😊'));
      await tester.tap(find.text('😊'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Add Entry'));
      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      // Verify entry exists.
      expect(find.textContaining('Headache'), findsOneWidget);

      // Navigate to Settings → Clear & Reset.
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Clear & Reset'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear & Reset'));
      await tester.pumpAndSettle();

      // Verify all three options are shown.
      expect(find.text('Clear Logged Data'), findsOneWidget);
      expect(find.text('Reset Settings'), findsOneWidget);
      expect(find.text('Clear Everything'), findsOneWidget);

      // Tap Clear Logged Data → first confirmation.
      await tester.tap(find.text('Clear Logged Data'));
      await tester.pumpAndSettle();
      expect(find.text('Clear Logged Data?'), findsOneWidget);

      // Tap Continue → second confirmation.
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Are you ABSOLUTELY sure?'), findsOneWidget);

      // Confirm deletion.
      await tester.tap(find.text('YES, PLEASE DELETE'));
      await tester.pumpAndSettle();

      // Verify data is cleared via snackbar.
      expect(find.text('All logged data has been cleared.'), findsOneWidget);

      // Verify database is empty.
      final entries = await db.getAllEntriesWithDetails();
      expect(entries, isEmpty);

      await db.close();
    });
  });

  // -------------------------------------------------------------------------
  // Flow 7: Export data
  // Navigate to settings → tap Export Data → verify sub-page with formats
  // Also verify "No data to export" snackbar when there are no entries
  // -------------------------------------------------------------------------
  group('Flow 7: Export data', () {
    testWidgets('export sub-page shows format options', (tester) async {
      final db = await launchApp(tester);

      // Navigate to Settings.
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Scroll to and tap Export Data.
      await tester.ensureVisible(find.text('Export Data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export Data'));
      await tester.pumpAndSettle();

      // Verify export sub-page shows format options.
      expect(find.text('JSON (Recommended)'), findsOneWidget);
      expect(find.text('CSV'), findsOneWidget);

      // Go back to settings.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await db.close();
    });

    testWidgets('shows "No data to export" when there are no entries',
        (tester) async {
      final db = await launchApp(tester);

      // Navigate to Settings.
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Scroll to and tap Export Data.
      await tester.ensureVisible(find.text('Export Data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export Data'));
      await tester.pumpAndSettle();

      // Tap CSV (with no entries in the database).
      await tester.tap(find.text('CSV'));
      await tester.pumpAndSettle();

      // Should show snackbar indicating no data.
      expect(find.text('No data to export.'), findsOneWidget);

      await db.close();
    });
  });

  // -------------------------------------------------------------------------
  // Flow 8: Changelog modal
  // First launch shows welcome → dismiss → revisit via Settings > What's New
  // -------------------------------------------------------------------------
  group('Flow 8: Changelog modal', () {
    testWidgets(
        'changelog modal appears on first launch and can be revisited from Settings',
        (tester) async {
      final db = await launchApp(tester, showChangelog: true);

      // Welcome modal should appear on first launch.
      expect(find.text("What's New in v1.9.0"), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);

      // Dismiss the modal.
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      // Modal is gone.
      expect(find.text("What's New in v1.9.0"), findsNothing);

      // Navigate to Settings and tap "What's New" to revisit.
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text("What's New"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("What's New"));
      await tester.pumpAndSettle();

      // Version-specific dialog should appear (not welcome, since version
      // was persisted after dismissing the first modal).
      expect(find.text("What's New in v1.9.0"), findsOneWidget);

      // Dismiss.
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      await db.close();
    });
  });

  // -------------------------------------------------------------------------
  // Flow 9: Summary screen (#45)
  // Calendar → create entries → tap insights icon → verify summary →
  // tap symptom → filtered list → tap entry → detail screen
  // -------------------------------------------------------------------------
  group('Flow 9: Summary screen', () {
    testWidgets('view summary and drill into filtered entries', (tester) async {
      final db = await launchApp(tester);

      // Create two entries with data so the summary has something to show.
      final now = DateTime.now();
      await db.saveEntry(
        dateTime: now.subtract(const Duration(days: 1)),
        mood: '😊',
        symptoms: [
          UserSymptomModel(id: -1, name: 'Headache', severity: 4),
          UserSymptomModel(id: -1, name: 'Nausea', severity: 2),
        ],
        tags: [UserTagModel(id: -1, name: 'After Meal')],
      );
      await db.saveEntry(
        dateTime: now.subtract(const Duration(days: 2)),
        mood: '😢',
        symptoms: [
          UserSymptomModel(id: -1, name: 'Headache', severity: 2),
        ],
        tags: [UserTagModel(id: -1, name: 'At Work')],
      );

      // Tap the insights icon to open the summary screen.
      await tester.tap(find.byIcon(Icons.insights));
      await tester.pumpAndSettle();

      // Verify summary screen loads.
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('2 entries'), findsOneWidget);

      // Verify mood distribution section.
      expect(find.text('Mood Distribution'), findsOneWidget);

      // Verify top symptoms section.
      expect(find.text('Top Symptoms'), findsOneWidget);
      expect(find.text('Headache'), findsOneWidget);
      expect(find.text('2x'), findsOneWidget);

      // Verify top tags section.
      expect(find.text('Top Tags'), findsOneWidget);
      expect(find.text('After Meal'), findsOneWidget);
      expect(find.text('At Work'), findsOneWidget);

      // Tap Headache to see filtered entries.
      await tester.tap(find.text('Headache'));
      await tester.pumpAndSettle();

      // Verify filtered entries screen shows Headache entries.
      expect(find.text('Headache'), findsAtLeast(1));

      // Tap an entry to open detail screen.
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // Verify detail screen shows.
      expect(find.textContaining('Headache'), findsOneWidget);

      await db.close();
    });

    testWidgets('summary shows empty state when no entries exist',
        (tester) async {
      final db = await launchApp(tester);

      // Open summary with no data.
      await tester.tap(find.byIcon(Icons.insights));
      await tester.pumpAndSettle();

      expect(find.text('No entries in this date range.'), findsOneWidget);

      await db.close();
    });
  });

  // -------------------------------------------------------------------------
  // Flow 10: Import data screen
  // Navigate to settings → tap Import Data → verify sub-page UI
  // -------------------------------------------------------------------------
  group('Flow 10: Import data', () {
    testWidgets('import sub-page shows file picker and instructions',
        (tester) async {
      final db = await launchApp(tester);

      // Navigate to Settings.
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Scroll to and tap Import Data.
      await tester.ensureVisible(find.text('Import Data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import Data'));
      await tester.pumpAndSettle();

      // Verify import sub-page shows instructions and file picker.
      expect(find.text('Import Data'), findsOneWidget);
      expect(find.text('Select backup file'), findsOneWidget);
      expect(
        find.textContaining('Restore your symptom data'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Existing entries are preserved'),
        findsOneWidget,
      );

      // No import button should be visible before selecting a file.
      expect(find.byType(FilledButton), findsNothing);

      // Go back to settings.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await db.close();
    });
  });

  // -------------------------------------------------------------------------
  // Flow 11: Onboarding walkthrough
  // Verifies the full onboarding flow on first launch.
  // -------------------------------------------------------------------------
  group('Flow 11: Onboarding walkthrough', () {
    testWidgets(
        'As a user, I expect to complete the full onboarding walkthrough on first launch',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        prefKeyLastSeenVersion: '1.9.0',
      });
      PreferencesService.hasSeenOnboardingNotifier.value = false;

      bool completed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.teal,
          ),
          home: OnboardingScreen(onComplete: () => completed = true),
        ),
      );
      await tester.pumpAndSettle();

      // Verify first page.
      expect(find.text(onboardingPages[0].title), findsOneWidget);
      expect(find.text(onboardingPages[0].description), findsOneWidget);

      // Navigate through all pages.
      for (int i = 1; i < onboardingPages.length; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        expect(find.text(onboardingPages[i].title), findsOneWidget);
      }

      // Last page: Get Started instead of Next, no Skip.
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
      expect(find.text('Skip'), findsNothing);

      // Complete onboarding.
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(completed, true);
    });

    testWidgets('As a user, I expect to skip the onboarding walkthrough',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        prefKeyLastSeenVersion: '1.9.0',
      });
      PreferencesService.hasSeenOnboardingNotifier.value = false;

      bool completed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.teal,
          ),
          home: OnboardingScreen(onComplete: () => completed = true),
        ),
      );
      await tester.pumpAndSettle();

      // Skip from the first page.
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(completed, true);
    });
  });

  // -------------------------------------------------------------------------
  // Flow 12: Encryption recovery
  // When migration fails, the app shows a toast and settings banner guiding
  // the user through the export → confirm → encrypt → import recovery flow.
  // -------------------------------------------------------------------------
  group('Flow 12: Encryption recovery', () {
    /// Launches the app with the encryption migration failure flag set.
    Future<AppDatabase> launchWithMigrationFailure(WidgetTester tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'Wellnot',
        packageName: 'dev.alexo.symptom_tracker_app',
        version: '1.9.0',
        buildNumber: '23',
        buildSignature: '',
      );
      PreferencesService.hasSeenOnboardingNotifier.value = true;
      PreferencesService.encryptionMigrationFailedNotifier.value = true;
      SharedPreferences.setMockInitialValues({
        prefKeyLastSeenVersion: '1.9.0',
        prefKeyHasSeenOnboarding: true,
        prefKeyEncryptionMigrationFailed: true,
      });

      final db = createTestDatabase();
      await tester.pumpWidget(
        Provider<AppDatabase>(
          create: (_) => db,
          child: MaterialApp(
            title: 'Symptom Tracker',
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.teal,
            ),
            home: const CalendarScreen(),
          ),
        ),
      );
      await tester.pump();
      return db;
    }

    testWidgets(
        'As a user, I expect to see a toast on launch when encryption migration has failed',
        (tester) async {
      final db = await launchWithMigrationFailure(tester);

      // The toast should appear after the first frame.
      await tester.pump();
      expect(find.text(encryptionRecoveryToastMessage), findsOneWidget);

      await db.close();
      PreferencesService.encryptionMigrationFailedNotifier.value = false;
    });

    testWidgets(
        'As a user, I expect to see a warning banner in settings when encryption migration has failed',
        (tester) async {
      final db = await launchWithMigrationFailure(tester);
      await tester.pump();

      // Dismiss the toast by tapping elsewhere.
      await tester.pump(const Duration(seconds: 7));

      // Navigate to Settings.
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // The warning banner should be visible at the top.
      expect(find.text(encryptionRecoveryBannerTitle), findsOneWidget);
      expect(find.text(encryptionRecoveryBannerSubtitle), findsOneWidget);

      await db.close();
      PreferencesService.encryptionMigrationFailedNotifier.value = false;
    });

    testWidgets(
        'As a user, I expect tapping the settings banner to navigate to the encryption issue screen',
        (tester) async {
      final db = await launchWithMigrationFailure(tester);
      await tester.pump();
      await tester.pump(const Duration(seconds: 7));

      // Navigate to Settings.
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Tap the warning banner.
      await tester.tap(find.text(encryptionRecoveryBannerTitle));
      await tester.pumpAndSettle();

      // Should be on the encryption issue screen.
      expect(find.text(encryptionRecoveryScreenTitle), findsOneWidget);
      expect(find.text(encryptionRecoveryExplanation), findsOneWidget);
      expect(find.text('Export Data'), findsOneWidget);

      await db.close();
      PreferencesService.encryptionMigrationFailedNotifier.value = false;
    });

    testWidgets(
        'As a user, I expect the Encrypt Database button to be disabled until I type the confirmation phrase',
        (tester) async {
      final db = await launchWithMigrationFailure(tester);
      await tester.pump();
      await tester.pump(const Duration(seconds: 7));

      // Navigate to Settings → Encryption Issue screen.
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text(encryptionRecoveryBannerTitle));
      await tester.pumpAndSettle();

      // Scroll to the Encrypt Database button.
      await tester.ensureVisible(find.text('Encrypt Database'));
      await tester.pump();

      // Button should be disabled.
      final disabledButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Encrypt Database'),
      );
      expect(disabledButton.onPressed, isNull);

      // Type the confirmation phrase.
      await tester.ensureVisible(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'I promise');
      await tester.pump();

      // Button should now be enabled.
      final enabledButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Encrypt Database'),
      );
      expect(enabledButton.onPressed, isNotNull);

      await db.close();
      PreferencesService.encryptionMigrationFailedNotifier.value = false;
    });
  });
}
