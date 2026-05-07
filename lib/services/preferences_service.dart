// preferences_service.dart: Centralized app-wide preference management.
//
// Owns all ValueNotifiers for user preferences and provides load/save methods
// backed by SharedPreferences. Extracted from app.dart to keep the app root
// widget thin and to make preferences testable in isolation.
//
// Pattern: all methods and notifiers are static. No instance state is needed
// since SharedPreferences is a global singleton internally. This matches the
// other stateless services (ChangelogService, ItemPreferencesService, etc.).
//
// Cross-ref:
//   - Preference keys & defaults: constants/defaults.dart
//   - Platform channel for system start day: services/platform_service.dart
//   - Consumed by: app.dart, main.dart, screens/calendar_screen.dart,
//     screens/manage_items_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import '../constants/defaults.dart';
import 'platform_service.dart';

/// Manages app-wide user preferences via SharedPreferences.
///
/// Each preference has a [ValueNotifier] that widgets can listen to for
/// reactive updates, plus a [load*] method (called at startup) and a [save*]
/// method (called when the user changes a setting).
class PreferencesService {
  // ---------------------------------------------------------------------------
  // Theme mode
  // ---------------------------------------------------------------------------

  /// Current theme mode. Updated by [loadThemeMode] and [saveThemeMode].
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier(ThemeMode.system);

  /// Loads the saved theme mode from SharedPreferences.
  static Future<void> loadThemeMode() async {
    _loadThemeModeFrom(await SharedPreferences.getInstance());
  }

  /// Internal: reads theme mode from a pre-acquired [prefs] instance.
  static void _loadThemeModeFrom(SharedPreferences prefs) {
    final stored = prefs.getString(prefKeyThemeMode) ?? defaultThemeMode;
    themeModeNotifier.value = _themeModeFromString(stored);
  }

  /// Saves the theme mode to SharedPreferences and updates the notifier.
  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKeyThemeMode, _themeModeToString(mode));
    themeModeNotifier.value = mode;
  }

  /// Converts a stored string ('light', 'dark', 'system') to [ThemeMode].
  static ThemeMode _themeModeFromString(String value) {
    if (value == 'light') return ThemeMode.light;
    if (value == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  /// Converts a [ThemeMode] to a string for SharedPreferences storage.
  static String _themeModeToString(ThemeMode mode) {
    if (mode == ThemeMode.light) return 'light';
    if (mode == ThemeMode.dark) return 'dark';
    return 'system';
  }

  // ---------------------------------------------------------------------------
  // Shake-to-feedback
  // ---------------------------------------------------------------------------

  /// Whether shake-to-feedback is enabled. Updated by [loadShakeToFeedback]
  /// and [saveShakeToFeedback].
  static final ValueNotifier<bool> shakeToFeedbackNotifier =
      ValueNotifier(true);

  /// Loads the shake-to-feedback preference.
  static Future<void> loadShakeToFeedback() async {
    _loadShakeToFeedbackFrom(await SharedPreferences.getInstance());
  }

  /// Internal: reads shake-to-feedback from a pre-acquired [prefs] instance.
  static void _loadShakeToFeedbackFrom(SharedPreferences prefs) {
    shakeToFeedbackNotifier.value =
        prefs.getBool(prefKeyShakeToFeedback) ?? defaultShakeToFeedbackEnabled;
  }

  /// Saves the shake-to-feedback preference and updates the notifier.
  static Future<void> saveShakeToFeedback(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyShakeToFeedback, enabled);
    shakeToFeedbackNotifier.value = enabled;
  }

  // ---------------------------------------------------------------------------
  // Note preview toggle
  // ---------------------------------------------------------------------------

  /// Whether note previews are shown in the calendar entry list.
  static final ValueNotifier<bool> showNotePreviewNotifier =
      ValueNotifier(true);

  /// Loads the note preview preference.
  static Future<void> loadShowNotePreview() async {
    _loadShowNotePreviewFrom(await SharedPreferences.getInstance());
  }

  /// Internal: reads note preview from a pre-acquired [prefs] instance.
  static void _loadShowNotePreviewFrom(SharedPreferences prefs) {
    showNotePreviewNotifier.value =
        prefs.getBool(prefKeyShowNotePreview) ?? defaultShowNotePreview;
  }

  /// Saves the note preview preference and updates the notifier.
  static Future<void> saveShowNotePreview(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyShowNotePreview, enabled);
    showNotePreviewNotifier.value = enabled;
  }

  // ---------------------------------------------------------------------------
  // Tag preview toggle
  // ---------------------------------------------------------------------------

  /// Whether tag previews are shown in the calendar entry list.
  static final ValueNotifier<bool> showTagPreviewNotifier = ValueNotifier(true);

  /// Loads the tag preview preference.
  static Future<void> loadShowTagPreview() async {
    _loadShowTagPreviewFrom(await SharedPreferences.getInstance());
  }

  /// Internal: reads tag preview from a pre-acquired [prefs] instance.
  static void _loadShowTagPreviewFrom(SharedPreferences prefs) {
    showTagPreviewNotifier.value =
        prefs.getBool(prefKeyShowTagPreview) ?? defaultShowTagPreview;
  }

  /// Saves the tag preview preference and updates the notifier.
  static Future<void> saveShowTagPreview(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyShowTagPreview, enabled);
    showTagPreviewNotifier.value = enabled;
  }

  // ---------------------------------------------------------------------------
  // Calendar start day
  // ---------------------------------------------------------------------------

  /// User's chosen calendar start day. Values: 'system', 'sunday', 'monday',
  /// 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'.
  static final ValueNotifier<String> calendarStartDayNotifier =
      ValueNotifier(defaultCalendarStartDay);

  /// Display labels for each calendar start day value.
  /// Used by ManageItemsScreen to show the current selection.
  static const Map<String, String> calendarStartDayLabels = {
    'system': 'System',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
  };

  /// Loads the calendar start day preference.
  static Future<void> loadCalendarStartDay() async {
    _loadCalendarStartDayFrom(await SharedPreferences.getInstance());
  }

  /// Internal: reads calendar start day from a pre-acquired [prefs] instance.
  static void _loadCalendarStartDayFrom(SharedPreferences prefs) {
    calendarStartDayNotifier.value =
        prefs.getString(prefKeyCalendarStartDay) ?? defaultCalendarStartDay;
  }

  /// Saves the calendar start day preference and updates the notifier.
  static Future<void> saveCalendarStartDay(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKeyCalendarStartDay, value);
    calendarStartDayNotifier.value = value;
  }

  // ---------------------------------------------------------------------------
  // System start day (read from OS, not user-configurable)
  // ---------------------------------------------------------------------------

  /// The OS-level first day of week, read via platform channel.
  /// Updated at startup and whenever the app resumes from the background
  /// (in case the user changed it in system settings).
  ///
  /// Cross-ref: services/platform_service.dart
  static final ValueNotifier<StartingDayOfWeek> systemStartDayNotifier =
      ValueNotifier(StartingDayOfWeek.sunday);

  /// Resolves the current start day preference to a [StartingDayOfWeek].
  ///
  /// For 'system', reads the OS preference from [systemStartDayNotifier].
  /// For explicit day strings ('monday', 'sunday', etc.), maps directly
  /// to the corresponding enum value.
  static StartingDayOfWeek resolveStartDay(String setting) {
    const dayMap = {
      'sunday': StartingDayOfWeek.sunday,
      'monday': StartingDayOfWeek.monday,
      'tuesday': StartingDayOfWeek.tuesday,
      'wednesday': StartingDayOfWeek.wednesday,
      'thursday': StartingDayOfWeek.thursday,
      'friday': StartingDayOfWeek.friday,
      'saturday': StartingDayOfWeek.saturday,
    };
    return dayMap[setting] ?? systemStartDayNotifier.value;
  }

  /// Fetches the system's first day of week from the OS and updates
  /// [systemStartDayNotifier]. Called at startup and on app resume.
  static Future<void> fetchSystemStartDay() async {
    systemStartDayNotifier.value =
        await PlatformService.getSystemFirstDayOfWeek();
  }

  // ---------------------------------------------------------------------------
  // App lock
  // ---------------------------------------------------------------------------

  /// Whether app lock is enabled. Updated by [loadAppLockEnabled] and
  /// [saveAppLockEnabled].
  static final ValueNotifier<bool> appLockEnabledNotifier =
      ValueNotifier(defaultAppLockEnabled);

  /// Grace period in seconds before re-authentication is required.
  /// 0 = immediately, 30 = 30 seconds, 60 = 1 minute.
  static final ValueNotifier<int> appLockGracePeriodNotifier =
      ValueNotifier(defaultAppLockGracePeriodSeconds);

  /// Display labels for each grace period value.
  static const Map<int, String> appLockGracePeriodLabels = {
    0: 'Immediately',
    60: '1 minute',
    300: '5 minutes',
    600: '10 minutes',
  };

  /// Loads the app lock enabled preference.
  static Future<void> loadAppLockEnabled() async {
    _loadAppLockEnabledFrom(await SharedPreferences.getInstance());
  }

  /// Internal: reads app lock enabled from a pre-acquired [prefs] instance.
  static void _loadAppLockEnabledFrom(SharedPreferences prefs) {
    appLockEnabledNotifier.value =
        prefs.getBool(prefKeyAppLockEnabled) ?? defaultAppLockEnabled;
  }

  /// Saves the app lock enabled preference and updates the notifier.
  static Future<void> saveAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyAppLockEnabled, enabled);
    appLockEnabledNotifier.value = enabled;
  }

  /// Loads the app lock grace period preference.
  static Future<void> loadAppLockGracePeriod() async {
    _loadAppLockGracePeriodFrom(await SharedPreferences.getInstance());
  }

  /// Internal: reads grace period from a pre-acquired [prefs] instance.
  static void _loadAppLockGracePeriodFrom(SharedPreferences prefs) {
    appLockGracePeriodNotifier.value =
        prefs.getInt(prefKeyAppLockGracePeriod) ??
            defaultAppLockGracePeriodSeconds;
  }

  /// Saves the app lock grace period preference and updates the notifier.
  static Future<void> saveAppLockGracePeriod(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefKeyAppLockGracePeriod, seconds);
    appLockGracePeriodNotifier.value = seconds;
  }

  /// Determines whether re-authentication is required after resuming.
  ///
  /// Returns true if app lock is enabled and the elapsed time since
  /// [lastPausedAt] exceeds [gracePeriodSeconds]. If [lastPausedAt] is null,
  /// returns false — cold start locking is handled by [MyApp.initState], and
  /// null here means no real background event has occurred yet (e.g., after
  /// a successful authentication clears the timestamp).
  static bool shouldLockOnResume({
    required bool appLockEnabled,
    required DateTime? lastPausedAt,
    required int gracePeriodSeconds,
  }) {
    if (!appLockEnabled) return false;
    if (lastPausedAt == null) return false;
    return DateTime.now().difference(lastPausedAt).inSeconds >=
        gracePeriodSeconds;
  }

  // ---------------------------------------------------------------------------
  // Achievements
  // ---------------------------------------------------------------------------

  /// Whether the achievement system is enabled. Updated by
  /// [loadAchievementsEnabled] and [saveAchievementsEnabled].
  static final ValueNotifier<bool> achievementsEnabledNotifier =
      ValueNotifier(defaultAchievementsEnabled);

  /// Loads the achievements enabled preference.
  static Future<void> loadAchievementsEnabled() async {
    _loadAchievementsEnabledFrom(await SharedPreferences.getInstance());
  }

  /// Internal: reads achievements enabled from a pre-acquired [prefs] instance.
  static void _loadAchievementsEnabledFrom(SharedPreferences prefs) {
    achievementsEnabledNotifier.value =
        prefs.getBool(prefKeyAchievementsEnabled) ?? defaultAchievementsEnabled;
  }

  /// Saves the achievements enabled preference and updates the notifier.
  static Future<void> saveAchievementsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyAchievementsEnabled, enabled);
    achievementsEnabledNotifier.value = enabled;
  }

  /// Whether achievement unlock notifications (toasts) are shown. Updated by
  /// [loadAchievementNotifications] and [saveAchievementNotifications].
  static final ValueNotifier<bool> achievementNotificationsNotifier =
      ValueNotifier(defaultAchievementNotificationsEnabled);

  /// Loads the achievement notifications preference.
  static Future<void> loadAchievementNotifications() async {
    _loadAchievementNotificationsFrom(await SharedPreferences.getInstance());
  }

  /// Internal: reads achievement notifications from a pre-acquired [prefs].
  static void _loadAchievementNotificationsFrom(SharedPreferences prefs) {
    achievementNotificationsNotifier.value =
        prefs.getBool(prefKeyAchievementNotifications) ??
            defaultAchievementNotificationsEnabled;
  }

  /// Saves the achievement notifications preference and updates the notifier.
  static Future<void> saveAchievementNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyAchievementNotifications, enabled);
    achievementNotificationsNotifier.value = enabled;
  }

  // ---------------------------------------------------------------------------
  // Onboarding walkthrough
  // ---------------------------------------------------------------------------

  /// Whether the user has seen the first-launch onboarding walkthrough.
  /// Updated by [loadHasSeenOnboarding] and [saveHasSeenOnboarding].
  static final ValueNotifier<bool> hasSeenOnboardingNotifier =
      ValueNotifier(defaultHasSeenOnboarding);

  /// Loads the onboarding-seen flag from SharedPreferences.
  static Future<void> loadHasSeenOnboarding() async {
    _loadHasSeenOnboardingFrom(await SharedPreferences.getInstance());
  }

  /// Internal: reads onboarding flag from a pre-acquired [prefs] instance.
  static void _loadHasSeenOnboardingFrom(SharedPreferences prefs) {
    hasSeenOnboardingNotifier.value =
        prefs.getBool(prefKeyHasSeenOnboarding) ?? defaultHasSeenOnboarding;
  }

  /// Saves the onboarding-seen flag and updates the notifier.
  static Future<void> saveHasSeenOnboarding(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyHasSeenOnboarding, seen);
    hasSeenOnboardingNotifier.value = seen;
  }

  // ---------------------------------------------------------------------------
  // Coach marks
  // ---------------------------------------------------------------------------

  /// Whether the user has seen the interactive coach marks on the calendar.
  /// Updated by [loadHasSeenCoachMarks] and [saveHasSeenCoachMarks].
  static final ValueNotifier<bool> hasSeenCoachMarksNotifier =
      ValueNotifier(defaultHasSeenCoachMarks);

  /// Loads the coach-marks-seen flag from SharedPreferences.
  static Future<void> loadHasSeenCoachMarks() async {
    _loadHasSeenCoachMarksFrom(await SharedPreferences.getInstance());
  }

  /// Internal: reads coach marks flag from a pre-acquired [prefs] instance.
  static void _loadHasSeenCoachMarksFrom(SharedPreferences prefs) {
    hasSeenCoachMarksNotifier.value =
        prefs.getBool(prefKeyHasSeenCoachMarks) ?? defaultHasSeenCoachMarks;
  }

  /// Saves the coach-marks-seen flag and updates the notifier.
  static Future<void> saveHasSeenCoachMarks(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyHasSeenCoachMarks, seen);
    hasSeenCoachMarksNotifier.value = seen;
  }

  // ---------------------------------------------------------------------------
  // Encryption migration failure
  // ---------------------------------------------------------------------------

  /// Whether the database encryption migration failed and needs user action.
  /// Set by _openConnection() in database.dart when PRAGMA rekey fails.
  static final ValueNotifier<bool> encryptionMigrationFailedNotifier =
      ValueNotifier(defaultEncryptionMigrationFailed);

  /// Loads the encryption migration failure flag.
  static Future<void> loadEncryptionMigrationFailed() async {
    _loadEncryptionMigrationFailedFrom(await SharedPreferences.getInstance());
  }

  /// Internal: reads the flag from a pre-acquired [prefs] instance.
  static void _loadEncryptionMigrationFailedFrom(SharedPreferences prefs) {
    encryptionMigrationFailedNotifier.value =
        prefs.getBool(prefKeyEncryptionMigrationFailed) ??
            defaultEncryptionMigrationFailed;
  }

  /// Saves the encryption migration failure flag and updates the notifier.
  static Future<void> saveEncryptionMigrationFailed(bool failed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyEncryptionMigrationFailed, failed);
    encryptionMigrationFailedNotifier.value = failed;
  }

  // ---------------------------------------------------------------------------
  // Bulk load (called once at startup from main.dart)
  // ---------------------------------------------------------------------------

  /// Loads all preferences from SharedPreferences into their notifiers.
  ///
  /// Acquires the SharedPreferences instance once and reads all keys from it,
  /// avoiding redundant async lookups. [fetchSystemStartDay] runs in parallel
  /// since it uses a platform channel, not SharedPreferences.
  ///
  /// Called from main.dart before [runApp] so the UI renders with the
  /// correct settings immediately (avoids flashes of wrong theme, etc.).
  static Future<void> loadAll() async {
    final results = await Future.wait([
      SharedPreferences.getInstance(),
      fetchSystemStartDay(),
    ]);
    final prefs = results[0] as SharedPreferences;

    _loadThemeModeFrom(prefs);
    _loadShakeToFeedbackFrom(prefs);
    _loadCalendarStartDayFrom(prefs);
    _loadShowNotePreviewFrom(prefs);
    _loadShowTagPreviewFrom(prefs);
    _loadAppLockEnabledFrom(prefs);
    _loadAppLockGracePeriodFrom(prefs);
    _loadAchievementsEnabledFrom(prefs);
    _loadAchievementNotificationsFrom(prefs);
    _loadHasSeenOnboardingFrom(prefs);
    _loadHasSeenCoachMarksFrom(prefs);
    _loadEncryptionMigrationFailedFrom(prefs);
  }

  // ---------------------------------------------------------------------------
  // Reset all settings to defaults
  // ---------------------------------------------------------------------------

  /// Clears all preference keys from SharedPreferences and resets notifiers
  /// to their default values. Also cancels any scheduled notifications.
  ///
  /// Does NOT touch the database — use [AppDatabase.clearAllData] for that.
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Reset all notifiers to defaults.
    themeModeNotifier.value = ThemeMode.system;
    shakeToFeedbackNotifier.value = defaultShakeToFeedbackEnabled;
    showNotePreviewNotifier.value = defaultShowNotePreview;
    showTagPreviewNotifier.value = defaultShowTagPreview;
    calendarStartDayNotifier.value = defaultCalendarStartDay;
    appLockEnabledNotifier.value = defaultAppLockEnabled;
    appLockGracePeriodNotifier.value = defaultAppLockGracePeriodSeconds;
    achievementsEnabledNotifier.value = defaultAchievementsEnabled;
    achievementNotificationsNotifier.value =
        defaultAchievementNotificationsEnabled;
    hasSeenOnboardingNotifier.value = defaultHasSeenOnboarding;
    hasSeenCoachMarksNotifier.value = defaultHasSeenCoachMarks;
    encryptionMigrationFailedNotifier.value = defaultEncryptionMigrationFailed;
  }
}
