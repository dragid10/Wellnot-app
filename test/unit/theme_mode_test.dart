// theme_mode_test.dart: Tests for theme mode preference persistence.
//
// Verifies that PreferencesService correctly loads, saves, and round-trips
// theme mode preferences via SharedPreferences.
//
// Cross-ref:
//   - Implementation: lib/services/preferences_service.dart
//   - Constants: lib/constants/defaults.dart (prefKeyThemeMode, defaultThemeMode)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:symptom_tracker_app/constants/defaults.dart';
import 'package:symptom_tracker_app/services/preferences_service.dart';

void main() {
  // loadThemeMode reads from SharedPreferences and updates themeModeNotifier.
  group('PreferencesService.loadThemeMode', () {
    setUp(() {
      PreferencesService.themeModeNotifier.value = ThemeMode.system;
    });

    test(
        'As a user, I expect the app to restore dark mode when I previously selected it',
        () async {
      SharedPreferences.setMockInitialValues({prefKeyThemeMode: 'dark'});
      await PreferencesService.loadThemeMode();
      expect(PreferencesService.themeModeNotifier.value, ThemeMode.dark);
    });

    test(
        'As a user, I expect the app to restore light mode when I previously selected it',
        () async {
      SharedPreferences.setMockInitialValues({prefKeyThemeMode: 'light'});
      await PreferencesService.loadThemeMode();
      expect(PreferencesService.themeModeNotifier.value, ThemeMode.light);
    });

    test(
        'As a user, I expect the app to follow system theme on first launch when no preference has been set',
        () async {
      SharedPreferences.setMockInitialValues({});
      await PreferencesService.loadThemeMode();
      expect(PreferencesService.themeModeNotifier.value, ThemeMode.system);
    });

    // Unknown stored values should gracefully fall back to system mode
    // rather than crashing.
    test(
        'As a user, I expect unknown or empty theme preferences to default to system mode',
        () async {
      SharedPreferences.setMockInitialValues({prefKeyThemeMode: 'unknown'});
      await PreferencesService.loadThemeMode();
      expect(PreferencesService.themeModeNotifier.value, ThemeMode.system);

      SharedPreferences.setMockInitialValues({prefKeyThemeMode: ''});
      await PreferencesService.loadThemeMode();
      expect(PreferencesService.themeModeNotifier.value, ThemeMode.system);
    });
  });

  // saveThemeMode writes to SharedPreferences and updates themeModeNotifier.
  group('PreferencesService.saveThemeMode', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PreferencesService.themeModeNotifier.value = ThemeMode.system;
    });

    test(
        'As a user, I expect selecting dark mode to save my preference and apply it immediately',
        () async {
      await PreferencesService.saveThemeMode(ThemeMode.dark);
      expect(PreferencesService.themeModeNotifier.value, ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(prefKeyThemeMode), 'dark');
    });

    test(
        'As a user, I expect selecting light mode to save my preference and apply it immediately',
        () async {
      await PreferencesService.saveThemeMode(ThemeMode.light);
      expect(PreferencesService.themeModeNotifier.value, ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(prefKeyThemeMode), 'light');
    });

    // Round-trip: save then load should restore the same value.
    test(
        'As a user, I expect my theme preference to survive an app restart — save then load round-trip',
        () async {
      await PreferencesService.saveThemeMode(ThemeMode.dark);
      // Reset the notifier to simulate app restart.
      PreferencesService.themeModeNotifier.value = ThemeMode.system;
      await PreferencesService.loadThemeMode();
      expect(PreferencesService.themeModeNotifier.value, ThemeMode.dark);
    });
  });
}
