// manage_items_screen_test.dart: Widget tests for the Settings hub screen
//
// Tests cover: settings screen layout with section headers, navigable tiles,
// subtitles showing current values, navigation to sub-pages, Clear All Data
// dialog, and What's New changelog dialog.
//
// Sub-page tests live in separate files:
//   - theme_settings_screen_test.dart
//   - calendar_settings_screen_test.dart
//   - reminders_settings_screen_test.dart
//   - export_data_screen_test.dart
//   - import_data_screen_test.dart
//   - about_screen_test.dart
//
// Cross-ref:
//   - Screen under test: lib/screens/manage_items_screen.dart
//   - Sub-pages: lib/screens/settings/

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:symptom_tracker_app/constants/defaults.dart';
import 'package:symptom_tracker_app/constants/encryption_recovery.dart';
import 'package:symptom_tracker_app/screens/feedback_screen.dart';
import 'package:symptom_tracker_app/screens/manage_items_screen.dart';
import 'package:symptom_tracker_app/screens/manage_list_screen.dart';
import 'package:symptom_tracker_app/screens/settings/about_screen.dart';
import 'package:symptom_tracker_app/screens/settings/calendar_settings_screen.dart';
import 'package:symptom_tracker_app/screens/settings/clear_reset_screen.dart';
import 'package:symptom_tracker_app/screens/settings/encryption_issue_screen.dart';
import 'package:symptom_tracker_app/screens/settings/security_settings_screen.dart';
import 'package:symptom_tracker_app/screens/settings/display_settings_screen.dart';
import 'package:symptom_tracker_app/screens/settings/export_data_screen.dart';
import 'package:symptom_tracker_app/screens/settings/import_data_screen.dart';
import 'package:symptom_tracker_app/screens/settings/reminders_settings_screen.dart';
import 'package:symptom_tracker_app/screens/settings/theme_settings_screen.dart';
import 'package:symptom_tracker_app/services/database.dart';
import 'package:symptom_tracker_app/services/preferences_service.dart';

import '../../helpers/test_database.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Wellnot',
      packageName: 'dev.alexo.symptom_tracker_app',
      version: '1.9.0',
      buildNumber: '25',
      buildSignature: '',
    );
  });

  /// Helper to pump ManageItemsScreen (settings) with Provider + async load.
  Future<AppDatabase> pumpSettings(WidgetTester tester) async {
    final db = createTestDatabase();
    await tester.pumpWidget(
      Provider<AppDatabase>(
        create: (_) => db,
        child: const MaterialApp(home: ManageItemsScreen()),
      ),
    );
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    return db;
  }

  /// Scrolls the SingleChildScrollView until [finder] is visible, then pumps.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
  }

  // ---------------------------------------------------------------------------
  // Settings hub layout
  // ---------------------------------------------------------------------------

  testWidgets(
      'As a user, I expect to see "Settings" as the title when opening the settings screen',
      (tester) async {
    await pumpSettings(tester);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect to see Manage Symptoms and Manage Tags tiles at the top',
      (tester) async {
    await pumpSettings(tester);
    expect(find.text('Manage Symptoms'), findsOneWidget);
    expect(find.text('Manage Tags'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Section headers
  // ---------------------------------------------------------------------------

  testWidgets(
      'As a user, I expect to see accent-colored section headers for Personalization, Security, Notifications, Data, and Support',
      (tester) async {
    await pumpSettings(tester);

    expect(find.text('Personalization'), findsOneWidget);

    await scrollTo(tester, find.text('Security'));
    expect(find.text('Security'), findsOneWidget);

    await scrollTo(tester, find.text('Notifications'));
    expect(find.text('Notifications'), findsOneWidget);

    await scrollTo(tester, find.text('Data'));
    expect(find.text('Data'), findsOneWidget);

    await scrollTo(tester, find.text('Support'));
    expect(find.text('Support'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Personalization tiles with subtitles
  // ---------------------------------------------------------------------------

  testWidgets(
      'As a user, I expect the Theme tile to show the current theme mode as subtitle',
      (tester) async {
    await pumpSettings(tester);

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect the Calendar tile to show the current week start day as subtitle',
      (tester) async {
    await pumpSettings(tester);

    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Week starts on System'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Notifications tile with subtitle
  // ---------------------------------------------------------------------------

  testWidgets(
      'As a user, I expect the Reminders tile to show "Off" when notifications are disabled',
      (tester) async {
    await pumpSettings(tester);

    expect(find.text('Reminders'), findsOneWidget);
    // Use ancestor matcher — both Reminders and App Lock can show "Off".
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Reminders'),
        matching: find.text('Off'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'As a user, I expect the Reminders tile to show the notification time when enabled',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      prefKeyNotificationsEnabled: true,
      prefKeyNotificationHour: 21,
      prefKeyNotificationMinute: 0,
    });

    await pumpSettings(tester);

    expect(find.text('Reminders'), findsOneWidget);
    expect(find.textContaining('9:00'), findsOneWidget);
    expect(find.textContaining('PM'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Data tiles
  // ---------------------------------------------------------------------------

  testWidgets(
      'As a user, I expect to see Import Data, Export Data, and Clear & Reset tiles in the Data section',
      (tester) async {
    await pumpSettings(tester);

    await scrollTo(tester, find.text('Import Data'));
    expect(find.text('Import Data'), findsOneWidget);

    await scrollTo(tester, find.text('Export Data'));
    expect(find.text('Export Data'), findsOneWidget);

    await scrollTo(tester, find.text('Clear & Reset'));
    expect(find.text('Clear & Reset'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Support tiles
  // ---------------------------------------------------------------------------

  testWidgets(
      'As a user, I expect to see Send Feedback, What\'s New, and About tiles in the Support section',
      (tester) async {
    await pumpSettings(tester);

    await scrollTo(tester, find.text('Send Feedback'));
    expect(find.text('Send Feedback'), findsOneWidget);

    await scrollTo(tester, find.text("What's New"));
    expect(find.text("What's New"), findsOneWidget);

    await scrollTo(tester, find.text('About'));
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect the About tile to show the app version as subtitle',
      (tester) async {
    await pumpSettings(tester);

    await scrollTo(tester, find.text('About'));
    expect(find.text('v1.9.0+25'), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect tapping "What\'s New" to show the changelog for the current version',
      (tester) async {
    await pumpSettings(tester);

    await scrollTo(tester, find.text("What's New"));
    await tester.tap(find.text("What's New"));
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.text("What's New in v1.9.0"), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Navigation to sub-pages
  // ---------------------------------------------------------------------------

  testWidgets(
      'As a user, I expect tapping Manage Symptoms to navigate to the symptom management screen',
      (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Manage Symptoms'));
    await tester.pumpAndSettle();

    expect(find.byType(ManageListScreen), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect tapping Manage Tags to navigate to the tag management screen',
      (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Manage Tags'));
    await tester.pumpAndSettle();

    expect(find.byType(ManageListScreen), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect tapping Theme to navigate to the theme settings screen',
      (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();

    expect(find.byType(ThemeSettingsScreen), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect tapping Calendar to navigate to the calendar settings screen',
      (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarSettingsScreen), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect tapping Display to navigate to the display settings screen',
      (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Display'));
    await tester.pumpAndSettle();

    expect(find.byType(DisplaySettingsScreen), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect tapping Reminders to navigate to the reminders settings screen',
      (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Reminders'));
    await tester.pumpAndSettle();

    expect(find.byType(RemindersSettingsScreen), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect tapping Export Data to navigate to the export data screen',
      (tester) async {
    await pumpSettings(tester);

    await scrollTo(tester, find.text('Export Data'));
    await tester.tap(find.text('Export Data'));
    await tester.pumpAndSettle();

    expect(find.byType(ExportDataScreen), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect tapping Import Data to navigate to the import data screen',
      (tester) async {
    await pumpSettings(tester);

    await scrollTo(tester, find.text('Import Data'));
    await tester.tap(find.text('Import Data'));
    await tester.pumpAndSettle();

    expect(find.byType(ImportDataScreen), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect tapping Clear & Reset to navigate to the clear and reset screen',
      (tester) async {
    await pumpSettings(tester);

    await scrollTo(tester, find.text('Clear & Reset'));
    await tester.tap(find.text('Clear & Reset'));
    await tester.pumpAndSettle();

    expect(find.byType(ClearResetScreen), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect tapping Send Feedback to navigate to the feedback screen',
      (tester) async {
    await pumpSettings(tester);

    await scrollTo(tester, find.text('Send Feedback'));
    await tester.tap(find.text('Send Feedback'));
    await tester.pumpAndSettle();

    expect(find.byType(FeedbackScreen), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect tapping About to navigate to the about screen',
      (tester) async {
    await pumpSettings(tester);

    await scrollTo(tester, find.text('About'));
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.byType(AboutScreen), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Subtitle reactivity
  // ---------------------------------------------------------------------------

  testWidgets(
      'As a user, I expect the Theme subtitle to update when I change the theme mode',
      (tester) async {
    await pumpSettings(tester);

    expect(find.text('System'), findsOneWidget);

    PreferencesService.themeModeNotifier.value = ThemeMode.dark;
    await tester.pump();
    expect(find.text('Dark'), findsOneWidget);

    // Reset to avoid leaking state.
    PreferencesService.themeModeNotifier.value = ThemeMode.system;
  });

  testWidgets(
      'As a user, I expect the Calendar subtitle to update when I change the week start day',
      (tester) async {
    await pumpSettings(tester);

    expect(find.text('Week starts on System'), findsOneWidget);

    PreferencesService.calendarStartDayNotifier.value = 'monday';
    await tester.pump();
    expect(find.text('Week starts on Monday'), findsOneWidget);

    PreferencesService.calendarStartDayNotifier.value = defaultCalendarStartDay;
  });

  // ---------------------------------------------------------------------------
  // Security section
  // ---------------------------------------------------------------------------

  testWidgets(
      'As a user, I expect to see a "Security" section header in settings',
      (tester) async {
    await pumpSettings(tester);

    await scrollTo(tester, find.text('Security'));
    expect(find.text('Security'), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect to see an "App Lock" tile in the Security section',
      (tester) async {
    await pumpSettings(tester);

    await scrollTo(tester, find.text('App Lock'));
    expect(find.text('App Lock'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'App Lock'),
        matching: find.text('Off'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'As a user, I expect tapping App Lock to navigate to the security settings screen',
      (tester) async {
    await pumpSettings(tester);

    await scrollTo(tester, find.text('App Lock'));
    await tester.tap(find.text('App Lock'));
    await tester.pumpAndSettle();

    expect(find.byType(SecuritySettingsScreen), findsOneWidget);
  });

  testWidgets(
      'As a user, I expect the App Lock subtitle to update when app lock is enabled',
      (tester) async {
    await pumpSettings(tester);

    await scrollTo(tester, find.text('App Lock'));
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'App Lock'),
        matching: find.text('Off'),
      ),
      findsOneWidget,
    );

    PreferencesService.appLockEnabledNotifier.value = true;
    await tester.pump();
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'App Lock'),
        matching: find.text('On'),
      ),
      findsOneWidget,
    );

    // Reset to avoid leaking state.
    PreferencesService.appLockEnabledNotifier.value = false;
  });

  // ---------------------------------------------------------------------------
  // Encryption migration warning banner
  // ---------------------------------------------------------------------------

  // When the encryption migration has failed, a warning banner should appear
  // at the top of the settings screen to alert the user.
  testWidgets(
      'As a user, I expect to see a warning banner at the top of settings when encryption migration has failed',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      prefKeyEncryptionMigrationFailed: true,
    });
    PreferencesService.encryptionMigrationFailedNotifier.value = true;

    await pumpSettings(tester);

    expect(find.text(encryptionRecoveryBannerTitle), findsOneWidget);
    expect(find.text(encryptionRecoveryBannerSubtitle), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    // Reset to avoid leaking state.
    PreferencesService.encryptionMigrationFailedNotifier.value = false;
  });

  // When encryption migration has not failed, no warning banner should appear.
  testWidgets(
      'As a user, I expect no warning banner in settings when encryption migration has not failed',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.encryptionMigrationFailedNotifier.value = false;

    await pumpSettings(tester);

    expect(find.text(encryptionRecoveryBannerTitle), findsNothing);
    expect(find.text(encryptionRecoveryBannerSubtitle), findsNothing);
  });

  // Tapping the warning banner should navigate to the EncryptionIssueScreen.
  testWidgets(
      'As a user, I expect tapping the encryption warning banner to navigate to the encryption issue screen',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      prefKeyEncryptionMigrationFailed: true,
    });
    PreferencesService.encryptionMigrationFailedNotifier.value = true;

    await pumpSettings(tester);

    await tester.tap(find.text(encryptionRecoveryBannerTitle));
    await tester.pumpAndSettle();

    expect(find.byType(EncryptionIssueScreen), findsOneWidget);

    // Reset to avoid leaking state.
    PreferencesService.encryptionMigrationFailedNotifier.value = false;
  });
}
