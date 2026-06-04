import 'package:domain/domain.dart';
import 'package:shared/shared.dart';

// A nyíl-konvenció és a placeholderek a `shared`-ben élnek (ADR 0015 D8 +
// addendum); innen re-exportáljuk, hogy a meglévő live-race widgetek import-
// változtatás nélkül használják őket. A formázó-szabályok is a `shared`-ben
// vannak; az alábbi wrapperek a domain value-objectekből primitívet emelnek
// ki, és a `shared` primitív formázóira delegálnak (egy igazságforrás).
export 'package:shared/shared.dart'
    show ArrowSide, arrowSideFromSign, missingTime, missingValue;

/// Egy signed [Angle] magnitúdója egész fokban `°` jellel (pl. `32°`), vagy
/// `missingValue` ha null. Az előjelet a nyíl hordozza; a szabályt a `shared`
/// `formatDegreesMagnitude` adja.
String formatAngleMagnitude(Angle? angle) =>
    formatDegreesMagnitude(angle?.degrees);

/// Egy abszolút [Bearing] három jegyre nullázva `°` jellel (pl. `095°`),
/// vagy `missingValue` ha null. A 360-ra kerekített érték `000`-ra wrap-el.
/// Phone-only: az órán nincs bearing (ADR 0015).
String formatBearing(Bearing? bearing) {
  if (bearing == null) {
    return missingValue;
  }
  final degrees = bearing.degrees.round() % 360;
  return '${degrees.toString().padLeft(3, '0')}°';
}

/// Egy [Distance] formázása: `< 1000 m` egész méter, `>= 1000 m` két tizedes
/// km, vagy `missingValue` ha null. A szabályt a `shared` `formatDistanceMeters`
/// adja.
String formatDistance(Distance? distance) =>
    formatDistanceMeters(distance?.meters);

/// Egy ETA [Duration] formázása: `< 60 perc` → `mm:ss`, `>= 60 perc` → egész
/// perc a [minutesUnit] címkével, vagy `missingValue` ha null. A szabályt a
/// `shared` `formatEtaSeconds` adja; a perc-címkét a hívó adja (l10n).
String formatEta(Duration? eta, {required String minutesUnit}) =>
    formatEtaSeconds(eta?.inSeconds, minutesUnit: minutesUnit);

/// Egy GPS műszer-időbélyeg local időben `HH:mm:ss` (pl. `14:32:07`), vagy
/// `missingTime` ha null. A szabályt a `shared` `formatLocalClock` adja
/// (`toLocal()`, DST-aware), hogy a chartplotterrel egyezzen.
String formatInstrumentTime(DateTime? instrumentTimeUtc) =>
    formatLocalClock(instrumentTimeUtc);
