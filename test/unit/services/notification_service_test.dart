// notification_service_test.dart: Tests for notification settings persistence
//
// Verifies that NotificationService correctly loads default settings when
// no SharedPreferences values exist, saves settings, and round-trips them.
//
// Cross-ref:
//   - Implementation: lib/services/notification_service.dart
//   - Constants: lib/constants/defaults.dart (default values + pref keys)
//   - SharedPreferences mock: SharedPreferences.setMockInitialValues()

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:symptom_tracker_app/constants/defaults.dart';
import 'package:symptom_tracker_app/services/notification_service.dart';

void main() {
  // Ensure Flutter bindings are initialized for SharedPreferences.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService settings', () {
    // loadSettings returns app defaults when SharedPreferences is empty.
    test(
        'As a user, I expect notification settings to default to disabled at 9:00 AM on first launch',
        () async {
      SharedPreferences.setMockInitialValues({});
      final service = NotificationService();
      final settings = await service.loadSettings();

      expect(settings.enabled, defaultNotificationsEnabled);
      expect(settings.hour, defaultNotificationHour);
      expect(settings.minute, defaultNotificationMinute);
    });

    // saveSettings persists values, and loadSettings reads them back.
    test(
        'As a user, I expect my notification settings to persist after I change them',
        () async {
      SharedPreferences.setMockInitialValues({});
      final service = NotificationService();

      await service.saveSettings(enabled: false, hour: 20, minute: 30);
      final settings = await service.loadSettings();

      expect(settings.enabled, false);
      expect(settings.hour, 20);
      expect(settings.minute, 30);
    });

    // loadSettings reads pre-existing SharedPreferences values correctly.
    test(
        'As a user, I expect the app to restore my previously saved notification settings on launch',
        () async {
      SharedPreferences.setMockInitialValues({
        prefKeyNotificationsEnabled: true,
        prefKeyNotificationHour: 14,
        prefKeyNotificationMinute: 45,
      });
      final service = NotificationService();
      final settings = await service.loadSettings();

      expect(settings.enabled, true);
      expect(settings.hour, 14);
      expect(settings.minute, 45);
    });

    // saveSettings overwrites previous values.
    test(
        'As a user, I expect changing notification settings to overwrite the previous values',
        () async {
      SharedPreferences.setMockInitialValues({
        prefKeyNotificationsEnabled: true,
        prefKeyNotificationHour: 8,
        prefKeyNotificationMinute: 0,
      });
      final service = NotificationService();

      await service.saveSettings(enabled: false, hour: 22, minute: 15);
      final settings = await service.loadSettings();

      expect(settings.enabled, false);
      expect(settings.hour, 22);
      expect(settings.minute, 15);
    });
  });

  group('Persistent notification settings', () {
    // Defaults to disabled when no pref exists.
    test(
        'As a user, I expect the persistent notification to be disabled by default on first launch',
        () async {
      SharedPreferences.setMockInitialValues({});
      final service = NotificationService();
      final enabled = await service.loadPersistentEnabled();

      expect(enabled, defaultPersistentNotificationEnabled);
    });

    // savePersistentEnabled + loadPersistentEnabled round-trip.
    test(
        'As a user, I expect toggling the persistent notification to save and restore correctly',
        () async {
      SharedPreferences.setMockInitialValues({});
      final service = NotificationService();

      await service.savePersistentEnabled(true);
      expect(await service.loadPersistentEnabled(), true);

      await service.savePersistentEnabled(false);
      expect(await service.loadPersistentEnabled(), false);
    });

    // Reads pre-existing value correctly.
    test(
        'As a user, I expect the app to restore my persistent notification preference on launch',
        () async {
      SharedPreferences.setMockInitialValues({
        prefKeyPersistentNotification: true,
      });
      final service = NotificationService();

      expect(await service.loadPersistentEnabled(), true);
    });
  });
}
