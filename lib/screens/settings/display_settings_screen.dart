// display_settings_screen.dart: Calendar display preferences sub-page.
//
// Houses toggles for tag and note previews in the calendar entry list.
// Split from CalendarSettingsScreen since display preferences aren't
// intuitively grouped with the calendar start day setting.
//
// Cross-ref:
//   - Parent: screens/manage_items_screen.dart (navigates here)
//   - Preferences: services/preferences_service.dart (preview notifiers)

import 'package:flutter/material.dart';
import '../../constants/layout.dart';
import '../../services/preferences_service.dart';

/// Sub-page for calendar display preferences (tag/note preview toggles).
class DisplaySettingsScreen extends StatelessWidget {
  const DisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Display'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: PreferencesService.showTagPreviewNotifier,
                builder: (context, enabled, _) {
                  return SwitchListTile.adaptive(
                    title: const Text('Show tag preview'),
                    subtitle: const Text(
                        'Show tags below entries in the calendar list'),
                    value: enabled,
                    onChanged: PreferencesService.saveShowTagPreview,
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable: PreferencesService.showNotePreviewNotifier,
                builder: (context, enabled, _) {
                  return SwitchListTile.adaptive(
                    title: const Text('Show note preview'),
                    subtitle: const Text(
                        'Show notes below entries in the calendar list'),
                    value: enabled,
                    onChanged: PreferencesService.saveShowNotePreview,
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
