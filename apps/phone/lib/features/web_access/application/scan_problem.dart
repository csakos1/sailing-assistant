import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/data/web_api_failure.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Milyen kódot olvasott be a telefon: a lejárt kód panelje ettől
/// függően mondja, honnan jön az új (ADR 0051 Addendum 9 X2).
enum ScanKind {
  /// Belépési QR egy regisztrált telefonon.
  login,

  /// Regisztrációs (CLI-s) QR.
  enrollment,

  /// Belépési QR egy fiók nélküli telefonon: csatlakozás.
  join,
}

/// Amit a beolvasó alsó hibapanelje mond (ADR 0051 Addendum 1 H7, makett
/// 18d-2…5, Addendum 8 V5–V6).
@immutable
sealed class ScanProblem {
  const ScanProblem();
}

/// Nem Foretack-kód, vagy hibás tartalmú Foretack-kód.
final class NotForetackCode extends ScanProblem {
  const NotForetackCode();
}

/// Foretack-kód, de ezt egy újabb app érti (J2).
final class UnsupportedCode extends ScanProblem {
  const UnsupportedCode();
}

/// Lejárt vagy már felhasznált kérés (18d-2).
final class ExpiredCode extends ScanProblem {
  /// Lejárt kód; a [kind] mondja, milyen kód volt.
  const ExpiredCode({this.kind = ScanKind.login});

  /// A kód fajtája: a regisztrációs kódhoz az újat a szerveren kell kérni,
  /// a csatlakozásnál a beírt név megmarad (X2).
  final ScanKind kind;
}

/// Egy másik szerver belépési QR-ja (18d-3).
final class ForeignServer extends ScanProblem {
  /// A beolvasott kód szerverének [host]-ja.
  const ForeignServer(this.host);

  /// A kód szerverének hostja, monóval mutatva.
  final String host;
}

/// A szerver nem érhető el, vagy érthetetlen választ adott (18d-4).
final class NoConnection extends ScanProblem {
  const NoConnection();
}

/// Túl sok próbálkozás; [minutes] perc múlva lehet újra.
final class TooManyAttemptsProblem extends ScanProblem {
  /// Várakozás [minutes] percig (legalább 1).
  const TooManyAttemptsProblem(this.minutes);

  /// A várakozás percben, felfelé kerekítve.
  final int minutes;
}

/// A telefon vissza lett vonva, vagy a kulcsa elveszett (18d-5).
final class DeviceRevokedProblem extends ScanProblem {
  /// Visszavont eszköz; az [isOwner] dönti el, mit kínál a panel (H7).
  const DeviceRevokedProblem({required this.isOwner});

  /// A tulajdonos telefonja-e: neki csak a CLI-s újraregisztráció marad.
  final bool isOwner;
}

/// Nincs beállított ujjlenyomat, vagy a telefon nem tud biometriát.
final class BiometricsUnavailable extends ScanProblem {
  const BiometricsUnavailable();
}

/// Túl sok sikertelen ujjlenyomat-próba miatt a biometria zárolva.
final class BiometricsLockedOut extends ScanProblem {
  const BiometricsLockedOut();
}

/// Az aláírás váratlanul nem sikerült.
final class SigningFailed extends ScanProblem {
  const SigningFailed();
}

/// Egy folyamat [error] hibája → a panel, vagy `null`, ha a felhasználó
/// maga vetette el az ujjlenyomat-ablakot (csendes bezárás, H6).
///
/// Az [isOwner] a visszavont-panelhez, a [kind] a lejárt kód szövegéhez
/// kell. A `NotAuthenticated` is
/// visszavonásnak számít: egy újrakért eszköz-token után ez azt jelenti,
/// hogy a szerver nem fogadja el a telefon kulcsát.
ScanProblem? scanProblemOf(
  WebAccessError error, {
  required bool isOwner,
  ScanKind kind = ScanKind.login,
}) => switch (error) {
  ApiCallFailed(:final failure) => _apiProblemOf(
    failure,
    isOwner: isOwner,
    kind: kind,
  ),
  KeyOperationFailed(:final failure) => switch (failure) {
    KeyOperationFailure.canceled => null,
    KeyOperationFailure.keyMissing => DeviceRevokedProblem(
      isOwner: isOwner,
    ),
    KeyOperationFailure.unavailable => const BiometricsUnavailable(),
    KeyOperationFailure.lockedOut => const BiometricsLockedOut(),
    KeyOperationFailure.failed => const SigningFailed(),
  },
};

ScanProblem _apiProblemOf(
  WebApiFailure failure, {
  required bool isOwner,
  required ScanKind kind,
}) => switch (failure) {
  WebServerFailure(error: RequestExpired()) => ExpiredCode(kind: kind),
  WebServerFailure(error: DeviceRevoked() || NotAuthenticated()) =>
    DeviceRevokedProblem(isOwner: isOwner),
  WebServerFailure(error: TooManyAttempts(:final retryAfterSeconds)) =>
    TooManyAttemptsProblem(minutesToWait(retryAfterSeconds)),
  // Minden más szerverhiba és az olvashatatlan válasz is 18d-4 (V6).
  WebServerFailure() ||
  WebNetworkFailure() ||
  WebUnreadableResponse() => const NoConnection(),
};

/// A [seconds] várakozás percben, felfelé kerekítve, legalább 1 (H10).
int minutesToWait(int seconds) => max(1, (seconds + 59) ~/ 60);
