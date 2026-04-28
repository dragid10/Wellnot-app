// encryption_issue_screen.dart: Guided recovery from encryption migration
// failure.
//
// Walks the user through exporting their data, confirming they have done so,
// resetting the database, and re-importing. Shown when _migrateToEncrypted()
// fails and the app falls back to an unencrypted database.
//
// Cross-ref:
//   - Navigation: screens/manage_items_screen.dart (warning banner)
//   - Recovery logic: services/encryption_recovery_service.dart
//   - Export codepath: services/export_service.dart
//   - String constants: constants/encryption_recovery.dart
//   - Preferences flag: constants/defaults.dart (prefKeyEncryptionMigrationFailed)

import 'dart:io' show exit;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/encryption_recovery.dart';
import '../../constants/layout.dart';
import '../../services/database.dart';
import '../../services/encryption_recovery_service.dart';
import '../../services/export_service.dart';
import '../../widgets/loading_overlay.dart';

/// Guided recovery screen for encryption migration failures.
class EncryptionIssueScreen extends StatefulWidget {
  const EncryptionIssueScreen({super.key});

  @override
  State<EncryptionIssueScreen> createState() => _EncryptionIssueScreenState();
}

class _EncryptionIssueScreenState extends State<EncryptionIssueScreen> {
  late AppDatabase _database;
  bool _initialized = false;
  final _confirmationController = TextEditingController();
  bool _isResetting = false;

  bool get _confirmationMatches =>
      _confirmationController.text.trim().toLowerCase() ==
      encryptionRecoveryConfirmationPhrase.toLowerCase();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _database = context.read<AppDatabase>();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _exportData() async {
    try {
      final entries = await _database.getAllEntriesWithDetails();
      if (entries.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data to export.')),
          );
        }
        return;
      }
      final savedPath =
          await ExportService.exportAndSave(entries, ExportFormat.json);
      if (mounted && savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export saved successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $error')),
        );
      }
    }
  }

  Future<void> _resetDatabase() async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog.adaptive(
          title: const Text(encryptionRecoveryResetConfirmTitle),
          content: const Text(encryptionRecoveryResetConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Encrypt'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isResetting = true;
    });

    try {
      await EncryptionRecoveryService.resetToEncrypted(_database);
      if (mounted) {
        await showAdaptiveDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog.adaptive(
              title: const Text(encryptionRecoveryEncryptCompleteTitle),
              content: const Text(encryptionRecoveryEncryptComplete),
              actions: [
                TextButton(
                  onPressed: () => exit(0),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset failed: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LoadingOverlay(
      isLoading: _isResetting,
      message: 'Resetting database...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text(encryptionRecoveryScreenTitle),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Explanation
                Text(
                  encryptionRecoveryExplanation,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: spacingXl),

                // Step 1: Export button
                Text(
                  'Step 1: Export your data',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: spacingSm),
                OutlinedButton.icon(
                  onPressed: _exportData,
                  icon: const Icon(Icons.upload_outlined),
                  label: const Text('Export Data'),
                ),
                const SizedBox(height: spacingLg),

                // Warning card
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(spacingLg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: spacingSm),
                        Expanded(
                          child: Text(
                            encryptionRecoveryDataWarning,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: spacingXl),

                // Step 2: Confirmation
                Text(
                  'Step 2: Confirm and encrypt',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: spacingSm),
                Text(
                  encryptionRecoveryConfirmationPrompt,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: spacingSm),
                TextField(
                  controller: _confirmationController,
                  decoration: const InputDecoration(
                    hintText: 'Type "I Promise"',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: spacingLg),
                FilledButton(
                  onPressed: _confirmationMatches ? _resetDatabase : null,
                  child: const Text('Encrypt Database'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
