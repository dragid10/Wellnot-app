// constants/changelog.dart: Structured changelog data for in-app display
//
// Auto-generated — do not edit manually.
//
// Cross-ref:
//   - Consumed by: services/changelog_service.dart
//   - Consumed by: widgets/changelog_dialog.dart

/// The type of a changelog entry, used to pick a leading icon in the UI.
enum ChangelogEntryType {
  /// A new user-facing feature.
  feature,

  /// A bug fix.
  fix,

  /// An improvement to existing functionality.
  improvement,
}

/// Which platform a changelog entry applies to.
///
/// Entries with [all] appear in the general section (no header).
/// Entries with [android] or [ios] appear under their own section header.
enum ChangelogPlatform {
  /// Applies to both Android and iOS.
  all,

  /// Android-only change.
  android,

  /// iOS-only change.
  ios,
}

/// A single changelog entry for display in the "What's New" modal.
class ChangelogEntry {
  /// Plain-language description of the change.
  final String description;

  /// Category of the change (feature, fix, improvement).
  final ChangelogEntryType type;

  /// Which platform this change applies to. Defaults to [ChangelogPlatform.all].
  final ChangelogPlatform platform;

  const ChangelogEntry({
    required this.description,
    required this.type,
    this.platform = ChangelogPlatform.all,
  });
}

/// Structured changelog content keyed by semantic version string.
///
/// Only include user-facing changes. No CI, tests, or internal refactors.
/// Use [ChangelogPlatform.android] or [ChangelogPlatform.ios] for
/// platform-specific entries — they are grouped under section headers.
/// Keep descriptions short and user-centric.
const Map<String, List<ChangelogEntry>> appChangelog = {
  '1.11.2': [
    ChangelogEntry(
      description:
          'Fixed rare crash on Android when the OS restarts the Quick Add notification service.',
      type: ChangelogEntryType.fix,
      platform: ChangelogPlatform.android,
    ),
  ],
  '1.11.1': [
    ChangelogEntry(
      description:
          'Database is now reliably excluded from iCloud backup on iOS.',
      type: ChangelogEntryType.fix,
      platform: ChangelogPlatform.ios,
    ),
  ],
  '1.11.0': [
    ChangelogEntry(
      description:
          'Your data is now encrypted on your device for added security',
      type: ChangelogEntryType.feature,
    ),
    ChangelogEntry(
      description:
          'Added protection for your data if encryption setup needs a retry',
      type: ChangelogEntryType.feature,
    ),
  ],
  '1.10.1': [
    ChangelogEntry(
      description: 'App lock — protect your data with biometrics or device PIN',
      type: ChangelogEntryType.feature,
    ),
    ChangelogEntry(
      description:
          'Welcome walkthrough — quick intro to features on first launch',
      type: ChangelogEntryType.feature,
    ),
    ChangelogEntry(
      description:
          'Import data from a previously exported backup file to restore your entries',
      type: ChangelogEntryType.feature,
    ),
    ChangelogEntry(
      description: 'Calendar row height adapts to screen size',
      type: ChangelogEntryType.fix,
    ),
    ChangelogEntry(
      description:
          'Reduced shake-to-feedback sensitivity for fewer accidental triggers',
      type: ChangelogEntryType.fix,
    ),
    ChangelogEntry(
      description: '"What\'s New" dialog fits better on tablets',
      type: ChangelogEntryType.fix,
    ),
    ChangelogEntry(
      description:
          'Database excluded from iCloud and Android cloud backups to keep your data on-device',
      type: ChangelogEntryType.fix,
    ),
  ],
  '1.10.0': [
    ChangelogEntry(
      description:
          'Welcome walkthrough — quick intro to features on first launch',
      type: ChangelogEntryType.feature,
    ),
    ChangelogEntry(
      description: 'App lock — protect your data with biometrics or device PIN',
      type: ChangelogEntryType.feature,
    ),
    ChangelogEntry(
      description: 'Calendar row height adapts to screen size',
      type: ChangelogEntryType.fix,
    ),
    ChangelogEntry(
      description:
          'Reduced shake-to-feedback sensitivity for fewer accidental triggers',
      type: ChangelogEntryType.fix,
    ),
    ChangelogEntry(
      description:
          'Database excluded from iCloud and Android cloud backups to keep your data on-device',
      type: ChangelogEntryType.fix,
    ),
    ChangelogEntry(
      description: '"What\'s New" dialog fits better on tablets',
      type: ChangelogEntryType.fix,
    ),
  ],
  '1.9.0': [
    ChangelogEntry(
      description:
          'Date range summary — see mood, symptom, and tag patterns at a glance',
      type: ChangelogEntryType.feature,
    ),
    ChangelogEntry(
      description:
          'Home screen widget with today\'s entries and quick-add button',
      type: ChangelogEntryType.feature,
    ),
    ChangelogEntry(
      description: 'Export your data to CSV or JSON',
      type: ChangelogEntryType.feature,
    ),
    ChangelogEntry(
      description: '"What\'s New" dialog on app updates',
      type: ChangelogEntryType.feature,
    ),
    ChangelogEntry(
      description: 'Open Source Licenses in Settings > About',
      type: ChangelogEntryType.feature,
    ),
    ChangelogEntry(
      description: 'Added 🙃 to default mood emojis',
      type: ChangelogEntryType.feature,
    ),
    ChangelogEntry(
      description: 'Redesigned Settings with cleaner navigation',
      type: ChangelogEntryType.improvement,
    ),
    ChangelogEntry(
      description: 'Time picker not opening when already selected fixed',
      type: ChangelogEntryType.fix,
    ),
    ChangelogEntry(
      description: 'Picker button clipping fixed',
      type: ChangelogEntryType.fix,
      platform: ChangelogPlatform.ios,
    ),
    ChangelogEntry(
      description: 'Calendar start day now reads from system settings',
      type: ChangelogEntryType.fix,
      platform: ChangelogPlatform.ios,
    ),
  ],
  '1.8.0': [
    ChangelogEntry(
      description: 'Pin your favorite symptoms and tags to the top',
      type: ChangelogEntryType.feature,
    ),
    ChangelogEntry(
      description: 'Hide default items you don\'t use',
      type: ChangelogEntryType.feature,
    ),
    ChangelogEntry(
      description: 'Previous severity shown when re-logging a symptom',
      type: ChangelogEntryType.improvement,
    ),
    ChangelogEntry(
      description: 'Symptom and tag names are now auto-capitalized',
      type: ChangelogEntryType.improvement,
    ),
    ChangelogEntry(
      description: 'Calendar day-of-week labels being cut off fixed',
      type: ChangelogEntryType.fix,
    ),
  ],
  '1.7.0': [
    ChangelogEntry(
      description: 'Today button to jump back to the current date',
      type: ChangelogEntryType.feature,
    ),
    ChangelogEntry(
      description: 'Choose your calendar start day (Sunday, Monday, or System)',
      type: ChangelogEntryType.feature,
    ),
    ChangelogEntry(
      description: 'Tag preview in the calendar entry list',
      type: ChangelogEntryType.feature,
    ),
    ChangelogEntry(
      description: 'Send Feedback now goes directly to email',
      type: ChangelogEntryType.improvement,
    ),
  ],
  '1.6.0': [
    ChangelogEntry(
      description: 'Native date and time pickers',
      type: ChangelogEntryType.feature,
      platform: ChangelogPlatform.ios,
    ),
    ChangelogEntry(
      description: 'Native segmented controls in Settings',
      type: ChangelogEntryType.improvement,
      platform: ChangelogPlatform.ios,
    ),
  ],
  '1.5.0': [
    ChangelogEntry(
      description: 'Send Feedback from Settings',
      type: ChangelogEntryType.feature,
    ),
    ChangelogEntry(
      description: 'Shake your device to quickly report a bug',
      type: ChangelogEntryType.feature,
    ),
  ],
};
