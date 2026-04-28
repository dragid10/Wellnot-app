// reminders_settings_screen.dart: Notification settings sub-page.
//
// Self-contained screen that manages notification state (daily reminder
// toggle, time picker, persistent notification). Extracted from the old
// NotificationsSettingsSection widget as part of the settings redesign.
//
// Cross-ref:
//   - Parent: screens/manage_items_screen.dart (navigates here)
//   - Notification service: services/notification_service.dart
//   - Constants: constants/defaults.dart (default values)
//   - Adaptive pickers: widgets/adaptive_pickers.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/defaults.dart';
import '../../constants/layout.dart';
import '../../services/notification_service.dart';
import '../../widgets/adaptive_pickers.dart';

/// Sub-page for daily reminder and persistent notification controls.
///
/// Manages its own state — loads notification settings from SharedPreferences
/// on first build, and saves changes back when the user interacts with toggles
/// or the time picker.
class RemindersSettingsScreen extends StatefulWidget {
  const RemindersSettingsScreen({super.key});

  @override
  State<RemindersSettingsScreen> createState() =>
      _RemindersSettingsScreenState();
}

class _RemindersSettingsScreenState extends State<RemindersSettingsScreen> {
  bool _notificationsEnabled = defaultNotificationsEnabled;
  TimeOfDay _notificationTime = const TimeOfDay(
    hour: defaultNotificationHour,
    minute: defaultNotificationMinute,
  );
  bool _persistentNotificationEnabled = defaultPersistentNotificationEnabled;
  final NotificationService _notificationService = NotificationService();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Loads notification settings from SharedPreferences and updates state.
  Future<void> _loadSettings() async {
    try {
      final settings = await _notificationService.loadSettings();
      final persistentEnabled =
          await _notificationService.loadPersistentEnabled();
      if (mounted) {
        setState(() {
          _notificationsEnabled = settings.enabled;
          _notificationTime = TimeOfDay(
            hour: settings.hour,
            minute: settings.minute,
          );
          _persistentNotificationEnabled = persistentEnabled;
          _loaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notification settings: $e')),
        );
      }
    }
  }

  /// Handles the daily reminder toggle switch.
  Future<void> _onNotificationToggle(bool enabled) async {
    try {
      if (enabled) {
        final granted = await _notificationService.requestPermissions();
        if (!granted) return;
      }
      setState(() {
        _notificationsEnabled = enabled;
      });
      await _notificationService.saveSettings(
        enabled: enabled,
        hour: _notificationTime.hour,
        minute: _notificationTime.minute,
      );
      await _notificationService.applySettings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update notification setting: $e')),
        );
      }
    }
  }

  /// Opens a time picker and updates the notification schedule.
  Future<void> _onNotificationTimeChange() async {
    final picked = await showAdaptiveTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (picked == null || !mounted) return;

    try {
      setState(() {
        _notificationTime = picked;
      });
      await _notificationService.saveSettings(
        enabled: _notificationsEnabled,
        hour: picked.hour,
        minute: picked.minute,
      );
      await _notificationService.applySettings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update reminder time: $e')),
        );
      }
    }
  }

  /// Handles the persistent (quick add) notification toggle.
  Future<void> _onPersistentToggle(bool enabled) async {
    try {
      if (enabled) {
        final granted = await _notificationService.requestPermissions();
        if (!granted) return;
      }
      setState(() {
        _persistentNotificationEnabled = enabled;
      });
      await _notificationService.savePersistentEnabled(enabled);
      await _notificationService.applyPersistentNotification();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update persistent notification: $e')),
        );
      }
    }
  }

  /// Formats a [TimeOfDay] as a user-friendly string (e.g., "9:00 AM").
  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
      ),
      body: SafeArea(
        top: false,
        child: !_loaded
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.all(spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile.adaptive(
                      title: const Text('Daily Reminder'),
                      subtitle: const Text('Get reminded to log your symptoms'),
                      value: _notificationsEnabled,
                      onChanged: _onNotificationToggle,
                      contentPadding: EdgeInsets.zero,
                    ),
                    ListTile(
                      title: const Text('Reminder Time'),
                      trailing: Text(
                        _formatTime(_notificationTime),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: _notificationsEnabled
                                  ? null
                                  : Theme.of(context).disabledColor,
                            ),
                      ),
                      enabled: _notificationsEnabled,
                      onTap: _notificationsEnabled
                          ? _onNotificationTimeChange
                          : null,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    SwitchListTile.adaptive(
                      title: const Text('Quick Add Notification'),
                      subtitle: const Text(
                          'Show a persistent notification to quickly log symptoms'),
                      value: _persistentNotificationEnabled,
                      onChanged: _onPersistentToggle,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
