import 'dart:typed_data';

import 'package:pointycastle/api.dart' show PrivateKeyParameter;
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/secp256r1.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/signers/ecdsa_signer.dart';

// Tesztbeli „telefon" (ADR 0051 D13): pure Dart P-256 aláíró a két
// kulccsal. A k az RFC 6979 szerint determinisztikus (HMAC-SHA-256), így
// a tesztek ismételhetők. Az aláírás DER, a kulcs SubjectPublicKeyInfo,
// mint az Android Keystore-é.

final ECCurve_secp256r1 _domain = ECCurve_secp256r1();

final List<int> _spkiPrefix = _fromHex(
  '3059301306072a8648ce3d020106082a8648ce3d03010703420004',
);

/// Egy P-256 kulcspár rögzített titkos skalárból.
final class TestKey {
  /// Kulcs a [privateHex] skalárral (kisebb a görbe rendjénél).
  TestKey(String privateHex) : _d = BigInt.parse(privateHex, radix: 16);

  final BigInt _d;

  /// A nyilvános kulcs SubjectPublicKeyInfo DER-je (91 bájt).
  Uint8List get spki {
    // A generátor többszöröse egy 1 és n közti skalárra soha nem a végtelen
    // pont, ezért a koordináták léteznek.
    final point = (_domain.G * _d)!;
    return Uint8List.fromList([
      ..._spkiPrefix,
      ..._fixed32(point.x!.toBigInteger()!),
      ..._fixed32(point.y!.toBigInteger()!),
    ]);
  }

  /// A [message] ES256 aláírása DER-ben.
  Uint8List sign(List<int> message) {
    final key = PrivateKeyParameter<ECPrivateKey>(ECPrivateKey(_d, _domain));
    final signer = ECDSASigner(SHA256Digest(), HMac(SHA256Digest(), 64))
      ..init(true, key);
    final signature =
        signer.generateSignature(Uint8List.fromList(message)) as ECSignature;
    final r = _derInteger(signature.r);
    final s = _derInteger(signature.s);
    return Uint8List.fromList([0x30, r.length + s.length, ...r, ...s]);
  }
}

/// Egy telefon a két kulcsával (Addendum 3 K1).
final class TestPhone {
  /// Telefon az aláíró és az eszközkulcs skalárjával.
  TestPhone({required String signingKeyHex, required String deviceKeyHex})
    : signingKey = TestKey(signingKeyHex),
      deviceKey = TestKey(deviceKeyHex);

  /// Az első telefon (az `owner`-é a legtöbb tesztben).
  factory TestPhone.first() => TestPhone(
    signingKeyHex:
        'c9afa9d845ba75166b5c215767b1d6934e50c3db36e89b127b8a622b120f6721',
    deviceKeyHex:
        '0f56db78ca460b055c500064824bed999a25aaf48ebb519ac201537b85479813',
  );

  /// Egy másik telefon.
  factory TestPhone.second() => TestPhone(
    signingKeyHex:
        '3b8f2a64c1d7e9051a6c8e2f4b7d9a0c3e5f7a9b1c3d5e7f9a1b3c5d7e9f1a2b',
    deviceKeyHex:
        '5d4c3b2a19087f6e5d4c3b2a19087f6e5d4c3b2a19087f6e5d4c3b2a19087f6e',
  );

  /// Az ujjlenyomatos aláíró kulcs.
  final TestKey signingKey;

  /// A csendes eszközkulcs.
  final TestKey deviceKey;
}

List<int> _derInteger(BigInt value) {
  var bytes = _unsigned(value);
  // A felső bit 1 negatív számot jelentene, ezért vezető nulla kell.
  if (bytes.first & 0x80 != 0) bytes = [0, ...bytes];
  return [0x02, bytes.length, ...bytes];
}

List<int> _unsigned(BigInt value) {
  final bytes = <int>[];
  var rest = value;
  while (rest > BigInt.zero) {
    bytes.insert(0, (rest & BigInt.from(0xFF)).toInt());
    rest = rest >> 8;
  }
  return bytes.isEmpty ? [0] : bytes;
}

List<int> _fixed32(BigInt value) {
  final bytes = _unsigned(value);
  return [...List.filled(32 - bytes.length, 0), ...bytes];
}

List<int> _fromHex(String hex) => [
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
];
