// lock_screen.dart: Full-screen authentication overlay for app lock.
//
// Displayed as a Stack layer above MaterialApp in app.dart when the app
// is locked. Uses local_auth to authenticate via device biometrics or PIN.
// This is NOT a Navigator route — it's an overlay that cannot be popped
// or circumvented.
//
// Cross-ref:
//   - Controlled by: app.dart (visibility based on lock state)
//   - Preferences: services/preferences_service.dart (app lock notifiers)
//   - Settings: screens/settings/security_settings_screen.dart

import 'package:flutter/material.dart';
import '../constants/layout.dart';

/// Full-screen lock overlay shown when the app requires authentication.
///
/// Calls [onUnlockRequested] when the user taps the Unlock button.
/// Displays [errorMessage] when authentication fails.
class LockScreen extends StatelessWidget {
  final VoidCallback onUnlockRequested;
  final String? errorMessage;

  const LockScreen({
    super.key,
    required this.onUnlockRequested,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: spacingLg),
                Text(
                  'Wellnot is Locked',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: spacingSm),
                Text(
                  'Authenticate to access your data',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: spacingXl),
                FilledButton.icon(
                  onPressed: onUnlockRequested,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Unlock'),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: spacingMd),
                  Text(
                    errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
