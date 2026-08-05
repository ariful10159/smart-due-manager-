import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

import 'package:smart_due/services/pin_service.dart';

// Same construction as the pre-migration PinService.hashPin, kept here only to
// build a legacy-format fixture for the migration tests below.
String _legacyHash(String pin) =>
    sha256.convert(utf8.encode('smart_due_salt_$pin')).toString();

void main() {
  group('PinService — new (pinv2) format', () {
    test('hashPin produces a pinv2-prefixed hash', () {
      final hash = PinService.hashPin('1234');
      expect(hash.startsWith('pinv2\$'), isTrue);
      expect(PinService.isLegacyFormat(hash), isFalse);
    });

    test('verifyPin accepts the correct PIN', () {
      final hash = PinService.hashPin('4321');
      expect(PinService.verifyPin('4321', hash), isTrue);
    });

    test('verifyPin rejects an incorrect PIN', () {
      final hash = PinService.hashPin('4321');
      expect(PinService.verifyPin('0000', hash), isFalse);
    });

    test('two hashes of the same PIN are different (random salt)', () {
      final hashA = PinService.hashPin('1234');
      final hashB = PinService.hashPin('1234');
      expect(hashA, isNot(equals(hashB)));
      // but both still verify correctly
      expect(PinService.verifyPin('1234', hashA), isTrue);
      expect(PinService.verifyPin('1234', hashB), isTrue);
    });

    test('verifyPin rejects a malformed/corrupted stored hash', () {
      expect(PinService.verifyPin('1234', 'pinv2\$not\$valid'), isFalse);
      expect(PinService.verifyPin('1234', 'pinv2\$0\$abc\$def'), isFalse);
    });
  });

  group('PinService — legacy format (pre-migration)', () {
    test('isLegacyFormat detects bare SHA-256 hex hashes', () {
      final legacy = _legacyHash('1234');
      expect(PinService.isLegacyFormat(legacy), isTrue);
    });

    test('verifyPin still accepts a correct PIN against a legacy hash', () {
      final legacy = _legacyHash('1234');
      expect(PinService.verifyPin('1234', legacy), isTrue);
    });

    test('verifyPin still rejects a wrong PIN against a legacy hash', () {
      final legacy = _legacyHash('1234');
      expect(PinService.verifyPin('9999', legacy), isFalse);
    });

    test('a freshly migrated hash (via hashPin) is no longer legacy', () {
      const pin = '1234';
      final legacy = _legacyHash(pin);
      expect(PinService.isLegacyFormat(legacy), isTrue);

      // Simulates what AppLockScreen does after a successful legacy verify.
      expect(PinService.verifyPin(pin, legacy), isTrue);
      final migrated = PinService.hashPin(pin);

      expect(PinService.isLegacyFormat(migrated), isFalse);
      expect(PinService.verifyPin(pin, migrated), isTrue);
    });
  });
}
