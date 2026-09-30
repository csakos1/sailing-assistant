import 'package:equatable/equatable.dart';

/// A szerkesztőben kitölthető eredmény-adatok (ADR 0047 D7).
///
/// Minden mező opcionális: egy részben ismert eredmény (pl. csak az
/// abszolút helyezés) is rögzíthető. A validációt a
/// `ValidateRaceAnnotationInput` végzi; ez az osztály csak hordoz.
final class RaceAnnotationInput extends Equatable {
  /// Eredmény-adatok; a hiányzó mező `null`.
  const RaceAnnotationInput({
    this.overallPlace,
    this.overallFleetSize,
    this.classPlace,
    this.classFleetSize,
    this.summary,
  });

  /// Abszolút helyezés.
  final int? overallPlace;

  /// Az abszolút mezőny mérete.
  final int? overallFleetSize;

  /// Osztályhelyezés.
  final int? classPlace;

  /// Az osztálymezőny mérete.
  final int? classFleetSize;

  /// A verseny szöveges összefoglalója (sima, többsoros szöveg).
  final String? summary;

  /// Igaz, ha egyetlen mező sincs kitöltve — a `PUT` ilyenkor töröl
  /// (Addendum 1 A5), a részletező pedig az üres állapotot mutatja.
  bool get isEmpty =>
      overallPlace == null &&
      overallFleetSize == null &&
      classPlace == null &&
      classFleetSize == null &&
      summary == null;

  @override
  List<Object?> get props => [
    overallPlace,
    overallFleetSize,
    classPlace,
    classFleetSize,
    summary,
  ];
}
