import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the database encryption key using platform-secure storage.
///
/// On Android, the key is stored in EncryptedSharedPreferences backed by
/// the Android Keystore. On iOS, it's stored in the Keychain with
/// `first_unlock` accessibility (available after the first device unlock,
/// needed for background widget updates).
///
/// The key is generated once per install and persists until the app data
/// is cleared via system settings or [deleteKey] is called explicitly.
///
/// Cross-ref:
///   - Used by: lib/services/database.dart (_openConnection)
///   - Key format: 32 random bytes encoded as 64-character hex string
class EncryptionKeyService {
  static const _storageKey = 'wellnot_db_encryption_key';

  static const _keyLengthBytes = 32;
  static const _keyLengthHex = _keyLengthBytes * 2; // 64 hex chars

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Returns the encryption key, generating and storing a new one if none
  /// exists or if the stored key is invalid.
  static Future<String> getOrCreateKey() async {
    final existing = await _storage.read(key: _storageKey);
    if (existing != null && existing.length == _keyLengthHex) {
      return existing;
    }

    final key = _generateKey();
    await _storage.write(key: _storageKey, value: key);
    return key;
  }

  /// Deletes the stored encryption key.
  ///
  /// Called when the database file must be recreated from scratch (e.g.,
  /// after detecting a key mismatch from a system data clear). A new key
  /// will be generated on the next [getOrCreateKey] call.
  static Future<void> deleteKey() async {
    await _storage.delete(key: _storageKey);
  }

  /// Generates a cryptographically secure 32-byte key as a hex string.
  static String _generateKey() {
    final random = Random.secure();
    final bytes =
        List<int>.generate(_keyLengthBytes, (_) => random.nextInt(256));
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}
