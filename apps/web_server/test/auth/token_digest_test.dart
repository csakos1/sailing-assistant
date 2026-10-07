import 'package:test/test.dart';
import 'package:web_server/src/auth/random_bytes.dart';
import 'package:web_server/src/auth/token_digest.dart';

void main() {
  group('digestToken', () {
    test('is the SHA-256 of the UTF-8 token', () {
      // FIPS 180-2 peldaja: SHA-256("abc").
      final hex = [
        for (final byte in digestToken('abc'))
          byte.toRadixString(16).padLeft(2, '0'),
      ].join();

      expect(
        hex,
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });
  });

  group('secureRandomBytes', () {
    test('returns the requested number of bytes, different each time', () {
      final first = secureRandomBytes(32);
      final second = secureRandomBytes(32);

      expect(first, hasLength(32));
      expect(first, isNot(second));
    });
  });
}
