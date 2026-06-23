// A PolarRepository szándékos DIP-seam: egyetlen metódusa van, de
// interfésznek KELL maradnia (data-impl + provider-override teszthez), a
// one_member_abstracts top-level-függvény javaslata itt nem alkalmazható.
// ignore_for_file: one_member_abstracts

import 'package:domain/src/entities/polar.dart';
import 'package:meta/meta.dart';
import 'package:shared/shared.dart';

/// A polárdiagram betöltésének absztrakciója (DIP).
///
/// A domain a [Polar]-t egy absztrakt forráson keresztül kéri, nem
/// ismeri a konkrét tárolást (bundled asset, fájl-import vagy DB). A v1
/// implementáció az `AssetPolarRepository` a data-rétegben: a
/// `foretack.pol` fordításidős assetet tölti (ADR 0028 Addendum 2
/// B1/B2). A későbbi fájl-import út drop-in csere e mögött, az interfész
/// változatlanul hagyásával (OCP/DIP).
///
/// A betöltés [Result]-ot ad: a `.pol`-fájl untrusted bemenet, ezért a
/// hibás tartalom várt eset ([Err] [PolarLoadError]-ral), nem dobott
/// kivétel.
abstract interface class PolarRepository {
  /// Betölti és parse-olja a polárt. Sikeres parse-nál [Ok] a kész
  /// [Polar]-ral; hibánál [Err] a [PolarLoadError] megfelelő ágával.
  Future<Result<Polar, PolarLoadError>> loadPolar();
}

/// Miért nem tölthető be a polár [Polar]-rá.
///
/// Sealed (nem enum, szemben az NMEA `ParseError`-ral), mert van
/// fogyasztója: a 3. szelet `PolarMissing` warningja a konkrét okra
/// ágazhat, és a debug-log a `toString`-ből lokalizálja a hibát.
@immutable
sealed class PolarLoadError {
  /// Csak a leaf-ek hívják.
  const PolarLoadError();
}

/// Az asset (vagy forrás-fájl) nem érhető el (hiányzik a bundle-ből,
/// vagy a betöltés más okból elbukott).
@immutable
final class PolarAssetMissing extends PolarLoadError {
  /// Konstans példány — nincs payload.
  const PolarAssetMissing();

  @override
  String toString() => 'PolarAssetMissing()';
}

/// A forrás üres vagy csak whitespace.
@immutable
final class PolarEmpty extends PolarLoadError {
  /// Konstans példány — nincs payload.
  const PolarEmpty();

  @override
  String toString() => 'PolarEmpty()';
}

/// A fejléc hibás: nem a `twa/tws` prefix, nincs érvényes TWS-tengely,
/// vagy a TWS-ek nem szigorúan növekvők.
@immutable
final class PolarMalformedHeader extends PolarLoadError {
  /// Konstans példány — nincs payload.
  const PolarMalformedHeader();

  @override
  String toString() => 'PolarMalformedHeader()';
}

/// Egy adatsor hibás (rossz mezőszám, nem-szám érték, tartományon kívüli
/// vagy nem növekvő TWA).
@immutable
final class PolarMalformedRow extends PolarLoadError {
  /// Hibás sor: [lineNumber] az 1-alapú fájl-sorszám (ahogy a
  /// szövegszerkesztő mutatja), [reason] az ember-olvasható ok.
  const PolarMalformedRow({required this.lineNumber, required this.reason});

  /// 1-alapú fájl-sorszám (az üres sorok átugrásával is a tényleges
  /// fájlbeli sort hivatkozza).
  final int lineNumber;

  /// Az ember-olvasható hibaok (debug-log/diagnosztika).
  final String reason;

  @override
  String toString() => 'PolarMalformedRow(line: $lineNumber, $reason)';
}

/// A parse formailag sikerült, de egyetlen használható (nem-null) cella
/// sincs — a polár sehol nem ad targetet.
@immutable
final class PolarNoUsableCells extends PolarLoadError {
  /// Konstans példány — nincs payload.
  const PolarNoUsableCells();

  @override
  String toString() => 'PolarNoUsableCells()';
}
