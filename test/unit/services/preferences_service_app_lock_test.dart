// preferences_service_app_lock_test.dart: Tests for app lock preferences.
//
// Verifies that PreferencesService correctly loads default values, saves and
// round-trips app lock settings, and includes app lock in bulk load/reset.
//
// Cross-ref:
//   - Service under test: lib/services/preferences_service.dart
//   - Preference keys & defaults: lib/constants/defaults.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:symptom_tracker_app/constants/defaults.dart';
import 'package:symptom_tracker_app/services/preferences_service.dart';

void main() {
  // Ensure Flutter bindings are initialized for SharedPreferences.
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // App lock enabled
  // ---------------------------------------------------------------------------
  group('PreferencesService.appLockEnabled', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PreferencesService.appLockEnabledNotifier.value = defaultAppLockEnabled;
    });

    // App lock defaults to disabled on first launch.
    test('As a user, I expect app lock to default to disabled on first launch',
        () async {
      await PreferencesService.loadAppLockEnabled();
      expect(PreferencesService.appLockEnabledNotifier.value,
          defaultAppLockEnabled);
      expect(PreferencesService.appLockEnabledNotifier.value, false);
    });

    // Enabling app lock persists and loads correctly.
    test('As a user, I expect enabling app lock to persist across app restarts',
        () async {
      await PreferencesService.saveAppLockEnabled(true);
      expect(PreferencesService.appLockEnabledNotifier.value, true);

      // Simulate restart — reset notifier then reload.
      PreferencesService.appLockEnabledNotifier.value = false;
      await PreferencesService.loadAppLockEnabled();
      expect(PreferencesService.appLockEnabledNotifier.value, true);
    });

    // Disabling app lock persists to SharedPreferences.
    test(
        'As a user, I expect disabling app lock to persist to SharedPreferences',
        () async {
      await PreferencesService.saveAppLockEnabled(false);
      expect(PreferencesService.appLockEnabledNotifier.value, false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(prefKeyAppLockEnabled), false);
    });

    // Pre-existing value is restored on load.
    test(
        'As a user, I expect the app to restore my previously saved app lock preference on launch',
        () async {
      SharedPreferences.setMockInitialValues({
        prefKeyAppLockEnabled: true,
      });
      await PreferencesService.loadAppLockEnabled();
      expect(PreferencesService.appLockEnabledNotifier.value, true);
    });
  });

  // ---------------------------------------------------------------------------
  // App lock grace period
  // ---------------------------------------------------------------------------
  group('PreferencesService.appLockGracePeriod', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PreferencesService.appLockGracePeriodNotifier.value =
          defaultAppLockGracePeriodSeconds;
    });

    // Grace period defaults to immediately on first launch.
    test(
        'As a user, I expect the grace period to default to immediately on first launch',
        () async {
      await PreferencesService.loadAppLockGracePeriod();
      expect(PreferencesService.appLockGracePeriodNotifier.value,
          defaultAppLockGracePeriodSeconds);
      expect(PreferencesService.appLockGracePeriodNotifier.value, 0);
    });

    // Changing grace period persists and loads correctly.
    test(
        'As a user, I expect changing the grace period to persist across app restarts',
        () async {
      await PreferencesService.saveAppLockGracePeriod(60);
      expect(PreferencesService.appLockGracePeriodNotifier.value, 60);

      // Simulate restart — reset notifier then reload.
      PreferencesService.appLockGracePeriodNotifier.value =
          defaultAppLockGracePeriodSeconds;
      await PreferencesService.loadAppLockGracePeriod();
      expect(PreferencesService.appLockGracePeriodNotifier.value, 60);
    });

    // Setting grace period to 0 (immediately) persists correctly.
    test(
        'As a user, I expect setting the grace period to 0 (immediately) to persist correctly',
        () async {
      await PreferencesService.saveAppLockGracePeriod(0);
      expect(PreferencesService.appLockGracePeriodNotifier.value, 0);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(prefKeyAppLockGracePeriod), 0);
    });

    // Pre-existing value is restored on load.
    test(
        'As a user, I expect the app to restore my previously saved grace period on launch',
        () async {
      SharedPreferences.setMockInitialValues({
        prefKeyAppLockGracePeriod: 60,
      });
      await PreferencesService.loadAppLockGracePeriod();
      expect(PreferencesService.appLockGracePeriodNotifier.value, 60);
    });
  });

  // ---------------------------------------------------------------------------
  // loadAll includes app lock preferences
  // ---------------------------------------------------------------------------
  group('PreferencesService.loadAll with app lock', () {
    test(
        'As a user, I expect loadAll to include app lock preferences at startup',
        () async {
      SharedPreferences.setMockInitialValues({
        prefKeyAppLockEnabled: true,
        prefKeyAppLockGracePeriod: 60,
      });

      await PreferencesService.loadAll();

      expect(PreferencesService.appLockEnabledNotifier.value, true);
      expect(PreferencesService.appLockGracePeriodNotifier.value, 60);
    });

    test(
        'As a user, I expect loadAll to use defaults when no app lock preferences are saved',
        () async {
      SharedPreferences.setMockInitialValues({});

      await PreferencesService.loadAll();

      expect(PreferencesService.appLockEnabledNotifier.value,
          defaultAppLockEnabled);
      expect(PreferencesService.appLockGracePeriodNotifier.value,
          defaultAppLockGracePeriodSeconds);
    });
  });

  // ---------------------------------------------------------------------------
  // resetAll disables app lock and resets grace period
  // ---------------------------------------------------------------------------
  group('PreferencesService.resetAll with app lock', () {
    test(
        'As a user, I expect resetAll to disable app lock and reset grace period to default',
        () async {
      SharedPreferences.setMockInitialValues({});

      // Set non-default values first.
      await PreferencesService.saveAppLockEnabled(true);
      await PreferencesService.saveAppLockGracePeriod(60);
      expect(PreferencesService.appLockEnabledNotifier.value, true);
      expect(PreferencesService.appLockGracePeriodNotifier.value, 60);

      // Reset all preferences.
      await PreferencesService.resetAll();

      expect(PreferencesService.appLockEnabledNotifier.value,
          defaultAppLockEnabled);
      expect(PreferencesService.appLockEnabledNotifier.value, false);
      expect(PreferencesService.appLockGracePeriodNotifier.value,
          defaultAppLockGracePeriodSeconds);
      expect(PreferencesService.appLockGracePeriodNotifier.value, 0);
    });

    test(
        'As a user, I expect resetAll to clear app lock preferences from SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({});

      await PreferencesService.saveAppLockEnabled(true);
      await PreferencesService.saveAppLockGracePeriod(60);

      await PreferencesService.resetAll();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(prefKeyAppLockEnabled), null);
      expect(prefs.getInt(prefKeyAppLockGracePeriod), null);
    });
  });

  // ---------------------------------------------------------------------------
  // Grace period labels
  // ---------------------------------------------------------------------------
  group('PreferencesService.appLockGracePeriodLabels', () {
    test('As a user, I expect all grace period options to have display labels',
        () {
      expect(PreferencesService.appLockGracePeriodLabels.length, 4);
      expect(PreferencesService.appLockGracePeriodLabels[0], 'Immediately');
      expect(PreferencesService.appLockGracePeriodLabels[60], '1 minute');
      expect(PreferencesService.appLockGracePeriodLabels[300], '5 minutes');
      expect(PreferencesService.appLockGracePeriodLabels[600], '10 minutes');
    });
  });
}
