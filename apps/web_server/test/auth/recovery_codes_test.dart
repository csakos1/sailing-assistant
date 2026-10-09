import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:web_server/src/auth/random_bytes.dart';
import 'package:web_server/src/auth/recovery_codes.dart';

// Minden hivas a kovetkezo bajtokat adja: 0, 1, 2, ...
RandomBytes _counting() {
  var next = 0;
  return (length) =>
      Uint8List.fromList([for (var i = 0; i < length; i++) next++ & 0xFF]);
}

void main() {
  group('generateRecoveryCodes', () {
    test('makes ten distinct codes of two five-letter groups', () {
      final codes = generateRecoveryCodes(_counting());

      expect(codes, hasLength(recoveryCodeCount));
      expect(codes.toSet(), hasLength(recoveryCodeCount));
      for (final code in codes) {
        expect(code, matches(RegExp(r'^[A-Z2-7]{5}-[A-Z2-7]{5}$')));
      }
    });

    test('maps the low five bits of each byte to the base32 alphabet', () {
      final codes = generateRecoveryCodes(_counting());

      expect(codes.first, 'ABCDE-FGHIJ');
      expect(codes[3], '67ABC-DEFGH');
    });

    test('draws again when a code repeats', () {
      // Az elso ket hivas ugyanazt adja, igy 11 hivas kell 10 kodhoz.
      var calls = 0;
      final codes = generateRecoveryCodes((length) {
        calls++;
        final seed = calls == 2 ? 0 : calls - 1;
        return Uint8List.fromList(List.filled(length, seed));
      });

      expect(codes.toSet(), hasLength(recoveryCodeCount));
      expect(calls, recoveryCodeCount + 1);
    });
  });

  group('normalizeRecoveryCode', () {
    test('accepts lower case, spaces and the hyphen', () {
      expect(normalizeRecoveryCode(' k7q2m 7xwpd '), 'K7Q2M7XWPD');
      expect(normalizeRecoveryCode('K7Q2M-7XWPD'), 'K7Q2M7XWPD');
    });

    test('rejects a wrong length or a character outside base32', () {
      expect(normalizeRecoveryCode('K7Q2M-7XWP'), isNull);
      expect(normalizeRecoveryCode('K7Q2M-7XWPDD'), isNull);
      expect(normalizeRecoveryCode('K7Q2M-0XWPD'), isNull);
      // A 8 es a 9 sincs a base32 abeceben.
      expect(normalizeRecoveryCode('K7Q2M-9XWPD'), isNull);
      expect(normalizeRecoveryCode('jelszó-jelszó'), isNull);
    });
  });
}
