import 'dart:convert';

import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/auth/der_ecdsa_signature.dart';
import 'package:web_server/src/auth/p256_public_key.dart';
import 'package:web_server/src/auth/p256_signature_verifier.dart';

// A vektorok Pythonnal (cryptography/OpenSSL) keszultek, igy a
// pointycastle-alapu ellenorzes egy fuggetlen implementacioval egyezik.
const String _spki =
    'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEYP7UuiVanTHJYet0xjVtaMBJuJI7Yfps'
    '5mliLmDyn7Z5A/4QCLi8maQa6elWKLxk8vGyDC1+n1F3o8KU1EYimQ==';
const String _otherSpki =
    'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEJu/OvQ7p40pmkYfhizqRIrL3M5RbZJzJ'
    '+fkh6fna2BKQI4venMe7Mw0VDGdwTdJa5wVSBXRLbzG/QHB0WHLQ5g==';
const String _secp256k1Spki =
    'MFYwEAYHKoZIzj0CAQYFK4EEAAoDQgAE8B1rkBirQh3UEEBMuGkHIGVSK/hXNACPEFzz'
    'haAjqA8OuinQ8MVAjtaBmE3FJZgqvvzNn3/wHdJtpJmc8/ailQ==';
const String _offCurveSpki =
    'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEYP7UuiVanTHJYet0xjVtaMBJuJI7Yfps'
    '5mliLmDyn7Z5A/4QCLi8maQa6elWKLxk8vGyDC1+n1F3o8KU1EYimA==';
const String _signature =
    'MEYCIQCFs0HShboTzwkfaNA87AvzmsnkB8f1llF29zkX8baEOwIhAILLmbrzN2R8hmsy'
    'GCVekfxyKm1UORO40cuMPhYBWp2l';
const String _signatureWithOtherS =
    'MEUCIQCFs0HShboTzwkfaNA87AvzmsnkB8f1llF29zkX8baEOwIgfTRmRAzIm4R5lM3n'
    '2qFuA0q8jVluA+WzKC2MrPsIh6w=';
const String _nonMinimalSignature =
    'MEYCIQCFs0HShboTzwkfaNA87AvzmsnkB8f1llF29zkX8baEOwIhAH00ZkQMyJuEeZTN'
    '59qhbgNKvI1ZbgPlsygtjKz7CIes';

final List<int> _message = loginApprovalMessage(
  origin: 'https://archivum.example.hu',
  requestId: 'AAECAwQFBgcICQoLDA0ODw',
  challenge: 'ICEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj8',
  deviceId: 'device-1',
);

P256PublicKey _key(String spki) => P256PublicKey.tryParse(base64.decode(spki))!;

bool _verify({
  String spki = _spki,
  List<int>? message,
  String signature = _signature,
}) => verifyP256Signature(
  publicKey: _key(spki),
  message: message ?? _message,
  derSignature: base64.decode(signature),
);

void main() {
  group('P256PublicKey.tryParse', () {
    test('reads the point and keeps the original encoding', () {
      final der = base64.decode(_spki);

      final key = P256PublicKey.tryParse(der);

      expect(key, isNotNull);
      expect(key!.spki, der);
    });

    test('rejects a key on another curve', () {
      expect(P256PublicKey.tryParse(base64.decode(_secp256k1Spki)), isNull);
    });

    test('rejects a point that is not on the curve', () {
      expect(P256PublicKey.tryParse(base64.decode(_offCurveSpki)), isNull);
    });

    test('rejects a truncated or extended encoding', () {
      final der = base64.decode(_spki);

      expect(P256PublicKey.tryParse(der.sublist(0, 90)), isNull);
      expect(P256PublicKey.tryParse([...der, 0]), isNull);
    });
  });

  group('parseDerEcdsaSignature', () {
    test('reads both integers of a valid signature', () {
      final values = parseDerEcdsaSignature(base64.decode(_signature));

      expect(values, isNotNull);
      expect(values!.r.bitLength, 256);
    });

    test('rejects a non-minimal integer encoding', () {
      expect(
        parseDerEcdsaSignature(base64.decode(_nonMinimalSignature)),
        isNull,
      );
    });

    test('rejects a wrong length, a trailing byte and a negative integer', () {
      final der = base64.decode(_signature);

      expect(parseDerEcdsaSignature(der.sublist(0, der.length - 1)), isNull);
      expect(parseDerEcdsaSignature([...der, 0]), isNull);
      // Az r vezeto nullaja nelkul a szam negativnak latszana.
      final negative = [0x30, der[1] - 1, 0x02, 0x20, ...der.sublist(5)];
      expect(parseDerEcdsaSignature(negative), isNull);
    });
  });

  group('verifyP256Signature', () {
    test('accepts the signature made by the key over the message', () {
      expect(_verify(), isTrue);
    });

    test('accepts the equivalent signature with n - s', () {
      expect(_verify(signature: _signatureWithOtherS), isTrue);
    });

    test('rejects a changed message', () {
      final changed = [..._message]..[_message.length - 1] ^= 1;

      expect(_verify(message: changed), isFalse);
    });

    test('rejects the signature under another key', () {
      expect(_verify(spki: _otherSpki), isFalse);
    });

    test('rejects a malformed signature without throwing', () {
      expect(_verify(signature: _nonMinimalSignature), isFalse);
      expect(_verify(signature: 'AAAA'), isFalse);
    });
  });
}
