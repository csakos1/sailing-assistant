// Cross-surface megjelenítési konvenció és primitív-bemenetű formázók (phone +
// óra közös szabálykészlete; ADR 0015 D8 + addendum). Tiszta Dart, semmi
// Flutter/domain: az óra a WatchPayload primitíveit rendereli, a phone
// domain-típusos wrapperei ezekre delegálnak.

/// A nyíl elhelyezése a számhoz képest. A glyph iránya/stílusa és a szín a
/// widgeté: TWA befelé mutató tömör háromszög, korrekció kifelé mutató
/// vonal-nyíl; mindkettő jobb → zöld, bal → piros (hajós konvenció).
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

/// Egy signed fok magnitúdója egész fokban `°` jellel (pl. `32°`), vagy
/// [missingValue] ha null. Az előjelet NEM írja — azt a nyíl hordozza.
String formatDegreesMagnitude(double? degrees) {
  if (degrees == null) {
    return missingValue;
  }
  return '${degrees.abs().round()}°';
}

/// Egy táv méterben: `< 1000 m` egész méter (`450 m`), `>= 1000 m` két
/// tizedes km (`1.85 km`), vagy [missingValue] ha null.
String formatDistanceMeters(double? meters) {
  if (meters == null) {
    return missingValue;
  }
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  return '${(meters / 1000).toStringAsFixed(2)} km';
}

/// Egy ETA másodpercben: `< 60 perc` → `mm:ss` (`07:32`), `>= 60 perc` →
/// egész perc a [minutesUnit] címkével (`83 perc`), vagy [missingValue] ha
/// null. A nyelvfüggő perc-címkét a hívó adja (l10n), hogy pure maradjon.
String formatEtaSeconds(int? seconds, {required String minutesUnit}) {
  if (seconds == null) {
    return missingValue;
  }
  if (seconds >= 3600) {
    return '${seconds ~/ 60} $minutesUnit';
  }
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final secs = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$secs';
}

/// Egy UTC időbélyeg local órája `HH:mm:ss` formátumban (pl. `14:32:07`),
/// vagy [missingTime] ha null. A UTC→local váltás `toLocal()`-lal
/// (DST-aware), hogy a chartplotterrel egyezzen.
String formatLocalClock(DateTime? utc) {
  if (utc == null) {
    return missingTime;
  }
  final local = utc.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');
  return '$hour:$minute:$second';
}
