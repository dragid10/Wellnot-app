// terms_of_service_screen.dart: In-app terms of service.
//
// Renders the terms of service as styled text. No network calls needed -
// the terms are bundled with the app.
//
// Cross-ref:
//   - Parent: screens/manage_items_screen.dart (navigates here)
//   - Layout constants: constants/layout.dart

import 'package:flutter/material.dart';
import '../../constants/layout.dart';

/// Displays the Wellnot terms of service as scrollable styled text.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
        title: const Text('Terms of Service'),
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
                'By using Wellnot, you agree to the following terms.',
                style: bodyStyle,
              ),
              const SizedBox(height: spacingLg),
              Text('Use of the App', style: headingStyle),
              const SizedBox(height: spacingSm),
              Text(
                'Wellnot is a personal health tracking tool intended for '
                'informational purposes only. It is not a medical device and '
                'does not provide medical advice, diagnoses, or treatment '
                'recommendations. Always consult a qualified healthcare '
                'provider for medical concerns.',
                style: bodyStyle,
              ),
              const SizedBox(height: spacingLg),
              Text('Your Data', style: headingStyle),
              const SizedBox(height: spacingSm),
              Text(
                'All data you enter into Wellnot is stored locally on your '
                'device. You are solely responsible for backing up your data. '
                'If you uninstall the app or clear its data, your entries will '
                'be permanently deleted. We recommend using the export feature '
                'regularly to maintain backups.',
                style: bodyStyle,
              ),
              const SizedBox(height: spacingLg),
              Text('No Warranty', style: headingStyle),
              const SizedBox(height: spacingSm),
              Text(
                'Wellnot is provided "as is" without warranty of any kind, '
                'express or implied. We do not guarantee that the app will be '
                'error-free, uninterrupted, or free of harmful components. '
                'Your use of the app is at your own risk.',
                style: bodyStyle,
              ),
              const SizedBox(height: spacingLg),
              Text('Limitation of Liability', style: headingStyle),
              const SizedBox(height: spacingSm),
              Text(
                'To the fullest extent permitted by law, the developer of '
                'Wellnot shall not be liable for any indirect, incidental, '
                'special, consequential, or punitive damages, or any loss of '
                'data, arising from your use of the app.',
                style: bodyStyle,
              ),
              const SizedBox(height: spacingLg),
              Text('Medical Disclaimer', style: headingStyle),
              const SizedBox(height: spacingSm),
              Text(
                'Wellnot is not a substitute for professional medical care. '
                'The symptom and mood data you record is for your personal '
                'reference and should not be used as the sole basis for any '
                'medical decision. If you are experiencing a medical '
                'emergency, contact your local emergency services immediately.',
                style: bodyStyle,
              ),
              const SizedBox(height: spacingLg),
              Text('Open Source License', style: headingStyle),
              const SizedBox(height: spacingSm),
              Text(
                'Wellnot is open-source software released under the MIT License. '
                'You are free to use, copy, modify, and distribute the software '
                'subject to the terms of that license. The full license text is '
                'available in the project repository.',
                style: bodyStyle,
              ),
              const SizedBox(height: spacingLg),
              Text('Changes to These Terms', style: headingStyle),
              const SizedBox(height: spacingSm),
              Text(
                'These terms may be updated from time to time. Updated terms '
                'will be included in future app updates. Continued use of '
                'Wellnot after changes constitutes acceptance of the updated '
                'terms.',
                style: bodyStyle,
              ),
              const SizedBox(height: spacingLg),
              Text('Contact', style: headingStyle),
              const SizedBox(height: spacingSm),
              Text(
                'If you have questions about these terms, you can reach us '
                'through the "Send Feedback" option in the app settings.',
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
