import 'package:flutter/foundation.dart';
import 'package:shared/shared.dart';

/// Miért nem sikerült egy kulcsművelet (ADR 0051 Addendum 1 H5, Addendum
/// 8 V4).
enum KeyOperationFailure {
  /// A felhasználó elvetette az ujjlenyomat-ablakot.
  canceled,

  /// A kulcs nincs meg, vagy érvénytelenné vált (pl. a képernyőzár
  /// törlése után).
  keyMissing,

  /// Nincs beállított ujjlenyomat, vagy a telefon nem tud biometriát.
  unavailable,

  /// Túl sok sikertelen próbálkozás miatt a biometria zárolva.
  lockedOut,

  /// Más, váratlan hiba.
  failed,
}

/// A telefon két webes kulcsa (Addendum 3 K1).
enum WebKeyRole {
  /// Az aláíró kulcs: minden aláíráshoz ujjlenyomat kell.
  signing,

  /// A csendes eszközkulcs: az eszköz-tokenhez, ujjlenyomat nélkül.
  device,
}

/// Az ujjlenyomat-ablak szövegei (H6).
@immutable
class BiometricPromptText {
  /// Ablak a [title] címmel, a [subtitle] alcímmel és a [cancel]
  /// gombfelirattal.
  const BiometricPromptText({
    required this.title,
    required this.cancel,
    this.subtitle,
  });

  /// A cím (pl. „Belépés a Foretack webre").
  final String title;

  /// Az alcím (pl. a kérő böngésző és helye), ha van.
  final String? subtitle;

  /// A megszakító gomb felirata.
  final String cancel;
}

/// Egy kulcspár létrehozása (a régit felülírva); az eredmény a nyilvános
/// kulcs SubjectPublicKeyInfo DER-je.
typedef CreateWebKey =
    Future<Result<Uint8List, KeyOperationFailure>> Function(WebKeyRole role);

/// Aláírás az aláíró kulccsal, ujjlenyomattal; az eredmény DER aláírás.
typedef SignWithBiometrics =
    Future<Result<Uint8List, KeyOperationFailure>> Function(
      Uint8List message,
      BiometricPromptText prompt,
    );

/// Aláírás a csendes eszközkulccsal; az eredmény DER aláírás.
typedef SignSilently =
    Future<Result<Uint8List, KeyOperationFailure>> Function(
      Uint8List message,
    );

/// Mindkét webes kulcs törlése; ha nincsenek, nem hiba.
typedef DeleteWebKeys = Future<void> Function();

/// A webes kulcsműveletek egy csomagban (V4).
///
/// Függvényekből áll, nem interfészből: a folyamatok így Keystore nélkül,
/// tesztben egy hamis aláíróval is futnak (D13), és az éles megvalósítás
/// egyetlen adapter a `biometric_signature` fölött.
@immutable
class WebKeyOperations {
  /// Kulcsműveletek a megadott függvényekkel.
  const WebKeyOperations({
    required this.createKey,
    required this.signWithBiometrics,
    required this.signSilently,
    required this.deleteKeys,
  });

  /// Kulcspár létrehozása.
  final CreateWebKey createKey;

  /// Aláírás ujjlenyomattal.
  final SignWithBiometrics signWithBiometrics;

  /// Csendes aláírás az eszközkulccsal.
  final SignSilently signSilently;

  /// Mindkét kulcs törlése.
  final DeleteWebKeys deleteKeys;
}
