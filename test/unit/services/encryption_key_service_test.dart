import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symptom_tracker_app/services/encryption_key_service.dart';

void main() {
  group('EncryptionKeyService', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test(
      'As a user, I expect a new encryption key to be generated on first launch',
      () async {
        final key = await EncryptionKeyService.getOrCreateKey();

        expect(key, isNotNull);
        expect(key.length, 64); // 32 bytes = 64 hex chars
        expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(key), isTrue);
      },
    );

    test(
      'As a user, I expect the same encryption key to be returned on subsequent launches',
      () async {
        final firstKey = await EncryptionKeyService.getOrCreateKey();
        final secondKey = await EncryptionKeyService.getOrCreateKey();

        expect(firstKey, equals(secondKey));
      },
    );

    test(
      'As a user, I expect a new key after the old key is deleted '
      '-- simulates key loss from system data clear',
      () async {
        final originalKey = await EncryptionKeyService.getOrCreateKey();
        await EncryptionKeyService.deleteKey();
        final newKey = await EncryptionKeyService.getOrCreateKey();

        expect(newKey, isNot(equals(originalKey)));
        expect(newKey.length, 64);
      },
    );

    test(
      'As a user, I expect the encryption key to be valid hex',
      () async {
        final key = await EncryptionKeyService.getOrCreateKey();

        // Each pair of hex chars represents one byte
        for (var index = 0; index < key.length; index += 2) {
          final byteHex = key.substring(index, index + 2);
          final value = int.tryParse(byteHex, radix: 16);
          expect(value, isNotNull);
          expect(value, greaterThanOrEqualTo(0));
          expect(value, lessThanOrEqualTo(255));
        }
      },
    );

    test(
      'As a user, I expect deleteKey to succeed even when no key exists',
      () async {
        // Should not throw
        await EncryptionKeyService.deleteKey();
      },
    );

    test(
      'As a user, I expect consecutive key generations to produce unique keys',
      () async {
        final key1 = await EncryptionKeyService.getOrCreateKey();
        await EncryptionKeyService.deleteKey();
        final key2 = await EncryptionKeyService.getOrCreateKey();
        await EncryptionKeyService.deleteKey();
        final key3 = await EncryptionKeyService.getOrCreateKey();

        // All three keys should be distinct (cryptographically unlikely to collide)
        expect({key1, key2, key3}.length, 3);
      },
    );
  });
}
