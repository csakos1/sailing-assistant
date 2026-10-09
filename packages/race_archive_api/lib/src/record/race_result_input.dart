import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/record/placing.dart';

/// Egy verseny szerkeszthető eredménye (ADR 0048 D3).
///
/// Mindkét versenyfajtán ugyanaz. Minden mező opcionális: egy részben
/// ismert eredmény (pl. csak az abszolút pár) is rögzíthető. A helyezések
/// a saját mezőnyükkel párban állnak. A validációt a
/// `ValidateRaceResultInput` végzi; ez az osztály csak hordoz.
final class RaceResultInput extends Equatable {
  /// Eredmény; a hiányzó mező `null`.
  const RaceResultInput({
    this.classPlace,
    this.classFleetSize,
    this.overallPlace,
    this.overallFleetSize,
    this.monohullPlace,
    this.monohullFleetSize,
    this.ysNumberHundredths,
    this.officialStart,
    this.officialFinish,
    this.prize,
    this.summary,
  });

  /// Osztályhelyezés.
  final Placing? classPlace;

  /// Az osztály mezőnye (indult hajók).
  final int? classFleetSize;

  /// Abszolút helyezés.
  final Placing? overallPlace;

  /// Az abszolút (teljes) mezőny.
  final int? overallFleetSize;

  /// Egytestű helyezés.
  final Placing? monohullPlace;

  /// Az egytestűek mezőnye.
  final int? monohullFleetSize;

  /// A YS-szám századokban (`75,90` → 7590), hogy lebegőpontos hiba nélkül
  /// utazzon.
  final int? ysNumberHundredths;

  /// A hivatalos rajt (UTC).
  final DateTime? officialStart;

  /// A hivatalos befutás (UTC).
  final DateTime? officialFinish;

  /// A díj rövid szövege.
  final String? prize;

  /// A verseny összefoglalója (sima, többsoros szöveg).
  final String? summary;

  /// Igaz, ha egyetlen mező sincs kitöltve: a `PUT` ilyenkor töröl
  /// (ADR 0048 D3).
  bool get isEmpty => props.every((value) => value == null);

  /// Dobogós-e: bármelyik helyezés 1., 2. vagy 3. (ADR 0048 D3, az Excel
  /// szabálya). Származtatott, nem tárolt.
  bool get isPodium => [
    classPlace,
    overallPlace,
    monohullPlace,
  ].any((placing) => placing?.isPodium ?? false);

  /// A hivatalos menetidő, ha mindkét idő megvan, különben `null`.
  Duration? get officialElapsed => switch ((officialStart, officialFinish)) {
    (final DateTime start, final DateTime finish) => finish.difference(start),
    _ => null,
  };

  @override
  List<Object?> get props => [
    classPlace,
    classFleetSize,
    overallPlace,
    overallFleetSize,
    monohullPlace,
    monohullFleetSize,
    ysNumberHundredths,
    officialStart,
    officialFinish,
    prize,
    summary,
  ];
}
