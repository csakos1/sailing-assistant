import 'dart:typed_data';

import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/auth/constant_time.dart';
import 'package:web_server/src/auth/p256_public_key.dart';

/// Már regisztrált (vagy egy függő kérelemben szereplő) kulcs (ADR 0051
/// Addendum 4 L3, L5).
const ApiError keysInUseError = MalformedRequest(
  DecodeError(path: r'$.publicKey', expected: 'keys not yet registered'),
);

const ApiError _invalidPublicKey = MalformedRequest(
  DecodeError(path: r'$.publicKey', expected: 'P-256 SubjectPublicKeyInfo'),
);

const ApiError _invalidDeviceKey = MalformedRequest(
  DecodeError(
    path: r'$.deviceKey',
    expected: 'P-256 SubjectPublicKeyInfo other than publicKey',
  ),
);

/// Egy új telefon két kulcsának alakja (Addendum 3 K1, Addendum 4 L5): az
/// aláíró kulcs, ha mindkettő P-256 SubjectPublicKeyInfo és a kettő
/// különbözik; különben a hiba.
///
/// Az egyediséget a DB-ben a hívó nézi, ez csak az alak.
Result<P256PublicKey, ApiError> parseNewDeviceKeys({
  required Uint8List publicKey,
  required Uint8List deviceKey,
}) {
  final signingKey = P256PublicKey.tryParse(publicKey);
  if (signingKey == null) return const Err(_invalidPublicKey);
  if (P256PublicKey.tryParse(deviceKey) == null ||
      constantTimeEquals(publicKey, deviceKey)) {
    return const Err(_invalidDeviceKey);
  }
  return Ok(signingKey);
}
