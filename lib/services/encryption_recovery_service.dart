// encryption_recovery_service.dart: Database reset logic for encryption
// migration failure recovery.
//
// Encapsulates the destructive reset operation so it is testable and kept
// out of the UI layer. Called from the EncryptionIssueScreen after the user
// confirms they have exported their data.
//
// Cross-ref:
//   - UI: screens/settings/encryption_issue_screen.dart
//   - Key management: services/encryption_key_service.dart
//   - Preferences: services/preferences_service.dart
//   - Flag key: constants/defaults.dart (prefKeyEncryptionMigrationFailed)

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'encryption_key_service.dart';
import 'preferences_service.dart';
import '../services/database.dart';

/// Handles database reset and re-encryption after a failed encryption migration.
class EncryptionRecoveryService {
  /// Whether the encryption migration has failed and needs user attention.
  static bool get hasEncryptionIssue =>
      PreferencesService.encryptionMigrationFailedNotifier.value;

  /// Resets the database to enable encryption on next launch.
  ///
  /// 1. Backs up the current (unencrypted) database to db.sqlite.recovery-bak
  /// 2. Closes the active database connection
  /// 3. Deletes the database file and all sidecar files
  /// 4. Deletes the encryption key (a new one will be generated on next open)
  /// 5. Clears the migration failure flag
  ///
  /// After this method completes, the user must close and reopen the app.
  /// On next launch, _openConnection() will create a fresh encrypted database.
  /// The user can then import their previously exported data.
  static Future<void> resetToEncrypted(AppDatabase database) async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(dbFolder.path, 'db.sqlite'));
    final backupFile = File(p.join(dbFolder.path, 'db.sqlite.recovery-bak'));

    // Safety backup in case something goes wrong.
    if (dbFile.existsSync()) {
      await dbFile.copy(backupFile.path);
    }

    // Close the active connection before deleting files.
    await database.close();

    // Delete database and sidecar files.
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final file = File(p.join(dbFolder.path, 'db.sqlite$suffix'));
      if (file.existsSync()) {
        await file.delete();
      }
    }

    // Delete the old encryption key so a fresh one is generated on next open.
    await EncryptionKeyService.deleteKey();

    // Clear the migration failure flag.
    await PreferencesService.saveEncryptionMigrationFailed(false);
  }
}
