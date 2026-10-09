import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:web_server/src/auth/password_hasher.dart';

// Pythonnal (cryptography.hazmat ... Argon2id, salt=b'0123456789abcdef',
// length=32, iterations=1, lanes=1, memory_cost=64) keszult vektor; a
// tesztek kis koltseggel futnak, hogy gyorsak maradjanak.
const PasswordHashParameters _cheap = PasswordHashParameters(
  memoryKiB: 64,
  iterations: 1,
  parallelism: 1,
);
const String _password = 'jelszó jelszó';
const String _encoded =
    r'$argon2id$v=19$m=64,t=1,p=1$MDEyMzQ1Njc4OWFiY2RlZg'
    r'$fOAooK4Z7pk5GjvBYYLhUMipN00kknFtRJja4PqJiOE';

PasswordHasher _hasher() => PasswordHasher(
  randomBytes: (length) =>
      Uint8List.fromList(utf8.encode('0123456789abcdef').take(length).toList()),
  parameters: _cheap,
);

void main() {
  group('PasswordHasher', () {
    test('hashes to the standard argon2id PHC string', () async {
      expect(await _hasher().hash(_password), _encoded);
    });

    test('verifies the right password against the stored hash', () async {
      expect(await _hasher().verify(_password, _encoded), isTrue);
    });

    test('rejects a wrong password', () async {
      expect(await _hasher().verify('jelszo jelszo', _encoded), isFalse);
    });

    test('verifies with the parameters stored in the hash', () async {
      // Az uj hash-ek koltsege kozben no: a regi hash a sajat
      // parametereivel ellenorzodik.
      const stronger = PasswordHasher(
        randomBytes: Uint8List.new,
        parameters: PasswordHashParameters(
          memoryKiB: 128,
          iterations: 2,
          parallelism: 1,
        ),
      );

      expect(await stronger.verify(_password, _encoded), isTrue);
    });

    final unusable = <String, String>{
      'another algorithm': _encoded.replaceFirst('argon2id', 'argon2i'),
      'another version': _encoded.replaceFirst('v=19', 'v=16'),
      'too much memory': _encoded.replaceFirst('m=64', 'm=999999'),
      'a huge number': _encoded.replaceFirst('m=64', 'm=${'9' * 30}'),
      'a missing part': _encoded.substring(0, _encoded.lastIndexOf(r'$')),
      'a broken salt': _encoded.replaceFirst('MDEy', 'M!Ey'),
      'an empty string': '',
    };
    for (final MapEntry(key: description, value: encoded) in unusable.entries) {
      test('treats a hash with $description as no match', () async {
        expect(await _hasher().verify(_password, encoded), isFalse);
      });
    }
  });
}
