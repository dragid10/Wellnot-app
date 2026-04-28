// manage_items_screen.dart: Main settings hub — navigation-only.
//
// Todoist-style flat list with accent-colored section headers and navigable
// tiles. Each tile shows the current value as a subtitle and taps through to
// a dedicated sub-page. No inline controls — all editing happens in sub-pages
// or confirmation dialogs.
//
// Cross-ref:
//   - Sub-pages: screens/settings/theme_settings_screen.dart,
//     screens/settings/calendar_settings_screen.dart,
//     screens/settings/security_settings_screen.dart,
//     screens/settings/reminders_settings_screen.dart,
//     screens/settings/export_data_screen.dart,
//     screens/settings/import_data_screen.dart,
//     screens/settings/about_screen.dart
//   - Item management: screens/manage_list_screen.dart
//   - Feedback: screens/feedback_screen.dart
//   - Clear & Reset: screens/settings/clear_reset_screen.dart
//   - Preferences: services/preferences_service.dart
//   - Changelog: services/changelog_service.dart, widgets/changelog_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/defaults.dart';
import '../constants/encryption_recovery.dart';
import '../constants/layout.dart';
import '../services/changelog_service.dart';
import '../services/encryption_recovery_service.dart';
import '../services/preferences_service.dart';
import '../widgets/changelog_dialog.dart';
import 'feedback_screen.dart';
import 'manage_list_screen.dart';
import 'settings/about_screen.dart';
import 'settings/calendar_settings_screen.dart';
import 'settings/clear_reset_screen.dart';
import 'settings/display_settings_screen.dart';
import 'settings/export_data_screen.dart';
import 'settings/import_data_screen.dart';
import 'settings/reminders_settings_screen.dart';
import 'settings/security_settings_screen.dart';
import 'settings/encryption_issue_screen.dart';
import 'settings/theme_settings_screen.dart';

/// Main settings screen — a navigation hub with accent-colored section headers.
///
/// No inline controls: every setting navigates to a sub-page or triggers a
/// dialog (Clear All Data, What's New). Subtitles show current preference
/// values so the user can see settings at a glance.
class ManageItemsScreen extends StatefulWidget {
  const ManageItemsScreen({super.key});

  @override
  State<ManageItemsScreen> createState() => _ManageItemsScreenState();
}

class _ManageItemsScreenState extends State<ManageItemsScreen> {
  bool _notificationsEnabled = defaultNotificationsEnabled;
  TimeOfDay _notificationTime = const TimeOfDay(
    hour: defaultNotificationHour,
    minute: defaultNotificationMinute,
  );
  String _versionString = '';

  @override
  void initState() {
    super.initState();
    _loadNotificationSummary();
    _loadVersion();
  }

  /// Loads notification state for the Reminders tile subtitle.
  Future<void> _loadNotificationSummary() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool(prefKeyNotificationsEnabled) ??
            defaultNotificationsEnabled;
        _notificationTime = TimeOfDay(
          hour:
              prefs.getInt(prefKeyNotificationHour) ?? defaultNotificationHour,
          minute: prefs.getInt(prefKeyNotificationMinute) ??
              defaultNotificationMinute,
        );
      });
    }
  }

  /// Loads the package version for the About tile subtitle.
  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _versionString = 'v${info.version}+${info.buildNumber}';
      });
    }
  }

  /// Formats a [TimeOfDay] as a user-friendly string (e.g., "9:00 AM").
  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  /// Navigates to [page] and refreshes notification summary on return.
  Future<void> _pushReminders(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RemindersSettingsScreen(),
      ),
    );
    _loadNotificationSummary();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final headerStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: accentColor,
          fontWeight: FontWeight.w600,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Encryption migration warning (conditional) ───────────
                if (EncryptionRecoveryService.hasEncryptionIssue)
                  Padding(
                    padding: const EdgeInsets.only(bottom: spacingSm),
                    child: Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: ListTile(
                        leading: Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        title: Text(
                          encryptionRecoveryBannerTitle,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                        ),
                        subtitle: Text(
                          encryptionRecoveryBannerSubtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EncryptionIssueScreen(),
                            ),
                          );
                          setState(() {});
                        },
                      ),
                    ),
                  ),

                // ── Items (no header) ────────────────────────────────────
                _SettingsTile(
                  icon: Icons.medical_services_outlined,
                  title: 'Manage Symptoms',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageListScreen(
                        title: 'Manage Symptoms',
                        itemType: 'symptom',
                      ),
                    ),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.label_outline,
                  title: 'Manage Tags',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageListScreen(
                        title: 'Manage Tags',
                        itemType: 'tag',
                      ),
                    ),
                  ),
                ),

                // ── Personalization ──────────────────────────────────────
                _SectionHeader(title: 'Personalization', style: headerStyle),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: PreferencesService.themeModeNotifier,
                  builder: (context, mode, _) {
                    return _SettingsTile(
                      icon: Icons.palette_outlined,
                      title: 'Theme',
                      subtitle: _themeModeLabel(mode),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ThemeSettingsScreen(),
                        ),
                      ),
                    );
                  },
                ),
                ValueListenableBuilder<String>(
                  valueListenable: PreferencesService.calendarStartDayNotifier,
                  builder: (context, startDay, _) {
                    return _SettingsTile(
                      icon: Icons.calendar_today_outlined,
                      title: 'Calendar',
                      subtitle:
                          'Week starts on ${PreferencesService.calendarStartDayLabels[startDay] ?? 'System'}',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CalendarSettingsScreen(),
                        ),
                      ),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.visibility_outlined,
                  title: 'Display',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DisplaySettingsScreen(),
                    ),
                  ),
                ),

                // ── Security ──────────────────────────────────────────────
                _SectionHeader(title: 'Security', style: headerStyle),
                ValueListenableBuilder<bool>(
                  valueListenable: PreferencesService.appLockEnabledNotifier,
                  builder: (context, enabled, _) {
                    return _SettingsTile(
                      icon: Icons.lock_outline,
                      title: 'App Lock',
                      subtitle: enabled ? 'On' : 'Off',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SecuritySettingsScreen(),
                        ),
                      ),
                    );
                  },
                ),

                // ── Notifications ────────────────────────────────────────
                _SectionHeader(title: 'Notifications', style: headerStyle),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Reminders',
                  subtitle: _notificationsEnabled
                      ? 'Daily at ${_formatTime(_notificationTime)}'
                      : 'Off',
                  onTap: () => _pushReminders(context),
                ),

                // ── Data ─────────────────────────────────────────────────
                _SectionHeader(title: 'Data', style: headerStyle),
                _SettingsTile(
                  icon: Icons.download_outlined,
                  title: 'Import Data',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ImportDataScreen(),
                    ),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.upload_outlined,
                  title: 'Export Data',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExportDataScreen(),
                    ),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.settings_backup_restore,
                  title: 'Clear & Reset',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClearResetScreen(),
                    ),
                  ),
                ),

                // ── Support ──────────────────────────────────────────────
                _SectionHeader(title: 'Support', style: headerStyle),
                _SettingsTile(
                  icon: Icons.feedback_outlined,
                  title: 'Send Feedback',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FeedbackScreen(),
                    ),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.new_releases_outlined,
                  title: "What's New",
                  onTap: () async {
                    final info = await PackageInfo.fromPlatform();
                    final currentVersion = info.version;
                    final entries =
                        ChangelogService.getEntriesForVersion(currentVersion);

                    if (entries.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'No changelog available for this version.'),
                          ),
                        );
                      }
                      return;
                    }

                    if (context.mounted) {
                      await showChangelogDialog(
                        context: context,
                        version: currentVersion,
                        entries: entries,
                      );
                    }
                  },
                ),
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: _versionString,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                    // Rebuild to pick up debug flag changes from About screen.
                    setState(() {});
                  },
                ),
                const SizedBox(height: spacingLg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Returns a user-friendly label for the given [ThemeMode].
  String _themeModeLabel(ThemeMode mode) {
    if (mode == ThemeMode.light) return 'Light';
    if (mode == ThemeMode.dark) return 'Dark';
    return 'System';
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

/// Accent-colored section header with a thin divider above it.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.style});

  final String title;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(top: spacingSm, bottom: spacingXs),
          child: Text(title, style: style),
        ),
      ],
    );
  }
}

/// A settings tile with optional icon, title, subtitle, and chevron.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.onTap,
    this.icon,
    this.subtitle,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null ? Icon(icon) : null,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
}
