// clear_reset_screen.dart: Data clearing and settings reset sub-page.
//
// Provides three destructive actions with two-step confirmation dialogs:
//   1. Clear logged data (entries, custom symptoms/tags from database)
//   2. Reset app settings (SharedPreferences back to defaults)
//   3. Clear everything (both database and settings)
//
// Cross-ref:
//   - Parent: screens/manage_items_screen.dart (navigates here)
//   - Database: services/database.dart (clearAllData)
//   - Preferences: services/preferences_service.dart (resetAll)
//   - Notification service: services/notification_service.dart (applySettings)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/layout.dart';
import '../../services/database.dart';
import '../../services/notification_service.dart';
import '../../services/preferences_service.dart';

/// Sub-page with options to clear logged data, reset settings, or both.
class ClearResetScreen extends StatefulWidget {
  const ClearResetScreen({super.key});

  @override
  State<ClearResetScreen> createState() => _ClearResetScreenState();
}

class _ClearResetScreenState extends State<ClearResetScreen> {
  late AppDatabase _database;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _database = context.read<AppDatabase>();
      _initialized = true;
    }
  }

  /// Shows a two-step confirmation dialog. Returns true only if the user
  /// confirms both steps.
  Future<bool> _confirmTwice({
    required String title,
    required String description,
    required String finalTitle,
    required String finalDescription,
  }) async {
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Continue',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (firstConfirm != true || !mounted) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(finalTitle),
        content: Text(finalDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("NO, I'M SCARED"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'YES, PLEASE DELETE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    return confirmed == true && mounted;
  }

  /// Clears all logged data from the database.
  Future<void> _clearData() async {
    final confirmed = await _confirmTwice(
      title: 'Clear Logged Data?',
      description: 'This will permanently delete all entries, custom symptoms, '
          'and custom tags. Your app settings will not be affected.',
      finalTitle: 'Are you ABSOLUTELY sure?',
      finalDescription: 'Are you ABSOLUTELY sure you want to delete all '
          "logged data? There's no way to recover it at all!!",
    );
    if (!confirmed) return;

    try {
      await _database.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All logged data has been cleared.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear data: $e')),
        );
      }
    }
  }

  /// Resets all app settings to defaults.
  Future<void> _resetSettings() async {
    final confirmed = await _confirmTwice(
      title: 'Reset All Settings?',
      description: 'This will reset theme, calendar, display, notification, '
          'and pin/hide preferences back to defaults. Your logged data will '
          'not be affected.',
      finalTitle: 'Are you ABSOLUTELY sure?',
      finalDescription: 'Are you ABSOLUTELY sure you want to reset all '
          'settings to their defaults?',
    );
    if (!confirmed) return;

    try {
      await PreferencesService.resetAll();
      // Cancel any scheduled notifications since settings were reset.
      final notificationService = NotificationService();
      await notificationService.applySettings();
      await notificationService.applyPersistentNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('All settings have been reset to defaults.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reset settings: $e')),
        );
      }
    }
  }

  /// Clears all data AND resets all settings.
  Future<void> _clearEverything() async {
    final confirmed = await _confirmTwice(
      title: 'Clear Everything?',
      description: 'This will permanently delete all entries, custom symptoms, '
          'custom tags, AND reset all app settings to defaults. '
          'This action cannot be undone.',
      finalTitle: 'Are you ABSOLUTELY sure?',
      finalDescription: 'Are you ABSOLUTELY sure you want to delete ALL data '
          "and reset ALL settings? There's no way to recover any of it!!",
    );
    if (!confirmed) return;

    try {
      await _database.clearAllData();
      await PreferencesService.resetAll();
      final notificationService = NotificationService();
      await notificationService.applySettings();
      await notificationService.applyPersistentNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('All data and settings have been cleared.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clear & Reset'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Clear Logged Data',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle:
                    const Text('Delete all entries, custom symptoms, and tags'),
                contentPadding: EdgeInsets.zero,
                onTap: _clearData,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings_backup_restore,
                    color: Colors.red),
                title: const Text(
                  'Reset Settings',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: const Text(
                    'Reset theme, calendar, notifications, and all preferences to defaults'),
                contentPadding: EdgeInsets.zero,
                onTap: _resetSettings,
              ),
              const Divider(),
              ListTile(
                leading:
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                title: const Text(
                  'Clear Everything',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: const Text('Delete all data and reset all settings'),
                contentPadding: EdgeInsets.zero,
                onTap: _clearEverything,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
