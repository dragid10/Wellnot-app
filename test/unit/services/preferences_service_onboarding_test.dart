// preferences_service_onboarding_test.dart: Tests for onboarding preferences.
//
// Verifies that PreferencesService correctly loads default values, saves and
// round-trips the onboarding-seen flag, and includes it in bulk load/reset.
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
  // Has seen onboarding
  // ---------------------------------------------------------------------------
  group('PreferencesService.hasSeenOnboarding', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PreferencesService.hasSeenOnboardingNotifier.value =
          defaultHasSeenOnboarding;
    });

    // Onboarding defaults to not seen on first launch.
    test(
        'As a user, I expect has_seen_onboarding to default to false on first launch',
        () async {
      await PreferencesService.loadHasSeenOnboarding();
      expect(PreferencesService.hasSeenOnboardingNotifier.value,
          defaultHasSeenOnboarding);
      expect(PreferencesService.hasSeenOnboardingNotifier.value, false);
    });

    // Marking onboarding as seen persists and loads correctly.
    test(
        'As a user, I expect marking onboarding as seen to persist across app restarts',
        () async {
      await PreferencesService.saveHasSeenOnboarding(true);
      expect(PreferencesService.hasSeenOnboardingNotifier.value, true);

      // Simulate restart — reset notifier then reload.
      PreferencesService.hasSeenOnboardingNotifier.value = false;
      await PreferencesService.loadHasSeenOnboarding();
      expect(PreferencesService.hasSeenOnboardingNotifier.value, true);
    });

    // Saving the onboarding flag persists to SharedPreferences.
    test(
        'As a user, I expect the onboarding flag to persist to SharedPreferences',
        () async {
      await PreferencesService.saveHasSeenOnboarding(true);
      expect(PreferencesService.hasSeenOnboardingNotifier.value, true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(prefKeyHasSeenOnboarding), true);
    });

    // Pre-existing value is restored on load.
    test(
        'As a user, I expect a previously saved onboarding flag to be restored on launch',
        () async {
      SharedPreferences.setMockInitialValues({
        prefKeyHasSeenOnboarding: true,
      });
      await PreferencesService.loadHasSeenOnboarding();
      expect(PreferencesService.hasSeenOnboardingNotifier.value, true);
    });
  });

  // ---------------------------------------------------------------------------
  // loadAll includes onboarding preference
  // ---------------------------------------------------------------------------
  group('PreferencesService.loadAll with onboarding', () {
    setUp(() {
      PreferencesService.hasSeenOnboardingNotifier.value =
          defaultHasSeenOnboarding;
    });

    test(
        'As a user, I expect loadAll to include onboarding preference at startup',
        () async {
      SharedPreferences.setMockInitialValues({
        prefKeyHasSeenOnboarding: true,
      });

      await PreferencesService.loadAll();

      expect(PreferencesService.hasSeenOnboardingNotifier.value, true);
    });

    test(
        'As a user, I expect loadAll to use default when no onboarding preference is saved',
        () async {
      SharedPreferences.setMockInitialValues({});

      await PreferencesService.loadAll();

      expect(PreferencesService.hasSeenOnboardingNotifier.value,
          defaultHasSeenOnboarding);
    });
  });

  // ---------------------------------------------------------------------------
  // resetAll resets onboarding flag
  // ---------------------------------------------------------------------------
  group('PreferencesService.resetAll with onboarding', () {
    test('As a user, I expect resetAll to reset the onboarding flag to default',
        () async {
      SharedPreferences.setMockInitialValues({});

      // Set non-default value first.
      await PreferencesService.saveHasSeenOnboarding(true);
      expect(PreferencesService.hasSeenOnboardingNotifier.value, true);

      // Reset all preferences.
      await PreferencesService.resetAll();

      expect(PreferencesService.hasSeenOnboardingNotifier.value,
          defaultHasSeenOnboarding);
      expect(PreferencesService.hasSeenOnboardingNotifier.value, false);
    });

    test(
        'As a user, I expect resetAll to clear the onboarding flag from SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({});

      await PreferencesService.saveHasSeenOnboarding(true);

      await PreferencesService.resetAll();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(prefKeyHasSeenOnboarding), null);
    });
  });
}
