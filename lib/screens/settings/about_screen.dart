// about_screen.dart: About sub-page with app info and easter eggs.
//
// Shows app name, version, build info, copyright, and a licenses link.
// Preserves the gorilla-chef easter egg from the old AboutSettingsSection.
// Extracted from ManageItemsScreen as part of the settings redesign.
//
// Cross-ref:
//   - Parent: screens/manage_items_screen.dart (navigates here)
//   - Build info: constants/build_info.dart (buildTimestamp)
//   - Layout constants: constants/layout.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as raw_sqlite;
import '../../constants/build_info.dart';
import '../../constants/layout.dart';
import '../../services/encryption_key_service.dart';
import '../../services/preferences_service.dart';

/// Sub-page displaying app info: name, version, copyright, and licenses.
///
/// Easter egg: long-pressing the app name for 8+ seconds shows the
/// gorilla-chef image.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  /// Number of taps required to trigger the build info easter egg.
  static const int _tapsRequired = 8;

  /// Running count of taps on the version row.
  int _tapCount = 0;

  /// Timer for the long-press gorilla-chef easter egg.
  Timer? _longPressTimer;

  /// Timer for the long-press debug mode easter egg on the version row.
  Timer? _debugLongPressTimer;

  /// Whether the database file is encrypted (not plaintext SQLite).
  bool _isEncrypted = false;

  /// Whether debug tools are visible (unlocked by the gorilla chef easter egg).
  bool _debugMode = false;

  @override
  void initState() {
    super.initState();
    _checkEncryptionStatus();
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _debugLongPressTimer?.cancel();
    super.dispose();
  }

  /// Checks whether the on-disk database file is encrypted by reading
  /// the first 16 bytes and verifying they do NOT match the standard
  /// SQLite plaintext header ("SQLite format 3\0").
  ///
  /// Fails silently if the documents directory is unavailable (e.g., in
  /// widget tests where path_provider has no platform channel mock).
  Future<void> _checkEncryptionStatus() async {
    try {
      await _readEncryptionStatus();
    } catch (error) {
      // Non-fatal: encryption status is informational only.
      debugPrint('Could not check encryption status: $error');
    }
  }

  Future<void> _readEncryptionStatus() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(dbFolder.path, 'db.sqlite'));
    if (!dbFile.existsSync() || dbFile.lengthSync() == 0) return;

    final raf = dbFile.openSync(mode: FileMode.read);
    try {
      final bytes = raf.readSync(16);
      if (bytes.length < 16) return;

      const plaintextHeader = <int>[
        0x53,
        0x51,
        0x4C,
        0x69,
        0x74,
        0x65,
        0x20,
        0x66,
        0x6F,
        0x72,
        0x6D,
        0x61,
        0x74,
        0x20,
        0x33,
        0x00,
      ];

      bool isPlaintext = true;
      for (var index = 0; index < 16; index++) {
        if (bytes[index] != plaintextHeader[index]) {
          isPlaintext = false;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _isEncrypted = !isPlaintext;
        });
      }
    } finally {
      raf.closeSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(spacingLg),
          child: FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              final version = info?.version ?? '';
              final buildNumber = info?.buildNumber ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App name with gorilla-chef easter egg on long-press.
                  GestureDetector(
                    onLongPressStart: (_) {
                      _longPressTimer = Timer(
                        const Duration(seconds: 8),
                        () {
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .removeCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Congratulations! You found an Easter Egg \u{1F389}'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                backgroundColor: Colors.transparent,
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(spacingLg),
                                  child: Image.asset(
                                      'assets/images/gorilla-chef.webp'),
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                    onLongPressEnd: (_) {
                      _longPressTimer?.cancel();
                      _longPressTimer = null;
                    },
                    child: Text(
                      'Wellnot',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: spacingSm),

                  // Version row — tapping 8 times shows detailed build info.
                  // Long-pressing 8 seconds unlocks the debug simulation tool.
                  GestureDetector(
                    onLongPressStart: (_) {
                      _debugLongPressTimer = Timer(
                        const Duration(seconds: 8),
                        () {
                          if (mounted) {
                            setState(() {
                              _debugMode = true;
                            });
                            ScaffoldMessenger.of(context)
                                .removeCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Congratulations! You found an Easter Egg \u{1F389}'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                backgroundColor: Colors.transparent,
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(spacingLg),
                                  child: Image.asset(
                                      'assets/images/gorilla-chef.webp'),
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                    onLongPressEnd: (_) {
                      _debugLongPressTimer?.cancel();
                      _debugLongPressTimer = null;
                    },
                    onTap: () async {
                      _tapCount++;
                      final remaining = _tapsRequired - _tapCount;

                      if (remaining > 0 && remaining <= 3) {
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '$remaining more tap${remaining == 1 ? '' : 's'}...'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }

                      if (_tapCount >= _tapsRequired) {
                        _tapCount = 0;
                        final messenger = ScaffoldMessenger.of(context);
                        final latestInfo = await PackageInfo.fromPlatform();
                        if (!mounted || !context.mounted) return;
                        messenger.removeCurrentSnackBar();
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog.adaptive(
                            title: const Text('Build Info'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Version: ${latestInfo.version}'),
                                Text('Build: ${latestInfo.buildNumber}'),
                                Text('Built: $buildTimestamp'),
                                const SizedBox(height: spacingSm),
                                Text('Package: ${latestInfo.packageName}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: spacingXs),
                      child: Text(
                        'v$version (Build $buildNumber)',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: spacingXs),

                  Text(
                    'Built: $buildTimestamp',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: spacingXs),

                  Row(
                    children: [
                      Icon(
                        _isEncrypted ? Icons.lock : Icons.lock_open,
                        size: 16,
                        color: _isEncrypted
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: spacingXs),
                      Text(
                        _isEncrypted ? 'Data encrypted' : 'Data not encrypted',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: spacingSm),

                  Text(
                    '\u00a9 2026 Alex Oladele. All rights reserved.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: spacingXl),

                  // DEBUG: Simulate encryption migration failure.
                  // Decrypts the DB in-place, deletes the key, and sets
                  // the flag — exactly like a real PRAGMA rekey failure.
                  // Hidden until the gorilla chef easter egg is triggered.
                  if (_debugMode)
                    ListTile(
                      leading: const Icon(Icons.bug_report),
                      title: const Text('[DEBUG] Simulate migration failure'),
                      contentPadding: EdgeInsets.zero,
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final dbFolder =
                              await getApplicationDocumentsDirectory();
                          final dbPath = p.join(dbFolder.path, 'db.sqlite');

                          // Decrypt the DB: open with key, rekey to empty.
                          final key =
                              await EncryptionKeyService.getOrCreateKey();
                          final rawDb = raw_sqlite.sqlite3.open(dbPath);
                          rawDb.execute("PRAGMA key = '$key'");
                          rawDb.execute('PRAGMA wal_checkpoint(TRUNCATE)');
                          rawDb.execute("PRAGMA rekey = ''");
                          rawDb.close();

                          // Delete sidecar files.
                          for (final suffix in ['-wal', '-shm', '-journal']) {
                            final sidecar = File('$dbPath$suffix');
                            if (sidecar.existsSync()) {
                              await sidecar.delete();
                            }
                          }

                          // Delete the encryption key.
                          await EncryptionKeyService.deleteKey();

                          // Set the migration failed flag.
                          await PreferencesService
                              .saveEncryptionMigrationFailed(true);

                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'DB decrypted and flag set. Force '
                                'close and reopen to test recovery.',
                              ),
                            ),
                          );
                        } catch (error) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Simulation failed: $error'),
                            ),
                          );
                        }
                      },
                    ),

                  // Licenses link.
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Open Source Licenses'),
                    trailing: const Icon(Icons.chevron_right),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'Wellnot',
                        applicationVersion: 'v$version',
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
