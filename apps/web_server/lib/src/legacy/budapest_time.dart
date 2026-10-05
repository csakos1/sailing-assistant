import 'package:race_archive_api/race_archive_api.dart';

/// Egy Europe/Budapest falióra-idő UTC-pillanata (ADR 0048 Addendum 6
/// M3).
///
/// A [wallClock] csak a mezőit hordozza (év … mikroszekundum), a zónája
/// lényegtelen; a hívó `DateTime.utc`-vel építi, hogy a gép helyi
/// zónája ne normalizálhassa el a mezőket.
///
/// A szabály az 1996 óta érvényes EU-szabály: nyári idő (UTC+2) március
/// utolsó vasárnapján 01:00 UTC-től október utolsó vasárnapján 01:00
/// UTC-ig, különben UTC+1. Ha egy falióra-idő kétértelmű (őszi
/// ismétlés) vagy nem létezik (tavaszi ugrás), a téli eltolás érvényes.
DateTime budapestWallClockToUtc(DateTime wallClock) {
  final fields = DateTime.utc(
    wallClock.year,
    wallClock.month,
    wallClock.day,
    wallClock.hour,
    wallClock.minute,
    wallClock.second,
    wallClock.millisecond,
    wallClock.microsecond,
  );
  final asWinterTime = fields.subtract(const Duration(hours: 1));
  if (!_isSummerTimeAt(asWinterTime)) return asWinterTime;
  final asSummerTime = fields.subtract(const Duration(hours: 2));
  if (_isSummerTimeAt(asSummerTime)) return asSummerTime;
  // A tavaszi ugrás órája: nem létező helyi idő, a téli eltolással.
  return asWinterTime;
}

/// Az [instant] pillanat Europe/Budapest falióra-ideje, a mezői egy
/// UTC-objektumban (a [budapestWallClockToUtc] fordítottja).
DateTime budapestWallClockOf(DateTime instant) {
  final utc = instant.toUtc();
  return utc.add(Duration(hours: _isSummerTimeAt(utc) ? 2 : 1));
}

/// Az [instant] pillanat naptári napja Europe/Budapest időben.
CalendarDate budapestDayOf(DateTime instant) {
  final local = budapestWallClockOf(instant);
  // Egy valódi DateTime mezőiből épül, ezért a nap mindig létezik.
  return CalendarDate.tryFromParts(
    year: local.year,
    month: local.month,
    day: local.day,
  )!;
}

/// A [date] utáni naptári nap.
CalendarDate nextCalendarDay(CalendarDate date) {
  // A DateTime a hónap- és évhatárt maga görgeti át.
  final next = DateTime.utc(date.year, date.month, date.day + 1);
  // Egy valódi DateTime mezőiből épül, ezért a nap mindig létezik.
  return CalendarDate.tryFromParts(
    year: next.year,
    month: next.month,
    day: next.day,
  )!;
}

bool _isSummerTimeAt(DateTime utc) {
  final start = _lastSundayAtOneUtc(utc.year, DateTime.march);
  final end = _lastSundayAtOneUtc(utc.year, DateTime.october);
  return !utc.isBefore(start) && utc.isBefore(end);
}

DateTime _lastSundayAtOneUtc(int year, int month) {
  // A következő hónap nulladik napja a hónap utolsó napja.
  final lastDay = DateTime.utc(year, month + 1, 0);
  // A weekday hétfőn 1, vasárnap 7; a maradék a vasárnapig visszalépés.
  final lastSunday = lastDay.day - lastDay.weekday % DateTime.daysPerWeek;
  return DateTime.utc(year, month, lastSunday, 1);
}
