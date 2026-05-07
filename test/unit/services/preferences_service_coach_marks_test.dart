// preferences_service_coach_marks_test.dart: Tests for coach marks preferences.
//
// Verifies that PreferencesService correctly loads default values, saves and
// round-trips the coach-marks-seen flag, and includes it in bulk load/reset.
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
  // Has seen coach marks
  // ---------------------------------------------------------------------------
  group('PreferencesService.hasSeenCoachMarks', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PreferencesService.hasSeenCoachMarksNotifier.value =
          defaultHasSeenCoachMarks;
    });

    // Coach marks default to not seen on first launch.
    test(
        'As a user, I expect has_seen_coach_marks to default to false on first launch',
        () async {
      await PreferencesService.loadHasSeenCoachMarks();
      expect(PreferencesService.hasSeenCoachMarksNotifier.value,
          defaultHasSeenCoachMarks);
      expect(PreferencesService.hasSeenCoachMarksNotifier.value, false);
    });

    // Marking coach marks as seen persists and loads correctly.
    test(
        'As a user, I expect marking coach marks as seen to persist across app restarts',
        () async {
      await PreferencesService.saveHasSeenCoachMarks(true);
      expect(PreferencesService.hasSeenCoachMarksNotifier.value, true);

      // Simulate restart -- reset notifier then reload.
      PreferencesService.hasSeenCoachMarksNotifier.value = false;
      await PreferencesService.loadHasSeenCoachMarks();
      expect(PreferencesService.hasSeenCoachMarksNotifier.value, true);
    });

    // Saving the coach marks flag persists to SharedPreferences.
    test(
        'As a user, I expect the coach marks flag to persist to SharedPreferences',
        () async {
      await PreferencesService.saveHasSeenCoachMarks(true);
      expect(PreferencesService.hasSeenCoachMarksNotifier.value, true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(prefKeyHasSeenCoachMarks), true);
    });

    // Saving false explicitly persists to SharedPreferences.
    test(
        'As a user, I expect saving coach marks as not seen to persist false to SharedPreferences',
        () async {
      await PreferencesService.saveHasSeenCoachMarks(false);
      expect(PreferencesService.hasSeenCoachMarksNotifier.value, false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(prefKeyHasSeenCoachMarks), false);
    });

    // Pre-existing value is restored on load.
    test(
        'As a user, I expect a previously saved coach marks flag to be restored on launch',
        () async {
      SharedPreferences.setMockInitialValues({
        prefKeyHasSeenCoachMarks: true,
      });
      await PreferencesService.loadHasSeenCoachMarks();
      expect(PreferencesService.hasSeenCoachMarksNotifier.value, true);
    });

    // The notifier updates immediately on save, before reload is needed.
    test(
        'As a user, I expect the coach marks notifier to update immediately when saving',
        () async {
      expect(PreferencesService.hasSeenCoachMarksNotifier.value, false);
      await PreferencesService.saveHasSeenCoachMarks(true);
      expect(PreferencesService.hasSeenCoachMarksNotifier.value, true);
    });
  });

  // ---------------------------------------------------------------------------
  // loadAll includes coach marks preference
  // ---------------------------------------------------------------------------
  group('PreferencesService.loadAll with coach marks', () {
    setUp(() {
      PreferencesService.hasSeenCoachMarksNotifier.value =
          defaultHasSeenCoachMarks;
    });

    test(
        'As a user, I expect loadAll to include coach marks preference at startup',
        () async {
      SharedPreferences.setMockInitialValues({
        prefKeyHasSeenCoachMarks: true,
      });

      await PreferencesService.loadAll();

      expect(PreferencesService.hasSeenCoachMarksNotifier.value, true);
    });

    test(
        'As a user, I expect loadAll to use default when no coach marks preference is saved',
        () async {
      SharedPreferences.setMockInitialValues({});

      await PreferencesService.loadAll();

      expect(PreferencesService.hasSeenCoachMarksNotifier.value,
          defaultHasSeenCoachMarks);
    });
  });

  // ---------------------------------------------------------------------------
  // resetAll resets coach marks flag
  // ---------------------------------------------------------------------------
  group('PreferencesService.resetAll with coach marks', () {
    test(
        'As a user, I expect resetAll to reset the coach marks flag to default',
        () async {
      SharedPreferences.setMockInitialValues({});

      // Set non-default value first.
      await PreferencesService.saveHasSeenCoachMarks(true);
      expect(PreferencesService.hasSeenCoachMarksNotifier.value, true);

      // Reset all preferences.
      await PreferencesService.resetAll();

      expect(PreferencesService.hasSeenCoachMarksNotifier.value,
          defaultHasSeenCoachMarks);
      expect(PreferencesService.hasSeenCoachMarksNotifier.value, false);
    });

    test(
        'As a user, I expect resetAll to clear the coach marks flag from SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({});

      await PreferencesService.saveHasSeenCoachMarks(true);

      await PreferencesService.resetAll();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(prefKeyHasSeenCoachMarks), null);
    });
  });
}
