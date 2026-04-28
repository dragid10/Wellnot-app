// security_settings_screen.dart: App lock and authentication settings.
//
// Houses the app lock toggle and grace period selector. When enabling app
// lock, performs a test authentication to ensure the device supports it and
// the user can actually authenticate — prevents locking themselves out.
//
// Cross-ref:
//   - Parent: screens/manage_items_screen.dart (navigates here)
//   - Preferences: services/preferences_service.dart (app lock notifiers)
//   - Lock screen: screens/lock_screen.dart (overlay shown when locked)
//   - Lock state: app.dart (manages lock/unlock lifecycle)

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../constants/layout.dart';
import '../../services/preferences_service.dart';

/// Sub-page for app lock settings (toggle + grace period).
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  /// Guards against double-tap while authentication is in progress.
  bool _isAuthenticating = false;

  /// Handles toggling app lock on or off.
  ///
  /// When enabling, checks device support and performs a test authentication
  /// before saving. When disabling, saves immediately.
  Future<void> _onAppLockToggled(bool enabled) async {
    if (_isAuthenticating) return;

    if (!enabled) {
      await PreferencesService.saveAppLockEnabled(false);
      return;
    }

    // Check device support before attempting authentication.
    final localAuth = LocalAuthentication();
    final isSupported = await localAuth.isDeviceSupported();
    if (!isSupported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your device does not support biometric or PIN authentication.',
            ),
          ),
        );
      }
      return;
    }

    // Test authentication — only enable if the user can actually authenticate.
    setState(() => _isAuthenticating = true);
    try {
      final authenticated = await localAuth.authenticate(
        localizedReason: 'Authenticate to enable App Lock',
        biometricOnly: false,
      );
      if (authenticated) {
        await PreferencesService.saveAppLockEnabled(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed. App Lock was not enabled.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: PreferencesService.appLockEnabledNotifier,
                builder: (context, enabled, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile.adaptive(
                        title: const Text('App Lock'),
                        subtitle: const Text(
                          'Require authentication to open Wellnot',
                        ),
                        value: enabled,
                        onChanged: _onAppLockToggled,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (enabled) ...[
                        const Divider(),
                        Text(
                          'Require authentication',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: spacingXs),
                        Text(
                          'How long after leaving the app before '
                          'authentication is required again.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: spacingSm),
                        ValueListenableBuilder<int>(
                          valueListenable:
                              PreferencesService.appLockGracePeriodNotifier,
                          builder: (context, gracePeriod, _) {
                            return Column(
                              children: PreferencesService
                                  .appLockGracePeriodLabels.entries
                                  .map((entry) {
                                final isSelected = entry.key == gracePeriod;
                                return ListTile(
                                  title: Text(entry.value),
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        )
                                      : null,
                                  onTap: () =>
                                      PreferencesService.saveAppLockGracePeriod(
                                          entry.key),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ],
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
