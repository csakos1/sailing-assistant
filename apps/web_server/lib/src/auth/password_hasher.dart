import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' show SecretKey;
import 'package:cryptography/dart.dart' show DartArgon2id;
import 'package:equatable/equatable.dart';
import 'package:web_server/src/auth/constant_time.dart';
import 'package:web_server/src/auth/random_bytes.dart';

const int _saltLength = 16;
const int _hashLength = 32;
const int _argon2Version = 19;
final RegExp _parameterPattern = RegExp(r'^m=(\d+),t=(\d+),p=(\d+)$');

/// Az argon2id költség-paraméterei (ADR 0051 D6, Addendum 2 J4).
final class PasswordHashParameters extends Equatable {
  /// Paraméterek: [memoryKiB] memória, [iterations] menet, [parallelism]
  /// sáv.
  const PasswordHashParameters({
    required this.memoryKiB,
    required this.iterations,
    required this.parallelism,
  });

  /// Az OWASP ajánlása (19 MiB, 2 menet, 1 sáv); a VPS-en mérendő (S8).
  static const PasswordHashParameters recommended = PasswordHashParameters(
    memoryKiB: 19456,
    iterations: 2,
    parallelism: 1,
  );

  /// A felhasznált memória KiB-ban.
  final int memoryKiB;

  /// A menetek száma.
  final int iterations;

  /// A párhuzamos sávok száma.
  final int parallelism;

  // Egy sérült vagy hamisított DB-sor ne foglalhasson le a szerveren
  // korlátlan memóriát vagy időt.
  bool get _isWithinLimits =>
      parallelism >= 1 &&
      parallelism <= 4 &&
      memoryKiB >= 8 * parallelism &&
      memoryKiB <= 262144 &&
      iterations >= 1 &&
      iterations <= 10;

  @override
  List<Object?> get props => [memoryKiB, iterations, parallelism];
}

/// A tartalék-jelszó hash-elése és ellenőrzése argon2id-vel (ADR 0051 D6).
///
/// A tárolt alak a szabványos PHC-szöveg
/// (`$argon2id$v=19$m=…,t=…,p=…$<só>$<hash>`), így a paraméterek a hash
/// mellett utaznak: később szigoríthatók, és a régi hash-ek is
/// ellenőrizhetők maradnak.
final class PasswordHasher {
  /// Hash-elő a [parameters] költséggel és a [randomBytes] sóval.
  const PasswordHasher({
    required RandomBytes randomBytes,
    this.parameters = PasswordHashParameters.recommended,
  }) : _randomBytes = randomBytes;

  /// Az új hash-ek költsége.
  final PasswordHashParameters parameters;

  final RandomBytes _randomBytes;

  /// A [password] PHC-alakú argon2id-hash-e, friss sóval.
  Future<String> hash(String password) async {
    final salt = _randomBytes(_saltLength);
    final digest = await _derive(password, salt, parameters, _hashLength);
    final cost =
        'm=${parameters.memoryKiB},t=${parameters.iterations},'
        'p=${parameters.parallelism}';
    return [
      '',
      'argon2id',
      'v=$_argon2Version',
      cost,
      _encode(salt),
      _encode(digest),
    ].join(r'$');
  }

  /// Egyezik-e a [password] az [encoded] PHC-hash-sel.
  ///
  /// Egy nem értelmezhető vagy a korlátokon kívüli [encoded] nem egyezik:
  /// a hívó ugyanúgy kezeli, mint a rossz jelszót.
  Future<bool> verify(String password, String encoded) async {
    final stored = _parse(encoded);
    if (stored == null) return false;
    final digest = await _derive(
      password,
      stored.salt,
      stored.parameters,
      stored.digest.length,
    );
    return constantTimeEquals(digest, stored.digest);
  }
}

typedef _StoredHash = ({
  PasswordHashParameters parameters,
  Uint8List salt,
  Uint8List digest,
});

_StoredHash? _parse(String encoded) {
  final parts = encoded.split(r'$');
  final isWellFormed =
      parts.length == 6 &&
      parts[0].isEmpty &&
      parts[1] == 'argon2id' &&
      parts[2] == 'v=$_argon2Version';
  if (!isWellFormed) return null;
  final match = _parameterPattern.firstMatch(parts[3]);
  // Nem egyező alaknál vagy egy int-be nem férő számjegysornál null.
  final memory = int.tryParse(match?.group(1) ?? '');
  final iterations = int.tryParse(match?.group(2) ?? '');
  final parallelism = int.tryParse(match?.group(3) ?? '');
  if (memory == null || iterations == null || parallelism == null) {
    return null;
  }
  final parameters = PasswordHashParameters(
    memoryKiB: memory,
    iterations: iterations,
    parallelism: parallelism,
  );
  final salt = _decode(parts[4]);
  final digest = _decode(parts[5]);
  final isUsable =
      parameters._isWithinLimits &&
      salt != null &&
      salt.length >= 8 &&
      salt.length <= 64 &&
      digest != null &&
      digest.length >= 16 &&
      digest.length <= 64;
  if (!isUsable) return null;
  return (parameters: parameters, salt: salt, digest: digest);
}

Future<Uint8List> _derive(
  String password,
  List<int> salt,
  PasswordHashParameters parameters,
  int length,
) async {
  final algorithm = DartArgon2id(
    parallelism: parameters.parallelism,
    memory: parameters.memoryKiB,
    iterations: parameters.iterations,
    hashLength: length,
  );
  final key = await algorithm.deriveKey(
    secretKey: SecretKey(utf8.encode(password)),
    nonce: salt,
  );
  return Uint8List.fromList(await key.extractBytes());
}

// A PHC-alak a szabványos base64 ábécét használja, kitöltés nélkül.
String _encode(List<int> bytes) => base64.encode(bytes).replaceAll('=', '');

Uint8List? _decode(String text) {
  if (text.isEmpty || text.length % 4 == 1) return null;
  try {
    return base64.decode(text.padRight((text.length + 3) ~/ 4 * 4, '='));
  } on FormatException {
    return null;
  }
}
