// feedback_screen.dart: In-app feedback screen.
//
// Lets users compose feedback (bugs, feature requests, general) and send it
// via the device's share sheet. No screenshots are captured or attached to
// protect user privacy. No network calls from the app — the user's chosen
// sharing method (email, messages, etc.) handles delivery.
//
// Cross-ref:
//   - Entry points: manage_items_screen.dart ("Send Feedback" link),
//     shake gesture in app.dart
//   - Uses share_plus for the share sheet
//   - Uses package_info_plus for app version in the message body

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app.dart';
import '../constants/layout.dart';
import '../services/achievement_service.dart';
import '../services/database.dart';
import '../services/preferences_service.dart';
import '../widgets/adaptive_segmented_control.dart';

/// Feedback categories shown in the category selector.
enum FeedbackCategory {
  bug('Bug Report'),
  feature('Feature Request'),
  general('General Feedback');

  final String label;
  const FeedbackCategory(this.label);
}

/// Screen for composing and sending feedback via the device's share sheet.
///
/// Pre-fills the subject with the selected category and appends device/app
/// info to the message body automatically. No data is collected or stored
/// by the app — everything goes through the user's chosen sharing method.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _messageController = TextEditingController();
  FeedbackCategory _category = FeedbackCategory.general;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// Builds the email body with the user's message and appended device info.
  Future<String> _buildEmailBody() async {
    final info = await PackageInfo.fromPlatform();
    final message = _messageController.text.trim();

    return '[Wellnot ${_category.label}]\n\n'
        '$message'
        '\n\n'
        '---\n'
        'App: ${info.appName} v${info.version} (${info.buildNumber})\n'
        'Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n';
  }

  /// Opens the user's email client with feedback pre-filled.
  /// Uses a mailto: link so feedback always goes to the developer.
  Future<void> _sendFeedback() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
      return;
    }

    final body = await _buildEmailBody();
    final subject = '[Wellnot] ${_category.label}';

    // TODO: Replace your-email@example.com with your own support email address.
    // Build the mailto URI manually — Uri(queryParameters:) encodes spaces
    // as '+' (x-www-form-urlencoded), but mailto requires '%20'.
    final uri = Uri.parse('mailto:your-email@example.com'
        '?subject=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(body)}');

    try {
      final launched = await launchUrl(uri);
      if (launched && mounted) {
        _checkFeedbackAchievement();
      } else if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No email app found. Please send feedback to '
                'your-email@example.com'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No email app found. Please send feedback to '
                'your-email@example.com'),
          ),
        );
      }
    }
  }

  Future<void> _checkFeedbackAchievement() async {
    if (!PreferencesService.achievementsEnabledNotifier.value) return;
    final database = context.read<AppDatabase>();
    final unlocked = await AchievementService.checkAfterFeedback(database);
    if (unlocked.isNotEmpty) {
      notifyAchievementsUnlocked(unlocked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Feedback'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Feedback category selector — Bug, Feature Request, or General.
                Text('Category',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: spacingSm),
                AdaptiveSegmentedControl<FeedbackCategory>(
                  segments: {
                    for (final c in FeedbackCategory.values) c: c.label,
                  },
                  selected: _category,
                  onChanged: (value) {
                    setState(() {
                      _category = value;
                    });
                  },
                ),

                const SizedBox(height: spacingLg),

                // Message text field — the main feedback content.
                Text('Message', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: spacingSm),
                TextField(
                  controller: _messageController,
                  maxLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Describe the bug, feature idea, or feedback...',
                  ),
                ),

                const SizedBox(height: spacingSm),

                // Info text explaining how feedback is sent.
                Text(
                  'Your feedback will be sent via email. '
                  'App version and device info are included automatically. '
                  'No data is collected or stored by Wellnot.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: spacingXl),

                // Send button — opens the share sheet with pre-filled content.
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _sendFeedback,
                    icon: const Icon(Icons.send),
                    label: const Text('Send Feedback'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: buttonVerticalPadding),
                    ),
                  ),
                ),

                const SizedBox(height: spacingXl),
                const Divider(),

                // Shake-to-feedback toggle — moved here from top-level settings.
                ValueListenableBuilder<bool>(
                  valueListenable: PreferencesService.shakeToFeedbackNotifier,
                  builder: (context, enabled, _) {
                    return SwitchListTile.adaptive(
                      title: const Text('Shake to Send Feedback'),
                      subtitle:
                          const Text('Shake your device to open feedback'),
                      value: enabled,
                      onChanged: PreferencesService.saveShakeToFeedback,
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
