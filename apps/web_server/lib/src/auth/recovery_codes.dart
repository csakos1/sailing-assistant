import 'package:web_server/src/auth/random_bytes.dart';

/// Ennyi helyreállító kód készül egyszerre (ADR 0051 D6).
const int recoveryCodeCount = 10;

// RFC 4648 base32: nagybetűk és 2–7, így nincs 0/O és 1/I keveredés.
const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
const int _codeLength = 10;
final RegExp _separators = RegExp(r'[\s-]');

/// [recoveryCodeCount] új, egymástól különböző helyreállító kód
/// `XXXXX-XXXXX` alakban (ADR 0051 D6).
///
/// Karakterenként egy véletlen bájt alsó 5 bitje: a 256 osztható 32-vel,
/// így minden karakter egyenletes eloszlású, kódonként 50 bit.
List<String> generateRecoveryCodes(RandomBytes randomBytes) {
  final codes = <String>{};
  while (codes.length < recoveryCodeCount) {
    final bytes = randomBytes(_codeLength);
    final characters = [for (final byte in bytes) _alphabet[byte & 0x1F]];
    codes.add('${characters.take(5).join()}-${characters.skip(5).join()}');
  }
  return codes.toList();
}

/// A begépelt [input] mint helyreállító kód, egységes alakban (10
/// nagybetűs base32 karakter, kötőjel nélkül), vagy `null`, ha nem az.
///
/// Elnézi a kisbetűt, a szóközt és a kötőjelet, mert a kódot a felhasználó
/// papírról gépeli be.
String? normalizeRecoveryCode(String input) {
  final code = input.toUpperCase().replaceAll(_separators, '');
  if (code.length != _codeLength) return null;
  for (final character in code.split('')) {
    if (!_alphabet.contains(character)) return null;
  }
  return code;
}
