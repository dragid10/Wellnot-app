// main.dart: Entry point for the Wellnot app.
//
// This file is a thin bootstrap — it initializes the database, loads
// preferences, and notification service, then hands off to MyApp (in app.dart).
//
// Cross-ref:
//   - Root widget: app.dart (MyApp)
//   - Database: services/database.dart
//   - Preferences: services/preferences_service.dart
//   - Notifications: services/notification_service.dart
//   - Entry screen: screens/entry_screen.dart (opened by persistent notification tap)

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'services/database.dart';
import 'services/home_widget_service.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';
import 'screens/detail_screen.dart';
import 'screens/entry_screen.dart';
import 'app.dart';

/// App entry point. Initializes core services before launching the UI.
///
/// Sequence:
/// 1. Ensure Flutter bindings are ready (required for async work before runApp)
/// 2. Create the local SQLite database via Drift
/// 3. Load all user preferences so the UI renders with correct settings
/// 4. Launch the widget tree immediately (avoids white screen)
/// 5. Initialize notifications after the UI is rendered
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();

  // Load all preferences before launching the UI so the correct theme,
  // calendar start day, etc. are applied immediately (avoids flashes).
  await PreferencesService.loadAll();

  // Initialize home screen widget data bridge (App Group on iOS).
  await HomeWidgetService.initialize();

  // Launch the UI first so the user doesn't see a white screen while
  // notification services initialize (especially on iOS where plugin
  // init can trigger platform channel calls that block).
  runApp(MyApp(database: database));

  // Initialize notifications after the UI is up.
  _initNotifications();

  // Push initial widget data so widgets show current state on first add.
  HomeWidgetService.updateWidgetData(database);

  // Handle deep links from home screen widget taps.
  _initHomeWidgetLinks(database);
}

/// Handles a deep link URI from a widget tap.
/// - wellnot://newEntry → opens entry screen
/// - wellnot://entry/{id} → opens detail screen for that entry
Future<void> _handleWidgetUri(Uri? uri, AppDatabase database) async {
  if (uri == null) return;

  // Schedule navigation after the current frame to ensure the widget tree
  // is fully built (critical on cold start from a widget tap).
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (uri.host == 'newentry') {
      final result = await navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => const SymptomEntryScreen(),
        ),
      );
      if (result == true) {
        notifyEntriesChanged();
      }
    } else if (uri.host == 'entry' && uri.pathSegments.isNotEmpty) {
      final entryId = int.tryParse(uri.pathSegments.first);
      if (entryId == null) return;
      final entry = await database.getEntryById(entryId);
      if (entry == null) return;
      final result = await navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => SymptomDetailScreen(entry: entry),
        ),
      );
      if (result == true) {
        notifyEntriesChanged();
      }
    }
  });
}

/// Sets up deep link handling for home screen widget taps.
void _initHomeWidgetLinks(AppDatabase database) {
  HomeWidget.initiallyLaunchedFromHomeWidget()
      .then((uri) => _handleWidgetUri(uri, database));
  HomeWidget.widgetClicked.listen((uri) => _handleWidgetUri(uri, database));
}

/// Sets up the notification service, tap handler, and applies persisted
/// settings. Runs after runApp() so the UI is already rendered.
Future<void> _initNotifications() async {
  try {
    final notificationService = NotificationService();
    await notificationService.init();

    // Handle notification taps — the persistent "quick add" notification
    // opens the new entry screen when tapped.
    notificationService.onNotificationTap = (payload) {
      if (payload == 'open_new_entry') {
        navigatorKey.currentState
            ?.push(
          MaterialPageRoute(
            builder: (context) => const SymptomEntryScreen(),
          ),
        )
            .then((result) {
          if (result == true) {
            notifyEntriesChanged();
          }
        });
      }
    };

    // Load persisted notification settings and schedule/cancel accordingly.
    await notificationService.applySettings();
    await notificationService.applyPersistentNotification();
  } catch (e) {
    debugPrint('Notification setup skipped: $e');
  }
}
