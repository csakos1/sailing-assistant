import 'package:domain/domain.dart';

/// A nyíl elhelyezése a számhoz képest (§8.7). A glyph iránya/stílusa és a
/// szín a widgeté: TWA befelé mutató tömör háromszög, korrekció kifelé
/// mutató vonal-nyíl; mindkettő jobb → zöld, bal → piros (hajós konvenció).
enum ArrowSide {
  /// A szám bal oldalán.
  left,

  /// A szám jobb oldalán.
  right,

  /// Nincs nyíl (0° vagy hiányzó érték).
  none,
}

/// Hiányzó számérték placeholdere (nyelvfüggetlen).
const String missingValue = '—';

/// Hiányzó GPS-idő placeholdere (nyelvfüggetlen).
const String missingTime = '--:--:--';

/// Signed fokból az oldal: `>0 → jobb`, `<0 → bal`, `0`/`null` → nincs.
/// TWA-nál `+` = starboard (szél jobbról), korrekciónál `+` = jobbra fordulj.
ArrowSide arrowSideFromSign(double? degrees) => switch (degrees) {
  null => ArrowSide.none,
  final d when d > 0 => ArrowSide.right,
  final d when d < 0 => ArrowSide.left,
  _ => ArrowSide.none,
};

/// Egy signed [Angle] magnitúdója egész fokban `°` jellel (pl. `32°`),
/// vagy [missingValue] ha null. Az előjelet NEM írja — azt a nyíl hordozza.
String formatAngleMagnitude(Angle? angle) {
  if (angle == null) {
    return missingValue;
  }
  return '${angle.degrees.abs().round()}°';
}

/// Egy abszolút [Bearing] három jegyre nullázva `°` jellel (pl. `095°`),
/// vagy [missingValue] ha null. A 360-ra kerekített érték `000`-ra wrap-el.
String formatBearing(Bearing? bearing) {
  if (bearing == null) {
    return missingValue;
  }
  final degrees = bearing.degrees.round() % 360;
  return '${degrees.toString().padLeft(3, '0')}°';
}

/// Egy [Distance] formázása: `< 1000 m` egész méter (`450 m`),
/// `>= 1000 m` két tizedes km (`1.85 km`), vagy [missingValue] ha null.
String formatDistance(Distance? distance) {
  if (distance == null) {
    return missingValue;
  }
  final meters = distance.meters;
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  return '${(meters / 1000).toStringAsFixed(2)} km';
}

/// Egy ETA [Duration] formázása: `< 60 perc` → `mm:ss` (`07:32`),
/// `>= 60 perc` → egész perc a [minutesUnit] címkével (`83 perc`), vagy
/// [missingValue] ha null. A nyelvfüggő perc-címkét a hívó adja (l10n),
/// hogy a formázó pure és nyelvfüggetlen maradjon.
String formatEta(Duration? eta, {required String minutesUnit}) {
  if (eta == null) {
    return missingValue;
  }
  final totalSeconds = eta.inSeconds;
  if (totalSeconds >= 3600) {
    return '${eta.inMinutes} $minutesUnit';
  }
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// Egy GPS műszer-időbélyeg local időben `HH:mm:ss` formátumban
/// (pl. `14:32:07`), vagy [missingTime] ha null. A UTC→local váltás
/// `toLocal()`-lal (DST-aware), hogy a chartplotterrel egyezzen.
String formatInstrumentTime(DateTime? instrumentTimeUtc) {
  if (instrumentTimeUtc == null) {
    return missingTime;
  }
  final local = instrumentTimeUtc.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');
  return '$hour:$minute:$second';
}
