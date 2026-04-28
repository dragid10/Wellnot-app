import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:symptom_tracker_app/services/database.dart';

/// Ensures the native sqlite3 library can be found on the test platform.
///
/// sqlite3 v3 bundles a precompiled binary via build hooks for production
/// builds, but `flutter test` may still need the system library. This
/// helper loads the correct shared object for both Linux and macOS:
///   - Linux: `libsqlite3.so.0` (common soname on Fedora/Ubuntu)
///   - macOS: `libsqlite3.dylib` (ships with macOS by default)
void _ensureSqlite3() {
  if (Platform.isLinux) {
    DynamicLibrary.open('libsqlite3.so.0');
  } else if (Platform.isMacOS) {
    DynamicLibrary.open('libsqlite3.dylib');
  }
  // Windows and other platforms: sqlite3 v3 build hooks handle it.
}

/// Creates an in-memory [AppDatabase] for unit and widget tests.
///
/// Each call returns a fresh database instance with no pre-existing data.
/// The caller is responsible for calling [AppDatabase.close] when done.
///
/// Works on both Linux and macOS — see [_ensureSqlite3] for platform details.
///
/// Cross-ref:
///   - Production DB setup: lib/services/database.dart
///   - Used by: all tests under test/unit/services/ and test/widget/screens/
AppDatabase createTestDatabase() {
  _ensureSqlite3();
  return AppDatabase.forTesting(NativeDatabase.memory());
}
