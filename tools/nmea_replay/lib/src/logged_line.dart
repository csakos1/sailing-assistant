/// A felvett NMEA 0183 log egyetlen, már értelmezett sora: a Serial WiFi
/// Terminal `HH:MM:SS.mmm ` faliidő-prefixéből kinyert időbélyeg + a tiszta
/// NMEA mondat (a `$`/`!` jeltől a sor végéig, prefix nélkül).
///
/// Immutable value-objektum; a [parseLoggedLine] gyártja a nyers log-sorból.
class LoggedLine {
  /// A [sentence] a prefix nélküli mondat, a [timeOfDay] a prefix faliideje
  /// éjféltől.
  const LoggedLine({required this.sentence, required this.timeOfDay});

  /// A tiszta NMEA 0183 mondat a `$` (vagy `!`) jeltől a sor végéig, a
  /// faliidő-prefix nélkül. A replay ezt küldi a socketre (CRLF-fel) — a
  /// Vulcan is prefix nélkül küld.
  final String sentence;

  /// A mondat faliideje éjféltől, a prefix `HH:MM:SS.mmm`-jéből. A replay
  /// ezek **különbségéből** ütemez valós időben.
  final Duration timeOfDay;
}

/// A felvett log `HH:MM:SS.mmm ` faliidő-prefixe (a másodperc-tört 3 jegyű).
final _prefixPattern = RegExp(r'^\s*(\d{2}):(\d{2}):(\d{2})\.(\d{3})');

/// Egy nyers log-sorból [LoggedLine]-t állít elő, vagy `null`-t ha a sor nem
/// játszható vissza.
///
/// A mondatot a `$` (parametric) vagy `!` (encapsulation) jeltől vesszük, így
/// a prefix utáni esetleges extra szóköz sem zavar. `null` (skip), ha: a sor
/// üres / csak whitespace, nincs benne `$`/`!` kezdetű mondat, vagy a prefix
/// nem értelmezhető `HH:MM:SS.mmm` faliidőként — az ütemezés a prefixre épül,
/// ezért prefix nélküli mondatot nem játszunk vissza (a felvételeid prefixesek).
LoggedLine? parseLoggedLine(String line) {
  // A mondat kezdete az első $ vagy ! — a kettő közül a korábbi.
  final dollarIndex = line.indexOf(r'$');
  final bangIndex = line.indexOf('!');
  final starts = [dollarIndex, bangIndex].where((index) => index >= 0).toList();
  if (starts.isEmpty) {
    return null;
  }
  final start = starts.reduce((a, b) => a < b ? a : b);

  final match = _prefixPattern.firstMatch(line.substring(0, start));
  if (match == null) {
    return null;
  }

  // A capture group-ok (1–4) kötelezőek, és a match létrejött, így biztosan
  // nem null — a `!` itt indokolt.
  final timeOfDay = Duration(
    hours: int.parse(match.group(1)!),
    minutes: int.parse(match.group(2)!),
    seconds: int.parse(match.group(3)!),
    milliseconds: int.parse(match.group(4)!),
  );

  return LoggedLine(
    sentence: line.substring(start).trimRight(),
    timeOfDay: timeOfDay,
  );
}
