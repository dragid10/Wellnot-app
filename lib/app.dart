// app.dart: Root widget for the Wellnot app.
//
// Extracted from main.dart to keep the entry point thin (bootstrap only).
// Wraps the widget tree with Provider<AppDatabase> and configures theming.
//
// Preferences (theme, calendar start day, etc.) are managed by
// PreferencesService — this file only reads the notifiers, not owns them.
//
// Cross-ref:
//   - Bootstrap: main.dart (creates the DB and runs this widget)
//   - Home screen: screens/calendar_screen.dart
//   - Database: services/database.dart (provided via Provider)
//   - Preferences: services/preferences_service.dart (ValueNotifiers)
//   - Notification tap routing: main.dart sets up onNotificationTap using
//     [navigatorKey] to push the entry screen.
//   - Shake detection: services/shake_detector.dart

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'services/achievement_service.dart';
import 'services/database.dart';
import 'services/home_widget_service.dart';
import 'services/preferences_service.dart';
import 'services/shake_detector.dart';
import 'screens/calendar_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/onboarding_screen.dart';

/// Global navigator key so notification tap handlers (in main.dart) can
/// push routes without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Notifier that fires when entries are created, updated, or deleted.
/// CalendarScreen listens to this to refresh its event list, ensuring
/// entries created from the persistent notification (or any other entry
/// point) appear immediately.
final ValueNotifier<int> entriesChangedNotifier = ValueNotifier(0);

/// Database reference for pushing widget data on entry changes.
/// Set once by [_MyAppState.initState] — not null during normal app lifecycle.
AppDatabase? _widgetDatabase;

/// Call this after saving or deleting an entry to trigger a calendar refresh
/// and update home screen widgets with the latest data.
void notifyEntriesChanged() {
  entriesChangedNotifier.value++;
  if (_widgetDatabase != null) {
    HomeWidgetService.updateWidgetData(_widgetDatabase!);
  }
}

/// Notifier that fires when achievements are newly unlocked.
/// CalendarScreen listens to this to show congratulatory toasts.
/// The value is a list of achievement IDs (empty list means no notification).
final ValueNotifier<List<String>> achievementUnlockedNotifier =
    ValueNotifier([]);

/// Call this after achievements are unlocked to trigger toasts on the
/// calendar screen. Pass the full list of newly unlocked IDs.
void notifyAchievementsUnlocked(List<String> achievementIds) {
  achievementUnlockedNotifier.value = List.of(achievementIds);
}

/// Notifier that tells a visible AchievementsScreen to scroll to a specific
/// achievement. Set by the toast "View" button when the screen is already open.
final ValueNotifier<String> achievementScrollToNotifier = ValueNotifier('');

class MyApp extends StatefulWidget {
  final AppDatabase database;
  const MyApp({super.key, required this.database});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  ShakeDetector? _shakeDetector;

  /// Whether the app is currently showing the onboarding walkthrough.
  bool _showOnboarding = false;

  /// Whether the app is currently showing the lock screen.
  bool _isLocked = false;

  /// Timestamp when the app was last fully backgrounded (paused state).
  /// Used with the grace period to decide if re-auth is needed on resume.
  DateTime? _lastPausedAt;

  /// Error message to display on the lock screen (e.g., auth failed).
  String? _lockError;

  /// Guards against re-lock during an active biometric prompt.
  /// The system auth dialog triggers paused → resumed lifecycle events
  /// which would otherwise cause a feedback loop.
  bool _isAuthenticating = false;

  /// End of the post-authentication cooldown window. During this window,
  /// lifecycle events are ignored for lock purposes. The system auth dialog
  /// on Android triggers multiple paused → resumed cycles as the activity
  /// stack settles — this cooldown covers all of them.
  DateTime? _authCooldownUntil;

  /// Whether we are currently in the post-auth cooldown window.
  bool get _inAuthCooldown =>
      _authCooldownUntil != null &&
      DateTime.now().isBefore(_authCooldownUntil!);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _widgetDatabase = widget.database;
    // Start listening for shake gestures to open the feedback screen.
    _shakeDetector = ShakeDetector(
      onShake: _onShake,
      shakeThreshold: 40.0,
      cooldownMs: 3000,
    );
    _shakeDetector!.start();

    // Show onboarding on first launch. Checked before app lock because
    // first launch won't have lock enabled, and on reinstall both prefs
    // are cleared so they never conflict.
    if (!PreferencesService.hasSeenOnboardingNotifier.value) {
      _showOnboarding = true;
    }

    // If app lock is enabled, start locked and auto-trigger authentication.
    if (PreferencesService.appLockEnabledNotifier.value) {
      _isLocked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticate();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shakeDetector?.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Record when the app was fully backgrounded for grace period
      // calculation. Only track `paused`, not `inactive` — pulling down
      // the notification shade or Control Center should not trigger re-auth.
      // Ignore paused events during authentication and the post-auth
      // cooldown — the system auth dialog triggers paused/resumed cycles
      // which aren't real background events.
      if (!_isAuthenticating && !_inAuthCooldown) {
        _lastPausedAt = DateTime.now();
      }
    }
    if (state == AppLifecycleState.resumed) {
      // Re-fetch the system's first day of week when the app resumes,
      // in case the user changed it in system settings while backgrounded.
      PreferencesService.fetchSystemStartDay();
      // Refresh widget data so it shows today's entries (clears stale data
      // if the day rolled over while the app was backgrounded).
      HomeWidgetService.updateWidgetData(widget.database);
      // Check if re-authentication is needed after returning from background.
      _checkLockOnResume();
    }
  }

  /// Checks whether the app should be locked after resuming from background.
  void _checkLockOnResume() {
    if (_isAuthenticating) return;
    if (_isLocked) return;
    if (_inAuthCooldown) return;

    final shouldLock = PreferencesService.shouldLockOnResume(
      appLockEnabled: PreferencesService.appLockEnabledNotifier.value,
      lastPausedAt: _lastPausedAt,
      gracePeriodSeconds: PreferencesService.appLockGracePeriodNotifier.value,
    );

    if (shouldLock) {
      setState(() {
        _isLocked = true;
        _lockError = null;
      });
      _authenticate();
    }
  }

  /// Attempts device authentication via biometrics or PIN.
  ///
  /// On success, dismisses the lock screen. On failure, shows an error
  /// message with a "Try Again" option.
  Future<void> _authenticate() async {
    _isAuthenticating = true;
    final localAuth = LocalAuthentication();
    try {
      final authenticated = await localAuth.authenticate(
        localizedReason: 'Authenticate to unlock Wellnot',
        persistAcrossBackgrounding: false,
        biometricOnly: false,
      );
      if (authenticated) {
        // Set a 3-second cooldown window. During this window, lifecycle
        // events from the auth dialog dismissal are ignored — both for
        // tracking _lastPausedAt and for _checkLockOnResume. Samsung
        // devices (Knox) generate a post-auth lifecycle cycle that
        // completes within ~1 second; 3 seconds provides margin.
        _authCooldownUntil = DateTime.now().add(const Duration(seconds: 3));
        // Clear _lastPausedAt so phantom lifecycle events that slip past
        // the cooldown can't trigger a re-lock using a stale timestamp.
        _lastPausedAt = null;
        setState(() {
          _isLocked = false;
          _lockError = null;
        });
      } else {
        setState(() {
          _lockError = 'Authentication failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _lockError = 'Authentication unavailable. Please try again.';
      });
    } finally {
      _isAuthenticating = false;
    }
  }

  /// Called when the device is shaken — opens the feedback screen and
  /// checks for the shake feedback achievement.
  void _onShake() {
    if (!PreferencesService.shakeToFeedbackNotifier.value) return;
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => const FeedbackScreen(),
      ),
    );
    _checkShakeFeedbackAchievement();
  }

  Future<void> _checkShakeFeedbackAchievement() async {
    if (!PreferencesService.achievementsEnabledNotifier.value) return;
    final unlocked =
        await AchievementService.checkAfterShakeFeedback(widget.database);
    if (unlocked.isNotEmpty) {
      notifyAchievementsUnlocked(unlocked);
    }
  }

  /// Called when the user completes or skips the onboarding walkthrough.
  /// Persists the flag and removes the overlay.
  void _completeOnboarding() {
    PreferencesService.saveHasSeenOnboarding(true);
    setState(() {
      _showOnboarding = false;
    });
  }

  /// Resolves the effective brightness for the lock screen theme.
  ///
  /// The lock screen sits above MaterialApp in the widget tree, so it
  /// doesn't inherit the app's theme. This helper mirrors the theme mode
  /// logic so the lock screen matches the app's appearance.
  Brightness _resolveBrightness(ThemeMode mode) {
    if (mode == ThemeMode.light) return Brightness.light;
    if (mode == ThemeMode.dark) return Brightness.dark;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  @override
  Widget build(BuildContext context) {
    return Provider<AppDatabase>(
      create: (_) => widget.database,
      dispose: (_, db) => db.close(),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: PreferencesService.themeModeNotifier,
        builder: (context, themeMode, _) {
          final app = MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Wellnot',
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorSchemeSeed: Colors.teal,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorSchemeSeed: Colors.teal,
            ),
            themeMode: themeMode,
            home: const CalendarScreen(),
          );

          Widget result = app;

          if (_isLocked) {
            // Lock screen overlay — sits above MaterialApp so no content
            // is visible while locked. Needs its own Theme since it's
            // outside the MaterialApp widget tree.
            final lockTheme = ThemeData(
              useMaterial3: true,
              brightness: _resolveBrightness(themeMode),
              colorSchemeSeed: Colors.teal,
            );

            result = Directionality(
              textDirection: TextDirection.ltr,
              child: Stack(
                children: [
                  result,
                  Theme(
                    data: lockTheme,
                    child: LockScreen(
                      onUnlockRequested: _authenticate,
                      errorMessage: _lockError,
                    ),
                  ),
                ],
              ),
            );
          }

          if (_showOnboarding) {
            // Onboarding overlay — sits above everything (including lock
            // screen) on first launch. Needs its own Theme since it's
            // outside the MaterialApp widget tree.
            final onboardingTheme = ThemeData(
              useMaterial3: true,
              brightness: _resolveBrightness(themeMode),
              colorSchemeSeed: Colors.teal,
            );

            result = Directionality(
              textDirection: TextDirection.ltr,
              child: Stack(
                children: [
                  result,
                  Theme(
                    data: onboardingTheme,
                    child: OnboardingScreen(
                      onComplete: _completeOnboarding,
                    ),
                  ),
                ],
              ),
            );
          }

          return result;
        },
      ),
    );
  }
}
