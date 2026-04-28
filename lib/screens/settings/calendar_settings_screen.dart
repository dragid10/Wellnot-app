// calendar_settings_screen.dart: Calendar preferences sub-page.
//
// Houses the week start day selector. Extracted from the old Appearance
// section in ManageItemsScreen as part of the settings redesign.
//
// Cross-ref:
//   - Parent: screens/manage_items_screen.dart (navigates here)
//   - Preferences: services/preferences_service.dart (calendar notifiers)
//   - Display toggles: screens/settings/display_settings_screen.dart

import 'package:flutter/material.dart';
import '../../constants/layout.dart';
import '../../services/preferences_service.dart';

/// Sub-page for the calendar week start day preference.
class CalendarSettingsScreen extends StatelessWidget {
  const CalendarSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(spacingLg),
          child: ValueListenableBuilder<String>(
            valueListenable: PreferencesService.calendarStartDayNotifier,
            builder: (context, currentStartDay, _) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Week starts on'),
                subtitle: Text(
                  PreferencesService.calendarStartDayLabels[currentStartDay] ??
                      'System',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showStartDayDialog(context, currentStartDay),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Shows a dialog with radio options for picking the calendar start day.
  void _showStartDayDialog(BuildContext context, String currentValue) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Week starts on'),
          content: SingleChildScrollView(
            child: RadioGroup<String>(
              groupValue: currentValue,
              onChanged: (value) {
                if (value != null) {
                  PreferencesService.saveCalendarStartDay(value);
                }
                Navigator.of(dialogContext).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: PreferencesService.calendarStartDayLabels.entries
                    .map((entry) {
                  return RadioListTile<String>(
                    title: Text(entry.value),
                    value: entry.key,
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
