import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:symptom_tracker_app/app.dart';
import 'package:symptom_tracker_app/constants/defaults.dart';
import 'package:symptom_tracker_app/constants/layout.dart';
import 'package:symptom_tracker_app/services/preferences_service.dart';
import 'package:symptom_tracker_app/models/symptom_models.dart';
import 'package:symptom_tracker_app/screens/calendar_screen.dart';
import 'package:symptom_tracker_app/services/database.dart';

import '../../helpers/test_database.dart';

/// Widget tests for `lib/screens/calendar_screen.dart`.
///
/// CalendarScreen is the home screen. It displays a TableCalendar and lists
/// entries for the selected day. It obtains the database via Provider.
///
/// Note: TableCalendar uses internal page animations, so we avoid
/// `pumpAndSettle()`. Each test creates and closes its own DB instance.
///
/// Cross-ref:
///   - In-memory DB: test/helpers/test_database.dart (createTestDatabase)
///   - Screen under test: lib/screens/calendar_screen.dart
void main() {
  // Suppress the changelog modal in all existing tests by pre-setting the
  // last-seen version. PackageInfo mock is also required since CalendarScreen
  // now reads it in initState via _checkChangelog().
  setUp(() {
    SharedPreferences.setMockInitialValues({
      prefKeyLastSeenVersion: '1.0.0',
      prefKeyHasSeenOnboarding: true,
    });
    // Ensure the onboarding notifier is set so _checkChangelog() isn't guarded.
    PreferencesService.hasSeenOnboardingNotifier.value = true;
    PackageInfo.setMockInitialValues(
      appName: 'Wellnot',
      packageName: 'dev.alexo.symptom_tracker_app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  /// Helper to pump the CalendarScreen wrapped in Provider.
  Future<void> pumpCalendar(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(
      Provider<AppDatabase>(
        create: (_) => db,
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    // Single pump: allows initState + didChangeDependencies + async _loadEvents.
    await tester.pump();
  }

  // Renders the TableCalendar widget from the table_calendar package.
  testWidgets('As a user, I expect to see a calendar on the home screen',
      (tester) async {
    final db = createTestDatabase();
    await pumpCalendar(tester, db);

    expect(find.byType(TableCalendar<SymptomEntryModel>), findsOneWidget);
    await db.close();
  });

  // The app bar should display "Wellnot" as the title.
  testWidgets(
      'As a user, I expect to see "Wellnot" as the app title in the top bar',
      (tester) async {
    final db = createTestDatabase();
    await pumpCalendar(tester, db);

    expect(find.text('Wellnot'), findsOneWidget);
    await db.close();
  });

  // The settings gear icon should be present in the app bar.
  testWidgets(
      'As a user, I expect to see a settings icon in the top bar to access app settings',
      (tester) async {
    final db = createTestDatabase();
    await pumpCalendar(tester, db);

    expect(find.byIcon(Icons.settings), findsOneWidget);
    await db.close();
  });

  // The "Today" button should be visible but disabled when viewing today.
  testWidgets(
      'As a user, I expect the Today button to be disabled when I\'m already viewing today',
      (tester) async {
    final db = createTestDatabase();
    await pumpCalendar(tester, db);

    // Button is present but disabled (onPressed is null).
    final todayButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.today),
    );
    expect(todayButton.onPressed, isNull);
    await db.close();
  });

  // The add button (FAB on Android/Linux, AppBar on iOS) should be present.
  testWidgets(
      'As a user, I expect an add button to be available so I can log a new entry',
      (tester) async {
    final db = createTestDatabase();
    await pumpCalendar(tester, db);

    // Tests run on Linux, so the FAB variant is rendered.
    expect(find.byType(FloatingActionButton), findsOneWidget);
    await db.close();
  });

  // When entries exist in the DB for today, they should appear in the list
  // after the async _loadEvents() completes.
  testWidgets(
      'As a user, I expect my logged entries to appear under the selected day on the calendar',
      (tester) async {
    final db = createTestDatabase();

    // Insert an entry for today before building the widget.
    final now = DateTime.now();
    await db.saveEntry(
      dateTime: now,
      mood: '😊',
      notes: 'Test entry',
      symptoms: [UserSymptomModel(id: -1, name: 'Headache', severity: 3)],
      tags: [],
    );

    await tester.pumpWidget(
      Provider<AppDatabase>(
        create: (_) => db,
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    // Allow async _loadEvents() Future to complete.
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    expect(find.textContaining('Headache'), findsOneWidget);
    expect(find.textContaining('😊'), findsOneWidget);
    await db.close();
  });

  // When an entry has notes, a truncated preview should appear in the list.
  testWidgets(
      'As a user, I expect to see a preview of my notes in the entry list when notes are present',
      (tester) async {
    final db = createTestDatabase();

    final now = DateTime.now();
    await db.saveEntry(
      dateTime: now,
      mood: '😊',
      notes: 'This is a test note that should be previewed',
      symptoms: [UserSymptomModel(id: -1, name: 'Headache', severity: 3)],
      tags: [],
    );

    await tester.pumpWidget(
      Provider<AppDatabase>(
        create: (_) => db,
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    expect(find.textContaining('This is a test note'), findsOneWidget);
    await db.close();
  });

  // When an entry has no notes, no subtitle should appear.
  testWidgets(
      'As a user, I expect no note preview to appear in the entry list when no notes were added',
      (tester) async {
    final db = createTestDatabase();

    final now = DateTime.now();
    await db.saveEntry(
      dateTime: now,
      mood: '😊',
      notes: '',
      symptoms: [UserSymptomModel(id: -1, name: 'Fatigue', severity: 2)],
      tags: [],
    );

    await tester.pumpWidget(
      Provider<AppDatabase>(
        create: (_) => db,
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    // The entry should show but with no visible subtitle text.
    // The subtitle widget may be a SizedBox.shrink() rather than null
    // when the entry has no tag/note data to preview.
    expect(find.textContaining('Fatigue'), findsOneWidget);
    final listTile = tester.widget<ListTile>(find.byType(ListTile));
    expect(
      listTile.subtitle,
      anyOf(isNull, isA<SizedBox>()),
    );
    await db.close();
  });

  // When today is selected and there are no entries, show an empty state hint.
  testWidgets(
      'As a user, I expect to see a "No symptoms logged" hint when I have no entries for the selected day',
      (tester) async {
    final db = createTestDatabase();
    await pumpCalendar(tester, db);

    expect(find.textContaining('No symptoms logged'), findsOneWidget);
    await db.close();
  });

  // When today has entries, the empty state hint should not appear.
  testWidgets(
      'As a user, I expect the empty state hint to disappear when entries exist for the selected day',
      (tester) async {
    final db = createTestDatabase();

    await db.saveEntry(
      dateTime: DateTime.now(),
      mood: '😊',
      symptoms: [UserSymptomModel(id: -1, name: 'Headache', severity: 3)],
      tags: [],
    );

    await tester.pumpWidget(
      Provider<AppDatabase>(
        create: (_) => db,
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    expect(find.textContaining('No symptoms logged'), findsNothing);
    await db.close();
  });

  // When an entry is added externally (e.g., via persistent notification)
  // and entriesChangedNotifier fires, the calendar should refresh and show
  // the new entry without navigating away.
  testWidgets(
      'As a user, I expect the calendar to refresh and show new entries when they are added externally (e.g. via notification)',
      (tester) async {
    final db = createTestDatabase();
    await pumpCalendar(tester, db);

    // No entries initially.
    expect(find.textContaining('Headache'), findsNothing);

    // Simulate an entry being created externally (e.g., from notification).
    await tester.runAsync(() async {
      await db.saveEntry(
        dateTime: DateTime.now(),
        mood: '😊',
        notes: '',
        symptoms: [UserSymptomModel(id: -1, name: 'Headache', severity: 3)],
        tags: [],
      );
    });

    // Fire the notifier to signal that entries have changed.
    notifyEntriesChanged();

    // Allow async _loadEvents to complete.
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    // The new entry should now appear in the calendar list.
    expect(find.textContaining('Headache'), findsOneWidget);
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // Calendar start day preference
  // ---------------------------------------------------------------------------

  // When the user sets the calendar start day to 'monday', the calendar
  // should begin the week on Monday.
  testWidgets(
      'As a user, I expect the calendar to start on Monday when I set the week start day to monday',
      (tester) async {
    final db = createTestDatabase();

    // Set the start day preference before pumping the widget.
    PreferencesService.calendarStartDayNotifier.value = 'monday';

    await pumpCalendar(tester, db);

    final calendar = tester.widget<TableCalendar<SymptomEntryModel>>(
      find.byType(TableCalendar<SymptomEntryModel>),
    );
    expect(calendar.startingDayOfWeek, StartingDayOfWeek.monday);

    // Reset the notifier to default to avoid leaking state to other tests.
    PreferencesService.calendarStartDayNotifier.value = defaultCalendarStartDay;
    await db.close();
  });

  // When the user sets the calendar start day to 'saturday', the calendar
  // should begin the week on Saturday (new day support beyond Sun/Mon).
  testWidgets(
      'As a user, I expect the calendar to start on Saturday when I set the week start day to saturday',
      (tester) async {
    final db = createTestDatabase();

    // Set the start day preference before pumping the widget.
    PreferencesService.calendarStartDayNotifier.value = 'saturday';

    await pumpCalendar(tester, db);

    final calendar = tester.widget<TableCalendar<SymptomEntryModel>>(
      find.byType(TableCalendar<SymptomEntryModel>),
    );
    expect(calendar.startingDayOfWeek, StartingDayOfWeek.saturday);

    // Reset the notifier to default to avoid leaking state to other tests.
    PreferencesService.calendarStartDayNotifier.value = defaultCalendarStartDay;
    await db.close();
  });

  // The summary (insights) icon should be present in the app bar.
  testWidgets(
      'As a user, I expect to see a summary button in the app bar on the calendar screen',
      (tester) async {
    final db = createTestDatabase();
    await pumpCalendar(tester, db);

    expect(find.byIcon(Icons.insights), findsOneWidget);
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // Adaptive calendar row height (#117)
  // ---------------------------------------------------------------------------

  testWidgets(
      'As a user, I expect a compact calendar on small screens so the entry list has more room',
      (tester) async {
    final db = createTestDatabase();

    // Simulate a small screen (Galaxy S9: ~740x360 logical pixels).
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(360, 640)),
        child: Provider<AppDatabase>(
          create: (_) => db,
          child: const MaterialApp(home: CalendarScreen()),
        ),
      ),
    );
    await tester.pump();

    final calendar = tester.widget<TableCalendar<SymptomEntryModel>>(
      find.byType(TableCalendar<SymptomEntryModel>),
    );
    expect(calendar.rowHeight, calendarRowHeightCompact);
    expect(calendar.daysOfWeekHeight, calendarDaysOfWeekHeightCompact);
    await db.close();
  });

  testWidgets(
      'As a user, I expect the default calendar sizing on normal/large screens',
      (tester) async {
    final db = createTestDatabase();

    // Simulate a larger screen (Pixel 9 Pro: ~891x411 logical pixels).
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(411, 891)),
        child: Provider<AppDatabase>(
          create: (_) => db,
          child: const MaterialApp(home: CalendarScreen()),
        ),
      ),
    );
    await tester.pump();

    final calendar = tester.widget<TableCalendar<SymptomEntryModel>>(
      find.byType(TableCalendar<SymptomEntryModel>),
    );
    expect(calendar.rowHeight, calendarRowHeightDefault);
    expect(calendar.daysOfWeekHeight, calendarDaysOfWeekHeightDefault);
    await db.close();
  });

  // --- Changelog modal tests ---

  group('Changelog modal', () {
    testWidgets(
        'As a user, I expect to see the "What\'s New" modal on first launch when no version has been seen',
        (tester) async {
      // Simulate first launch: no lastSeenVersion stored.
      // Onboarding is marked as seen so the changelog guard doesn't suppress it.
      SharedPreferences.setMockInitialValues({
        prefKeyHasSeenOnboarding: true,
      });
      PackageInfo.setMockInitialValues(
        appName: 'Wellnot',
        packageName: 'dev.alexo.symptom_tracker_app',
        version: '1.9.0',
        buildNumber: '23',
        buildSignature: '',
      );

      final db = createTestDatabase();
      await tester.pumpWidget(
        Provider<AppDatabase>(
          create: (_) => db,
          child: const MaterialApp(home: CalendarScreen()),
        ),
      );
      // Allow post-frame callback + async changelog check to complete.
      await tester
          .runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();

      expect(find.text("What's New in v1.9.0"), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
      await db.close();
    });

    testWidgets(
        'As a user, I expect to see a "What\'s New" modal after updating to a new version',
        (tester) async {
      // Simulate update: last seen was 1.8.0, now running 1.9.0.
      SharedPreferences.setMockInitialValues({
        prefKeyLastSeenVersion: '1.8.0',
        prefKeyHasSeenOnboarding: true,
      });
      PackageInfo.setMockInitialValues(
        appName: 'Wellnot',
        packageName: 'dev.alexo.symptom_tracker_app',
        version: '1.9.0',
        buildNumber: '23',
        buildSignature: '',
      );

      final db = createTestDatabase();
      await tester.pumpWidget(
        Provider<AppDatabase>(
          create: (_) => db,
          child: const MaterialApp(home: CalendarScreen()),
        ),
      );
      await tester
          .runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();

      expect(find.text("What's New in v1.9.0"), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
      await db.close();
    });

    testWidgets(
        'As a user, I expect the changelog modal NOT to appear when the version has not changed',
        (tester) async {
      // Same version — modal should not appear.
      SharedPreferences.setMockInitialValues({
        prefKeyLastSeenVersion: '1.9.0',
        prefKeyHasSeenOnboarding: true,
      });
      PackageInfo.setMockInitialValues(
        appName: 'Wellnot',
        packageName: 'dev.alexo.symptom_tracker_app',
        version: '1.9.0',
        buildNumber: '23',
        buildSignature: '',
      );

      final db = createTestDatabase();
      await tester.pumpWidget(
        Provider<AppDatabase>(
          create: (_) => db,
          child: const MaterialApp(home: CalendarScreen()),
        ),
      );
      await tester
          .runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump();

      expect(find.text("What's New in v1.9.0"), findsNothing);
      expect(find.text("What's New in v1.9.0"), findsNothing);
      await db.close();
    });

    testWidgets(
        'As a user, I expect dismissing the changelog to persist the version so it does not reappear',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        prefKeyHasSeenOnboarding: true,
      });
      PackageInfo.setMockInitialValues(
        appName: 'Wellnot',
        packageName: 'dev.alexo.symptom_tracker_app',
        version: '1.9.0',
        buildNumber: '23',
        buildSignature: '',
      );

      final db = createTestDatabase();
      await tester.pumpWidget(
        Provider<AppDatabase>(
          create: (_) => db,
          child: const MaterialApp(home: CalendarScreen()),
        ),
      );
      await tester
          .runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();

      // Modal is showing.
      expect(find.text("What's New in v1.9.0"), findsOneWidget);

      // Dismiss.
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      // Modal is gone.
      expect(find.text("What's New in v1.9.0"), findsNothing);

      // Verify version was persisted.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(prefKeyLastSeenVersion), '1.9.0');
      await db.close();
    });
  });
}
