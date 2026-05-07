// export_data_screen.dart: Data export sub-page.
//
// Presents JSON and CSV export options as navigable tiles. JSON is listed
// first and recommended because it is the only format supported by the
// import/restore flow (see import_data_screen.dart).
// Extracted from DataSettingsSection as part of the settings redesign.
//
// Cross-ref:
//   - Parent: screens/manage_items_screen.dart (navigates here)
//   - Export service: services/export_service.dart
//   - Database: services/database.dart (getAllEntriesWithDetails)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app.dart';
import '../../constants/layout.dart';
import '../../services/achievement_service.dart';
import '../../services/database.dart';
import '../../services/export_service.dart';
import '../../services/preferences_service.dart';

/// Sub-page for choosing an export format and exporting symptom data.
class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  late AppDatabase _database;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _database = context.read<AppDatabase>();
      _initialized = true;
    }
  }

  /// Exports data in the specified format.
  Future<void> _export(ExportFormat format) async {
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
      final savedPath = await ExportService.exportAndSave(entries, format);
      if (mounted) {
        if (savedPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export saved successfully')),
          );
          if (PreferencesService.achievementsEnabledNotifier.value) {
            final unlocked =
                await AchievementService.checkAfterExport(_database);
            if (unlocked.isNotEmpty) {
              notifyAchievementsUnlocked(unlocked);
            }
          }
        }
      }
    } on PlatformException catch (platformError) {
      // file_picker throws PlatformException when the user cancels the
      // save dialog — not a real error, so silently ignore it.
      if (platformError.code == 'FileSaver' ||
          (platformError.message?.contains('cancel') ?? false)) {
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${platformError.message}')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a format to export your symptom data.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: spacingLg),
              ListTile(
                leading: const Icon(Icons.data_object),
                title: const Text('JSON (Recommended)'),
                subtitle: const Text(
                    'Required for backup & restore. Also useful for developers and data analysis'),
                contentPadding: EdgeInsets.zero,
                onTap: () => _export(ExportFormat.json),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: const Text('CSV'),
                subtitle: const Text(
                    'Opens in Excel, Google Sheets, and other spreadsheet apps'),
                contentPadding: EdgeInsets.zero,
                onTap: () => _export(ExportFormat.csv),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
