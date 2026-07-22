import 'package:flutter/foundation.dart';

/// A track-kép exportjának hibaágai (ADR 0036 A1-D7).
///
/// Szándékosan `Result`-tal utaznak, nem kivételként: mindhárom eset VÁRT
/// üzemzavar egy telefonon — a raszterizálás elbukhat memóriahiányon, a
/// temp könyvtár tele lehet, a share sheetet a rendszer megtagadhatja. A
/// hívó kimerítő `switch`-csel kezeli, ágonként külön üzenettel; nincs
/// újrapróbálkozás és nincs csendes elnyelés.
///
/// A `cause` mező csak diagnosztika: a felhasználónak sosem mutatjuk,
/// naplózni viszont érdemes, mert a hiba a vízparton derül ki.
@immutable
sealed class TrackExportError {
  /// Csak a leszármazottak hívják.
  const TrackExportError(this.cause);

  /// Az eredeti hiba, ami az ágat kiváltotta.
  final Object cause;

  /// Az ág stabil neve a naplóhoz.
  ///
  /// Nem a `runtimeType`, mert azt a release-build minifikálhatja, és a
  /// napló pont akkor válna olvashatatlanná, amikor a legjobban kell.
  String get label;

  @override
  String toString() => '$label($cause)';
}

/// A látható nézet raszterizálása nem sikerült.
final class CaptureFailed extends TrackExportError {
  /// A capture vagy a vászon-kompozíció hibáját csomagolja.
  const CaptureFailed(super.cause);

  @override
  String get label => 'CaptureFailed';
}

/// A kész PNG nem volt kiírható a temp könyvtárba.
final class StorageUnavailable extends TrackExportError {
  /// A fájlrendszer hibáját csomagolja.
  const StorageUnavailable(super.cause);

  @override
  String get label => 'StorageUnavailable';
}

/// A rendszer megosztó-felülete nem indult el.
final class ShareFailed extends TrackExportError {
  /// A megosztó-plugin hibáját csomagolja.
  const ShareFailed(super.cause);

  @override
  String get label => 'ShareFailed';
}
