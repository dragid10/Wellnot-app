// services/changelog_service.dart: Version-check logic for the changelog modal
//
// Compares the current app version against the last-seen version stored in
// SharedPreferences to determine whether the "What's New" modal should appear.
//
// Cross-ref:
//   - Constants: constants/defaults.dart (prefKeyLastSeenVersion)
//   - Changelog data: constants/changelog.dart (appChangelog)
//   - Consumed by: screens/calendar_screen.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../constants/changelog.dart';
import '../constants/defaults.dart';

/// Service for managing the in-app changelog modal display.
///
/// Uses SharedPreferences to persist the last-seen version. On each launch,
/// the current version is compared to determine whether to show the modal.
class ChangelogService {
  /// Loads the last-seen version from SharedPreferences.
  ///
  /// Returns `null` on first launch (no version stored yet).
  static Future<String?> loadLastSeenVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(prefKeyLastSeenVersion);
  }

  /// Saves the current version as the last-seen version.
  ///
  /// Called after the user dismisses the changelog modal.
  static Future<void> saveLastSeenVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKeyLastSeenVersion, version);
  }

  /// Returns `true` if the changelog modal should be shown.
  ///
  /// Shows when no last-seen version exists (first launch) or when the
  /// last-seen version differs from [currentVersion] (app update).
  static Future<bool> shouldShowChangelog(String currentVersion) async {
    final lastSeen = await loadLastSeenVersion();
    return lastSeen == null || lastSeen != currentVersion;
  }

  /// Returns the changelog entries to display for [version].
  ///
  /// Returns the entries from [appChangelog] for the given version,
  /// or an empty list if the version has no changelog entries.
  static List<ChangelogEntry> getEntriesForVersion(String version) {
    return appChangelog[version] ?? [];
  }
}
