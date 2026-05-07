// constants/defaults.dart: Centralized default symptom, tag, and mood lists
//
// These defaults are the union of items that were previously hardcoded in
// entry_screen.dart and manage_items_screen.dart. Moving them here avoids
// duplication and makes them easy to update.
//
// Cross-ref:
//   - Consumed by screens/entry_screen.dart (symptom/tag chip lists)
//   - Consumed by screens/manage_items_screen.dart (default items display)
//   - Also available via SymptomEntryModel static members in models/symptom_models.dart

/// Default symptom names available in the app (sorted alphabetically).
const List<String> defaultSymptoms = [
  'Dizziness',
  'Dry mouth',
  'Fatigue',
  'Fever',
  'Headache',
  'Nausea',
];

/// Default tag names available in the app (sorted alphabetically).
const List<String> defaultTags = [
  'After Meal',
  'After Wakeup',
  'At Home',
  'At Work',
  'Before Meal',
  'Before Sleep',
  'Dehydrated',
  'Dietary Restriction',
  'During Meal',
  'Exercise',
  'High Stress',
  'Hormonal',
  'Poor Sleep',
  'Rainy',
  'Skipped Meal',
  'Sunny',
  'Took Medication',
  'Travel',
  'With Drink',
];

/// Maximum character length for symptom and tag names.
///
/// Enforced in the add symptom/tag dialog (entry_screen.dart) and during
/// JSON import validation (import_service.dart).
const int maxItemNameLength = 120;

/// Mood emojis available for selection.
const List<String> defaultMoods = [
  '😊',
  '😢',
  '😠',
  '😩',
  '😐',
  '🤢',
  '😴',
  '🤔',
  '🤒',
  '😮',
  '😰',
  '🤕',
  '🙃',
  '😬',
  '😮‍💨',
  '🫩',
  '🤧',
];

// ---------------------------------------------------------------------------
// Notification settings defaults & SharedPreferences keys
// ---------------------------------------------------------------------------

/// Default hour (24h) for the daily reminder notification.
const int defaultNotificationHour = 9;

/// Default minute for the daily reminder notification.
const int defaultNotificationMinute = 0;

/// Whether notifications are enabled by default on first launch.
/// Disabled so the app doesn't try to schedule before permissions are granted.
const bool defaultNotificationsEnabled = false;

/// SharedPreferences key for the notifications-enabled toggle.
const String prefKeyNotificationsEnabled = 'notifications_enabled';

/// SharedPreferences key for the notification hour (0–23).
const String prefKeyNotificationHour = 'notification_hour';

/// SharedPreferences key for the notification minute (0–59).
const String prefKeyNotificationMinute = 'notification_minute';

/// Whether the persistent (ongoing) notification is enabled by default.
const bool defaultPersistentNotificationEnabled = false;

/// SharedPreferences key for the persistent notification toggle.
const String prefKeyPersistentNotification = 'persistent_notification_enabled';

// ---------------------------------------------------------------------------
// Appearance settings
// ---------------------------------------------------------------------------

/// SharedPreferences key for the theme mode setting.
/// Values: 'system', 'light', 'dark'.
const String prefKeyThemeMode = 'theme_mode';

/// Default theme mode on first launch — follows the system setting.
const String defaultThemeMode = 'system';

/// Calendar start day preference.
/// Values: 'system', 'saturday', 'sunday', 'monday', 'tuesday',
/// 'wednesday', 'thursday', 'friday'.
const String defaultCalendarStartDay = 'system';

/// SharedPreferences key for the calendar start day setting.
const String prefKeyCalendarStartDay = 'calendar_start_day';

/// Whether to show note previews in the calendar entry list.
const bool defaultShowNotePreview = true;

/// SharedPreferences key for the note preview toggle.
const String prefKeyShowNotePreview = 'show_note_preview';

/// Whether to show tag previews in the calendar entry list.
const bool defaultShowTagPreview = true;

/// SharedPreferences key for the tag preview toggle.
const String prefKeyShowTagPreview = 'show_tag_preview';

/// Whether shake-to-feedback is enabled by default.
const bool defaultShakeToFeedbackEnabled = false;

/// SharedPreferences key for the shake-to-feedback toggle.
const String prefKeyShakeToFeedback = 'shake_to_feedback_enabled';

// ---------------------------------------------------------------------------
// App lock (security)
// ---------------------------------------------------------------------------

/// Whether app lock (biometric/PIN authentication) is enabled.
const bool defaultAppLockEnabled = false;

/// SharedPreferences key for the app lock toggle.
const String prefKeyAppLockEnabled = 'app_lock_enabled';

/// Default grace period in seconds before re-authentication is required
/// after the app is backgrounded. 0 = immediately.
const int defaultAppLockGracePeriodSeconds = 0;

/// SharedPreferences key for the app lock grace period (in seconds).
const String prefKeyAppLockGracePeriod = 'app_lock_grace_period';

// ---------------------------------------------------------------------------
// Onboarding walkthrough
// ---------------------------------------------------------------------------

/// Whether the user has completed the first-launch onboarding walkthrough.
const bool defaultHasSeenOnboarding = false;

/// SharedPreferences key for the onboarding-seen flag.
const String prefKeyHasSeenOnboarding = 'has_seen_onboarding';

/// Whether the user has seen the interactive coach marks on the calendar screen.
const bool defaultHasSeenCoachMarks = false;

/// SharedPreferences key for the coach-marks-seen flag.
const String prefKeyHasSeenCoachMarks = 'has_seen_coach_marks';

// ---------------------------------------------------------------------------
// Encryption migration recovery
// ---------------------------------------------------------------------------

/// Whether the database encryption migration failed and needs user attention.
const bool defaultEncryptionMigrationFailed = false;

/// SharedPreferences key for the encryption migration failure flag.
const String prefKeyEncryptionMigrationFailed = 'encryption_migration_failed';

// ---------------------------------------------------------------------------
// Changelog modal
// ---------------------------------------------------------------------------

/// SharedPreferences key for the last app version the user has seen
/// the changelog for. Compared against the current version on each launch
/// to decide whether to show the "What's New" modal.
const String prefKeyLastSeenVersion = 'last_seen_version';

// ---------------------------------------------------------------------------
// Pin & hide preferences
// ---------------------------------------------------------------------------

/// SharedPreferences key for pinned symptom names (JSON string list).
const String prefKeyPinnedSymptoms = 'pinned_symptoms';

/// SharedPreferences key for pinned tag names (JSON string list).
const String prefKeyPinnedTags = 'pinned_tags';

/// SharedPreferences key for hidden default symptom names (JSON string list).
const String prefKeyHiddenSymptoms = 'hidden_symptoms';

/// SharedPreferences key for hidden default tag names (JSON string list).
const String prefKeyHiddenTags = 'hidden_tags';

// ---------------------------------------------------------------------------
// Achievement system
// ---------------------------------------------------------------------------

/// SharedPreferences key for the one-time retroactive achievement scan flag.
/// Set to true after the scan runs, so it only executes once per install.
const String prefKeyAchievementsScanned = 'achievements_scanned';

/// Whether the achievement system is enabled by default.
const bool defaultAchievementsEnabled = true;

/// SharedPreferences key for the achievements enabled toggle.
const String prefKeyAchievementsEnabled = 'achievements_enabled';

/// Whether achievement unlock notifications (toasts) are enabled by default.
const bool defaultAchievementNotificationsEnabled = true;

/// SharedPreferences key for the achievement notifications toggle.
const String prefKeyAchievementNotifications =
    'achievement_notifications_enabled';

// ---------------------------------------------------------------------------
// Tooltip text
// ---------------------------------------------------------------------------

/// Tooltip text explaining what tags are and how to use them.
const String tagTooltipText =
    'Tags help you track context around your symptoms \u2014 things like '
    'activities, food, weather, sleep quality, or anything else that might '
    'be relevant. Use them to spot patterns over time.';
