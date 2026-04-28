// widgets/changelog_dialog.dart: "What's New" changelog modal
//
// Shows a dialog with changelog entries for the current app version on first
// launch or after an update. Uses Material AlertDialog on all platforms —
// CupertinoAlertDialog is too narrow for content-heavy lists like changelogs.
//
// Entries are grouped into sections: general (no header), then Android-only
// and iOS-only under their own section headers. Each entry is prefixed with
// a text tag like [New], [Fix], or [Improved].
//
// Cross-ref:
//   - Changelog data: constants/changelog.dart (ChangelogEntry, ChangelogEntryType)
//   - Layout constants: constants/layout.dart
//   - Called from: screens/calendar_screen.dart, screens/manage_items_screen.dart

import 'package:flutter/material.dart';
import '../constants/changelog.dart';
import '../constants/layout.dart';

/// Shows the changelog dialog with a list of changes for the current version.
///
/// [version] is the current app version string (e.g., "1.9.0").
/// [entries] is the list of changelog items to display.
Future<void> showChangelogDialog({
  required BuildContext context,
  required String version,
  required List<ChangelogEntry> entries,
}) {
  final title = "What's New in v$version";

  // Group entries by platform.
  final general =
      entries.where((e) => e.platform == ChangelogPlatform.all).toList();
  final android =
      entries.where((e) => e.platform == ChangelogPlatform.android).toList();
  final ios =
      entries.where((e) => e.platform == ChangelogPlatform.ios).toList();

  return showDialog(
    context: context,
    // Material AlertDialog on all platforms — CupertinoAlertDialog has a
    // fixed narrow width (~270dp) unsuitable for content-heavy changelogs.
    // On wide screens (tablets), constrain content to dialogMaxWidth.
    builder: (context) {
      final isWideScreen =
          MediaQuery.sizeOf(context).width > wideScreenBreakpoint;

      final scrollController = ScrollController();
      final content = Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // General entries (no section header).
                for (final entry in general) _buildEntryRow(entry, context),
                // Android section.
                if (android.isNotEmpty) ...[
                  _buildSectionHeader('Android', context),
                  for (final entry in android) _buildEntryRow(entry, context),
                ],
                // iOS section.
                if (ios.isNotEmpty) ...[
                  _buildSectionHeader('iOS', context),
                  for (final entry in ios) _buildEntryRow(entry, context),
                ],
              ],
            ),
          ));

      return AlertDialog(
        title: Text(title),
        content: isWideScreen
            ? SizedBox(width: dialogMaxWidth, child: content)
            : content,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      );
    },
  );
}

/// Builds a single changelog entry row with a bullet, text tag, and description.
Widget _buildEntryRow(ChangelogEntry entry, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(bottom: spacingSm),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '\u2022 ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextSpan(
            text: '${_tagForType(entry.type)} ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          TextSpan(
            text: entry.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}

/// Builds a platform section header (e.g., "Android", "iOS").
Widget _buildSectionHeader(String label, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(top: spacingSm, bottom: spacingSm),
    child: Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    ),
  );
}

/// Returns the text tag prefix for a changelog entry type.
String _tagForType(ChangelogEntryType type) {
  switch (type) {
    case ChangelogEntryType.feature:
      return '[New]';
    case ChangelogEntryType.fix:
      return '[Fix]';
    case ChangelogEntryType.improvement:
      return '[Improved]';
  }
}
