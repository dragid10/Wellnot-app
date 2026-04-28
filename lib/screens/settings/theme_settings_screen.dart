// theme_settings_screen.dart: Theme mode sub-page.
//
// Displays a segmented control for choosing Light/System/Dark theme.
// Extracted from the old Appearance section in ManageItemsScreen as part
// of the settings redesign.
//
// Cross-ref:
//   - Parent: screens/manage_items_screen.dart (navigates here)
//   - Preferences: services/preferences_service.dart (theme mode notifier)
//   - Segmented control: widgets/adaptive_segmented_control.dart

import 'package:flutter/material.dart';
import '../../constants/layout.dart';
import '../../services/preferences_service.dart';
import '../../widgets/adaptive_segmented_control.dart';

/// Sub-page for selecting the app's theme mode (Light, System, or Dark).
class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(spacingLg),
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: PreferencesService.themeModeNotifier,
            builder: (context, currentMode, _) {
              return AdaptiveSegmentedControl<ThemeMode>(
                segments: const {
                  ThemeMode.light: 'Light',
                  ThemeMode.system: 'System',
                  ThemeMode.dark: 'Dark',
                },
                icons: const {
                  ThemeMode.light: Icons.light_mode,
                  ThemeMode.system: Icons.settings_brightness,
                  ThemeMode.dark: Icons.dark_mode,
                },
                selected: currentMode,
                onChanged: PreferencesService.saveThemeMode,
              );
            },
          ),
        ),
      ),
    );
  }
}
