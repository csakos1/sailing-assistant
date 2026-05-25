// NMEA 0183 mező-parserek, amelyeket több mondat-dekóder is használ
// (RMC/GGA/GLL a koordinátát, RMC az UTC-időt). Pure Dart, nincs Flutter.

/// `ddmm.mmmm` (lat) vagy `dddmm.mmmm` (lon) + hemiszféra-jel → előjeles
/// decimális fok, vagy `null` ha [value] nem értelmezhető vagy a
/// [hemisphere] ismeretlen.
///
/// Az NMEA a fok-perc értéket egyetlen számként adja (fok×100 + perc); a
/// hemiszféra (`N`/`E` = pozitív, `S`/`W` = negatív) hordozza az előjelet.
/// A finite-guard kötelező: `double.tryParse('NaN')` NaN-t ad, amin a
/// `.floor()` kivételt dobna.
double? decimalDegreesFromNmea(String value, String hemisphere) {
  final raw = double.tryParse(value);
  if (raw == null || !raw.isFinite || raw < 0) {
    return null;
  }

  final sign = switch (hemisphere) {
    'N' || 'E' => 1,
    'S' || 'W' => -1,
    _ => null,
  };
  if (sign == null) {
    return null;
  }

  final degrees = (raw / 100).floor();
  final minutes = raw - degrees * 100;
  return sign * (degrees + minutes / 60);
}

/// `ddmmyy` (dátum) + `hhmmss` (UTC-idő) → `DateTime.utc`, vagy `null` ha a
/// formátum hibás.
///
/// A v1 forrás tizedmásodperc NÉLKÜL adja az időt, ezért pontosan 6-6
/// karaktert várunk; a `.ss`-es variáns (más műszereknél) skippel.
DateTime? utcDateTimeFromNmea(String date, String time) {
  if (date.length != 6 || time.length != 6) {
    return null;
  }

  final day = int.tryParse(date.substring(0, 2));
  final month = int.tryParse(date.substring(2, 4));
  final year = int.tryParse(date.substring(4, 6));
  final hour = int.tryParse(time.substring(0, 2));
  final minute = int.tryParse(time.substring(2, 4));
  final second = int.tryParse(time.substring(4, 6));
  if (day == null ||
      month == null ||
      year == null ||
      hour == null ||
      minute == null ||
      second == null) {
    return null;
  }

  return DateTime.utc(2000 + year, month, day, hour, minute, second);
}
