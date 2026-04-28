// import_data_screen.dart: Data import sub-page.
//
// Allows users to restore symptom data from a previously exported JSON file
// (or a ZIP containing one). Uses file_picker for file selection, validates
// the JSON structure, shows a preview, and imports via ImportService.
//
// Cross-ref:
//   - Parent: screens/manage_items_screen.dart (navigates here)
//   - Import service: services/import_service.dart
//   - Export format: services/export_service.dart (toJson)
//   - Database: services/database.dart (saveEntry)

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/layout.dart';
import '../../services/database.dart';
import '../../services/import_service.dart';
import '../../widgets/loading_overlay.dart';

/// Sub-page for importing symptom data from a Wellnot JSON export.
class ImportDataScreen extends StatefulWidget {
  const ImportDataScreen({super.key});

  @override
  State<ImportDataScreen> createState() => _ImportDataScreenState();
}

class _ImportDataScreenState extends State<ImportDataScreen> {
  late AppDatabase _database;
  bool _initialized = false;
  bool _importing = false;

  /// The parsed JSON content ready for import (null until a file is loaded).
  String? _jsonContent;

  /// Validation result for the loaded file.
  ImportValidation? _validation;

  /// The name of the selected file (for display).
  String? _fileName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _database = context.read<AppDatabase>();
      _initialized = true;
    }
  }

  /// Opens the file picker and loads a JSON or ZIP file.
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'zip'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    final bytes = await File(file.path!).readAsBytes();
    String? jsonContent;

    if (file.name.endsWith('.zip')) {
      jsonContent = await ImportService.extractJsonFromZip(bytes);
      if (jsonContent == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No JSON file found in the selected ZIP.'),
            ),
          );
        }
        return;
      }
    } else {
      jsonContent = utf8.decode(bytes);
    }

    final validation = ImportService.validate(jsonContent);

    setState(() {
      _jsonContent = jsonContent;
      _validation = validation;
      _fileName = file.name;
    });
  }

  /// Imports the loaded JSON data into the database.
  Future<void> _import() async {
    if (_jsonContent == null) return;

    setState(() {
      _importing = true;
    });

    // Wait for the frame to finish painting so the loading overlay is
    // visible before the import blocks the UI thread.
    await WidgetsBinding.instance.endOfFrame;

    try {
      final result = await ImportService.importFromJson(
        _database,
        _jsonContent!,
      );

      if (mounted) {
        final message = StringBuffer();
        if (result.importedCount > 0) {
          message.write(
            'Imported ${result.importedCount} '
            '${result.importedCount == 1 ? 'entry' : 'entries'}',
          );
        }
        if (result.skippedCount > 0) {
          if (message.isNotEmpty) message.write(', ');
          message.write(
            'skipped ${result.skippedCount} '
            '${result.skippedCount == 1 ? 'duplicate' : 'duplicates'}',
          );
        }
        if (result.importedCount == 0 && result.skippedCount == 0) {
          message.write('No entries to import.');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.toString())),
        );

        // Clear the loaded file after successful import.
        setState(() {
          _jsonContent = null;
          _validation = null;
          _fileName = null;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _importing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LoadingOverlay(
      isLoading: _importing,
      message: 'Importing data...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Import Data'),
        ),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restore your symptom data from a Wellnot backup file '
                  '(JSON or ZIP).',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: spacingSm),
                Text(
                  'Existing entries are preserved — only new entries will be '
                  'added.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: spacingLg),

                // File picker button.
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _importing ? null : _pickFile,
                    icon: const Icon(Icons.file_open_outlined),
                    label: Text(
                      _fileName ?? 'Select backup file',
                    ),
                  ),
                ),

                // Validation / preview section.
                if (_validation != null) ...[
                  const SizedBox(height: spacingLg),
                  _buildValidationCard(theme),
                ],

                const Spacer(),

                // Import button.
                if (_validation != null && _validation!.isValid)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _importing ? null : _import,
                      icon: _importing
                          ? SizedBox(
                              width: spacingLg,
                              height: spacingLg,
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Icon(Icons.upload_outlined),
                      label: Text(
                        _importing
                            ? 'Importing...'
                            : 'Import ${_validation!.entryCount} '
                                '${_validation!.entryCount == 1 ? 'entry' : 'entries'}',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a card showing validation results: success preview or error list.
  Widget _buildValidationCard(ThemeData theme) {
    if (_validation!.isValid) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(spacingLg),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to import',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: spacingXs),
                    Text(
                      '${_validation!.entryCount} '
                      '${_validation!.entryCount == 1 ? 'entry' : 'entries'} '
                      'found in $_fileName',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Validation failed — show errors.
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: spacingMd),
                Text(
                  'Invalid backup file',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: spacingSm),
            ...(_validation!.errors.map(
              (error) => Padding(
                padding: const EdgeInsets.only(
                  left: spacingLg + spacingMd,
                  top: spacingXs,
                ),
                child: Text(
                  error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
