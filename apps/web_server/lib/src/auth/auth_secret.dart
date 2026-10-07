import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:shared/shared.dart';

/// A titok-fájl legkisebb mérete bájtban (256 bit).
const int minimumAuthSecretLength = 32;

// A HMAC-üzenet tartomány-előtagja: ha a titok később más célra is kell,
// a két felhasználás kimenete nem keveredhet.
const String _recoveryCodeDomain = 'foretack-recovery-v1\n';

/// A szerveroldali titok (ADR 0051 D6, D10): a VPS-en egy `0600`-s
/// fájlban, sem a DB-ben, sem a repóban nincs.
///
/// A helyreállító kódokat ezzel HMAC-elve tároljuk: egy kiszivárgott
/// `auth.sqlite`-ból a titok nélkül a kódok nem próbálgathatók.
final class AuthSecret {
  AuthSecret._(this._key);

  final Uint8List _key;

  /// A már egységesített (`normalizeRecoveryCode`) [code] HMAC-SHA-256-ja.
  Uint8List digestRecoveryCode(String code) => Uint8List.fromList(
    Hmac(sha256, _key).convert(utf8.encode('$_recoveryCodeDomain$code')).bytes,
  );

  // A titok soha nem kerülhet naplóba vagy hibaüzenetbe.
  @override
  String toString() => 'AuthSecret(…)';
}

/// Miért nem tölthető be a titok-fájl.
enum AuthSecretError {
  /// A fájl nem létezik vagy nem olvasható.
  unreadable,

  /// A fájl a tulajdonosán kívül másnak is olvasható (nem `0600`).
  tooPermissive,

  /// A fájl [minimumAuthSecretLength] bájtnál rövidebb.
  tooShort,
}

/// A [file] titok-fájl betöltése (ADR 0051 D10, Addendum 2 J6).
///
/// A tartalom nyers bájt, például
/// `(umask 077; head -c 64 /dev/urandom > auth-secret)`. A csoport és
/// mások jogait nem engedi: egy véletlenül olvashatóvá tett titok a
/// szerver indulását állítja meg, nem csendben fut tovább.
Future<Result<AuthSecret, AuthSecretError>> loadAuthSecret(File file) async {
  final FileStat stat;
  final Uint8List bytes;
  try {
    stat = file.statSync();
    if (stat.type != FileSystemEntityType.file) {
      return const Err(AuthSecretError.unreadable);
    }
    bytes = await file.readAsBytes();
  } on FileSystemException {
    return const Err(AuthSecretError.unreadable);
  }
  if (stat.mode & 0x3F != 0) return const Err(AuthSecretError.tooPermissive);
  if (bytes.length < minimumAuthSecretLength) {
    return const Err(AuthSecretError.tooShort);
  }
  return Ok(AuthSecret._(bytes));
}
