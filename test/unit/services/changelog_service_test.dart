// changelog_service_test.dart: Tests for changelog version-check logic
//
// Verifies that ChangelogService correctly detects first launch, version
// changes, and returns appropriate changelog entries.
//
// Cross-ref:
//   - Implementation: lib/services/changelog_service.dart
//   - Constants: lib/constants/defaults.dart (prefKeyLastSeenVersion)
//   - Changelog data: lib/constants/changelog.dart
//   - SharedPreferences mock pattern: test/unit/services/notification_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:symptom_tracker_app/constants/changelog.dart';
import 'package:symptom_tracker_app/constants/defaults.dart';
import 'package:symptom_tracker_app/services/changelog_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChangelogService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    // --- shouldShowChangelog ---

    test(
        'As a user, I expect to see the changelog on first launch when no version has been stored',
        () async {
      final shouldShow = await ChangelogService.shouldShowChangelog('1.9.0');
      expect(shouldShow, isTrue);
    });

    test(
        'As a user, I expect to see the changelog after updating to a new version',
        () async {
      SharedPreferences.setMockInitialValues({
        prefKeyLastSeenVersion: '1.8.0',
      });
      final shouldShow = await ChangelogService.shouldShowChangelog('1.9.0');
      expect(shouldShow, isTrue);
    });

    test(
        'As a user, I expect NOT to see the changelog on subsequent launches when the version has not changed',
        () async {
      SharedPreferences.setMockInitialValues({
        prefKeyLastSeenVersion: '1.9.0',
      });
      final shouldShow = await ChangelogService.shouldShowChangelog('1.9.0');
      expect(shouldShow, isFalse);
    });

    // --- loadLastSeenVersion / saveLastSeenVersion ---

    test('As a user, I expect the last-seen version to be null on first launch',
        () async {
      final lastSeen = await ChangelogService.loadLastSeenVersion();
      expect(lastSeen, isNull);
    });

    test(
        'As a user, I expect the last-seen version to persist after dismissing the changelog',
        () async {
      await ChangelogService.saveLastSeenVersion('1.9.0');
      final lastSeen = await ChangelogService.loadLastSeenVersion();
      expect(lastSeen, '1.9.0');
    });

    test(
        'As a user, I expect the last-seen version to update when I dismiss a newer changelog',
        () async {
      SharedPreferences.setMockInitialValues({
        prefKeyLastSeenVersion: '1.8.0',
      });
      await ChangelogService.saveLastSeenVersion('1.9.0');
      final lastSeen = await ChangelogService.loadLastSeenVersion();
      expect(lastSeen, '1.9.0');
    });

    // --- getEntriesForVersion ---

    test(
        'As a user, I expect to see version-specific entries for a known version',
        () {
      final entries = ChangelogService.getEntriesForVersion('1.8.0');
      expect(entries, appChangelog['1.8.0']);
      expect(entries, isNotEmpty);
    });

    test(
        'As a user, I expect an empty list when the version has no changelog entries',
        () {
      final entries = ChangelogService.getEntriesForVersion('99.0.0');
      expect(entries, isEmpty);
    });
  });
}
