// privacy_policy_screen.dart: In-app privacy policy.
//
// Renders the privacy policy as styled text. No network calls needed -
// the policy is bundled with the app.
//
// Cross-ref:
//   - Parent: screens/manage_items_screen.dart (navigates here)
//   - Layout constants: constants/layout.dart

import 'package:flutter/material.dart';
import '../../constants/layout.dart';

/// Displays the Wellnot privacy policy as scrollable styled text.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String _lastUpdated = 'May 1, 2026';

  @override
  Widget build(BuildContext context) {
    final headingStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    final captionStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Last updated: $_lastUpdated', style: captionStyle),
              const SizedBox(height: spacingLg),
              Text(
                'Wellnot is designed with your privacy as its foundation. '
                'This policy explains how the app handles your data.',
                style: bodyStyle,
              ),
              const SizedBox(height: spacingLg),
              Text('Data Storage', style: headingStyle),
              const SizedBox(height: spacingSm),
              Text(
                'All data you enter into Wellnot - including symptoms, moods, '
                'tags, notes, and settings - is stored exclusively on your '
                'device. Wellnot does not have a server, cloud service, or any '
                'backend infrastructure. Your data never leaves your device '
                'unless you explicitly choose to export it.',
                style: bodyStyle,
              ),
              const SizedBox(height: spacingLg),
              Text('Encryption', style: headingStyle),
              const SizedBox(height: spacingSm),
              Text(
                'Your health data is encrypted at rest using '
                'SQLite3MultipleCiphers. The encryption key is generated '
                'randomly on your device and stored securely in the Android '
                'Keystore or iOS Keychain. Wellnot does not have access to '
                'your encryption key on any other device or system.',
                style: bodyStyle,
              ),
              const SizedBox(height: spacingLg),
              Text('No Data Collection', style: headingStyle),
              const SizedBox(height: spacingSm),
              Text(
                'Wellnot does not collect, transmit, or share any personal '
                'information. The app makes no network calls whatsoever. There '
                'are no analytics, no crash reporting, no advertising, and no '
                'third-party tracking of any kind.',
                style: bodyStyle,
              ),
              const SizedBox(height: spacingLg),
              Text('No Account Required', style: headingStyle),
              const SizedBox(height: spacingSm),
              Text(
                'Wellnot does not require you to create an account, sign in, '
                'or provide any personal information to use the app. There is '
                'no registration, no email collection, and no cloud sync.',
                style: bodyStyle,
              ),
              const SizedBox(height: spacingLg),
              Text('Data Export', style: headingStyle),
              const SizedBox(height: spacingSm),
              Text(
                'You can export your data at any time in CSV or JSON format '
                'through the app settings. Exported files are saved to your '
                'device and shared only through the method you choose (email, '
                'file manager, etc.). Wellnot does not process or retain '
                'exported data.',
                style: bodyStyle,
              ),
              const SizedBox(height: spacingLg),
              Text('Data Deletion', style: headingStyle),
              const SizedBox(height: spacingSm),
              Text(
                'You can delete all your data at any time using the '
                '"Clear & Reset" option in settings. Uninstalling the app also '
                'removes all stored data from your device.',
                style: bodyStyle,
              ),
              const SizedBox(height: spacingLg),
              Text('Notifications', style: headingStyle),
              const SizedBox(height: spacingSm),
              Text(
                'If you enable daily reminders, notifications are scheduled '
                'locally on your device. No notification data is sent to any '
                'external service.',
                style: bodyStyle,
              ),
              const SizedBox(height: spacingLg),
              Text('Children', style: headingStyle),
              const SizedBox(height: spacingSm),
              Text(
                'Wellnot does not knowingly collect any data from anyone, '
                'including children under 13. Since no data is collected or '
                'transmitted, there is no data to protect in this regard.',
                style: bodyStyle,
              ),
              const SizedBox(height: spacingLg),
              Text('Changes to This Policy', style: headingStyle),
              const SizedBox(height: spacingSm),
              Text(
                'If this privacy policy changes, the updated version will be '
                'included in a future app update. Since Wellnot does not '
                'collect contact information, we cannot notify you directly of '
                'changes.',
                style: bodyStyle,
              ),
              const SizedBox(height: spacingLg),
              Text('Contact', style: headingStyle),
              const SizedBox(height: spacingSm),
              Text(
                'If you have questions about this privacy policy, you can '
                'reach us through the "Send Feedback" option in the app '
                'settings.',
                style: bodyStyle,
              ),
              const SizedBox(height: spacingLg),
            ],
          ),
        ),
      ),
    );
  }
}
