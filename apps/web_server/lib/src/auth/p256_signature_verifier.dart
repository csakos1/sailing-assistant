import 'dart:typed_data';

import 'package:pointycastle/api.dart' show PublicKeyParameter;
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/secp256r1.dart';
import 'package:pointycastle/signers/ecdsa_signer.dart';
import 'package:web_server/src/auth/der_ecdsa_signature.dart';
import 'package:web_server/src/auth/p256_public_key.dart';

final ECCurve_secp256r1 _domain = ECCurve_secp256r1();

/// Érvényes-e a [derSignature] ES256 (ECDSA P-256 + SHA-256) aláírás a
/// [message]-re a [publicKey]-jel (ADR 0051 D4, Addendum 2 J9).
///
/// A hibás kódolású aláírás egyszerűen érvénytelen: a hívó nem tudja és
/// nem is kell tudnia, miért nem ment át.
bool verifyP256Signature({
  required P256PublicKey publicKey,
  required List<int> message,
  required List<int> derSignature,
}) {
  final values = parseDerEcdsaSignature(derSignature);
  if (values == null) return false;
  final point = _domain.curve.createPoint(publicKey.x, publicKey.y);
  final key = PublicKeyParameter<ECPublicKey>(ECPublicKey(point, _domain));
  final signer = ECDSASigner(SHA256Digest())..init(false, key);
  return signer.verifySignature(
    Uint8List.fromList(message),
    ECSignature(values.r, values.s),
  );
}
