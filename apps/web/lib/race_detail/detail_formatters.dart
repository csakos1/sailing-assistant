// A részletező szám- és idő-formázói (ADR 0048 Addendum 4 K10). Pure
// függvények: a megjelenítés helyi időben történik, a böngésző zónájában.

/// A YS-szám századokból: 7590 → `75,90` (két tizedes, vesszővel).
String formatYsNumber(int hundredths) {
  final whole = hundredths ~/ 100;
  final fraction = (hundredths % 100).toString().padLeft(2, '0');
  return '$whole,$fraction';
}

/// Egy pillanat helyi ideje `ÓÓ:PP` alakban.
String formatLocalClock(DateTime instant) {
  final local = instant.toLocal();
  return '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
}

/// Egy időtartam `ÓÓ:PP:MM` alakban; 24 óra fölött is órában (Kékszalag).
String formatElapsed(Duration elapsed) {
  final hours = elapsed.inHours;
  final minutes = elapsed.inMinutes % 60;
  final seconds = elapsed.inSeconds % 60;
  return '${_twoDigits(hours)}:${_twoDigits(minutes)}:${_twoDigits(seconds)}';
}

/// Igaz, ha a [finish] helyi naptári napja későbbi a [start]-énál.
bool isNextLocalDay(DateTime start, DateTime finish) {
  final startLocal = start.toLocal();
  final finishLocal = finish.toLocal();
  final startDay = DateTime(startLocal.year, startLocal.month, startLocal.day);
  final finishDay = DateTime(
    finishLocal.year,
    finishLocal.month,
    finishLocal.day,
  );
  return finishDay.isAfter(startDay);
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
