// preferences_service_test.dart: Unit tests for centralized preferences.
//
// Tests cover: load/save round-trips and default values for each preference
// managed by PreferencesService. Theme mode tests are in theme_mode_test.dart.
//
// Cross-ref:
//   - Service under test: lib/services/preferences_service.dart
//   - Preference keys & defaults: lib/constants/defaults.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:symptom_tracker_app/constants/defaults.dart';
import 'package:symptom_tracker_app/services/preferences_service.dart';

void main() {
  // Ensure Flutter bindings are initialized for SharedPreferences.
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Shake-to-feedback
  // ---------------------------------------------------------------------------
  group('PreferencesService.shakeToFeedback', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PreferencesService.shakeToFeedbackNotifier.value =
          defaultShakeToFeedbackEnabled;
    });

    test(
        'As a user, I expect shake-to-feedback to default to the app default on first launch',
        () async {
      await PreferencesService.loadShakeToFeedback();
      expect(PreferencesService.shakeToFeedbackNotifier.value,
          defaultShakeToFeedbackEnabled);
    });

    test(
        'As a user, I expect enabling shake-to-feedback to persist across app restarts',
        () async {
      await PreferencesService.saveShakeToFeedback(true);
      expect(PreferencesService.shakeToFeedbackNotifier.value, true);

      // Simulate restart — reset notifier then reload.
      PreferencesService.shakeToFeedbackNotifier.value = false;
      await PreferencesService.loadShakeToFeedback();
      expect(PreferencesService.shakeToFeedbackNotifier.value, true);
    });

    test(
        'As a user, I expect disabling shake-to-feedback to persist across app restarts',
        () async {
      await PreferencesService.saveShakeToFeedback(false);
      expect(PreferencesService.shakeToFeedbackNotifier.value, false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(prefKeyShakeToFeedback), false);
    });
  });

  // ---------------------------------------------------------------------------
  // Note preview toggle
  // ---------------------------------------------------------------------------
  group('PreferencesService.showNotePreview', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PreferencesService.showNotePreviewNotifier.value = defaultShowNotePreview;
    });

    test(
        'As a user, I expect note previews to default to enabled on first launch',
        () async {
      await PreferencesService.loadShowNotePreview();
      expect(PreferencesService.showNotePreviewNotifier.value,
          defaultShowNotePreview);
    });

    test(
        'As a user, I expect toggling note preview off to persist across app restarts',
        () async {
      await PreferencesService.saveShowNotePreview(false);
      expect(PreferencesService.showNotePreviewNotifier.value, false);

      // Simulate restart.
      PreferencesService.showNotePreviewNotifier.value = true;
      await PreferencesService.loadShowNotePreview();
      expect(PreferencesService.showNotePreviewNotifier.value, false);
    });
  });

  // ---------------------------------------------------------------------------
  // Tag preview toggle
  // ---------------------------------------------------------------------------
  group('PreferencesService.showTagPreview', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PreferencesService.showTagPreviewNotifier.value = defaultShowTagPreview;
    });

    test(
        'As a user, I expect tag previews to default to enabled on first launch',
        () async {
      await PreferencesService.loadShowTagPreview();
      expect(PreferencesService.showTagPreviewNotifier.value,
          defaultShowTagPreview);
    });

    test(
        'As a user, I expect toggling tag preview off to persist across app restarts',
        () async {
      await PreferencesService.saveShowTagPreview(false);
      expect(PreferencesService.showTagPreviewNotifier.value, false);

      // Simulate restart.
      PreferencesService.showTagPreviewNotifier.value = true;
      await PreferencesService.loadShowTagPreview();
      expect(PreferencesService.showTagPreviewNotifier.value, false);
    });
  });

  // ---------------------------------------------------------------------------
  // Calendar start day
  // ---------------------------------------------------------------------------
  group('PreferencesService.calendarStartDay', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PreferencesService.calendarStartDayNotifier.value =
          defaultCalendarStartDay;
    });

    test(
        'As a user, I expect the calendar start day to default to system on first launch',
        () async {
      await PreferencesService.loadCalendarStartDay();
      expect(PreferencesService.calendarStartDayNotifier.value,
          defaultCalendarStartDay);
    });

    test(
        'As a user, I expect choosing Monday as the start day to persist across app restarts',
        () async {
      await PreferencesService.saveCalendarStartDay('monday');
      expect(PreferencesService.calendarStartDayNotifier.value, 'monday');

      // Simulate restart.
      PreferencesService.calendarStartDayNotifier.value =
          defaultCalendarStartDay;
      await PreferencesService.loadCalendarStartDay();
      expect(PreferencesService.calendarStartDayNotifier.value, 'monday');
    });

    test(
        'As a user, I expect pre-existing calendar start day preference to be restored on launch',
        () async {
      SharedPreferences.setMockInitialValues({
        prefKeyCalendarStartDay: 'saturday',
      });
      await PreferencesService.loadCalendarStartDay();
      expect(PreferencesService.calendarStartDayNotifier.value, 'saturday');
    });
  });

  // ---------------------------------------------------------------------------
  // resolveStartDay
  // ---------------------------------------------------------------------------
  group('PreferencesService.resolveStartDay', () {
    test('As a user, I expect "monday" to resolve to Monday start day', () {
      expect(PreferencesService.resolveStartDay('monday'),
          StartingDayOfWeek.monday);
    });

    test('As a user, I expect "sunday" to resolve to Sunday start day', () {
      expect(PreferencesService.resolveStartDay('sunday'),
          StartingDayOfWeek.sunday);
    });

    test('As a user, I expect "saturday" to resolve to Saturday start day', () {
      expect(PreferencesService.resolveStartDay('saturday'),
          StartingDayOfWeek.saturday);
    });

    test('As a user, I expect "system" to fall back to the OS system start day',
        () {
      // Set a known system start day for deterministic testing.
      PreferencesService.systemStartDayNotifier.value =
          StartingDayOfWeek.wednesday;
      expect(PreferencesService.resolveStartDay('system'),
          StartingDayOfWeek.wednesday);
      // Reset to avoid leaking state.
      PreferencesService.systemStartDayNotifier.value =
          StartingDayOfWeek.sunday;
    });
  });

  // ---------------------------------------------------------------------------
  // calendarStartDayLabels
  // ---------------------------------------------------------------------------
  group('PreferencesService.calendarStartDayLabels', () {
    test('As a user, I expect all 8 start day options to have display labels',
        () {
      expect(PreferencesService.calendarStartDayLabels.length, 8);
      expect(PreferencesService.calendarStartDayLabels['system'], 'System');
      expect(PreferencesService.calendarStartDayLabels['monday'], 'Monday');
      expect(PreferencesService.calendarStartDayLabels['sunday'], 'Sunday');
      expect(PreferencesService.calendarStartDayLabels['saturday'], 'Saturday');
    });
  });

  // ---------------------------------------------------------------------------
  // loadAll (bulk loader)
  // ---------------------------------------------------------------------------
  group('PreferencesService.loadAll', () {
    test(
        'As a user, I expect all preferences to be loaded in one call at app startup',
        () async {
      SharedPreferences.setMockInitialValues({
        prefKeyThemeMode: 'dark',
        prefKeyShakeToFeedback: true,
        prefKeyCalendarStartDay: 'friday',
        prefKeyShowNotePreview: false,
        prefKeyShowTagPreview: false,
      });

      await PreferencesService.loadAll();

      expect(PreferencesService.themeModeNotifier.value, ThemeMode.dark);
      expect(PreferencesService.shakeToFeedbackNotifier.value, true);
      expect(PreferencesService.calendarStartDayNotifier.value, 'friday');
      expect(PreferencesService.showNotePreviewNotifier.value, false);
      expect(PreferencesService.showTagPreviewNotifier.value, false);
    });
  });
}
