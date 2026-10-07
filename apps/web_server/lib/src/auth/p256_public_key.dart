import 'dart:typed_data';

import 'package:equatable/equatable.dart';

// Egy P-256 (secp256r1) nyilvános kulcs SubjectPublicKeyInfo DER-jének
// rögzített eleje: SEQUENCE { SEQUENCE { id-ecPublicKey, prime256v1 },
// BIT STRING 0x00 0x04 }. A tömörítetlen pont X és Y koordinátája követi.
// Az Android Keystore pontosan ezt adja (Addendum 1 H5).
final Uint8List _spkiPrefix = _fromHex(
  '3059301306072a8648ce3d020106082a8648ce3d03010703420004',
);
const int _coordinateLength = 32;
const int _spkiLength = 91;

// A P-256 görbe paraméterei (SEC 2, FIPS 186-4): y² = x³ + a·x + b mod p.
final BigInt _p = BigInt.parse(
  'ffffffff00000001000000000000000000000000ffffffffffffffffffffffff',
  radix: 16,
);
final BigInt _a = _p - BigInt.from(3);
final BigInt _b = BigInt.parse(
  '5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b',
  radix: 16,
);

/// Egy eszköz P-256 nyilvános kulcsa (ADR 0051 D4, Addendum 1 H5).
///
/// Csak a [tryParse] hozza létre, így minden példány érvényes, a görbén
/// fekvő pont.
final class P256PublicKey extends Equatable {
  const P256PublicKey._(this.x, this.y, this._spki);

  /// A pont X koordinátája.
  final BigInt x;

  /// A pont Y koordinátája.
  final BigInt y;

  final Uint8List _spki;

  /// A kulcs SubjectPublicKeyInfo DER-alakja (91 bájt), másolatként.
  Uint8List get spki => Uint8List.fromList(_spki);

  /// A [der] mint P-256 SubjectPublicKeyInfo, vagy `null`, ha nem az.
  ///
  /// Szigorú: csak a pontos 91 bájtos, tömörítetlen pontú alakot fogadja
  /// el (más görbét, RSA-t, tömörített pontot nem), és ellenőrzi, hogy a
  /// pont a görbén van. Egy hibás kulcs így már a regisztrációnál elakad.
  static P256PublicKey? tryParse(List<int> der) {
    if (der.length != _spkiLength) return null;
    for (var i = 0; i < _spkiPrefix.length; i++) {
      if (der[i] != _spkiPrefix[i]) return null;
    }
    final x = _unsigned(der, _spkiPrefix.length);
    final y = _unsigned(der, _spkiPrefix.length + _coordinateLength);
    if (!_isOnCurve(x, y)) return null;
    return P256PublicKey._(x, y, Uint8List.fromList(der));
  }

  @override
  List<Object?> get props => [x, y];

  static BigInt _unsigned(List<int> bytes, int offset) {
    var value = BigInt.zero;
    for (var i = offset; i < offset + _coordinateLength; i++) {
      value = (value << 8) | BigInt.from(bytes[i]);
    }
    return value;
  }

  // A kofaktor 1, ezért a görbén fekvő, nem végtelen pont egyben a
  // részcsoport eleme is.
  static bool _isOnCurve(BigInt x, BigInt y) {
    if (x >= _p || y >= _p) return false;
    final left = (y * y) % _p;
    final right = (x * x * x + _a * x + _b) % _p;
    return left == right;
  }
}

Uint8List _fromHex(String hex) => Uint8List.fromList([
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
]);
