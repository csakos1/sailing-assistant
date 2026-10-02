// Helyi nap + helyi idő ↔ UTC pillanat (ADR 0048 Addendum 4 K11). Az
// űrlap helyi időben dolgozik, a böngésző zónájában; a dróton UTC utazik.

import 'package:foretack_web/race_edit/form/clock_time.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A [date] napon, a [dayOffset] nappal később, a [time] helyi időpont
/// UTC-ben.
///
/// A `DateTime` helyi konstruktora a nyári időszámítás váltását is
/// kezeli, és a túlcsorduló napot (pl. június 31.) a következő hónapra
/// görgeti.
DateTime localInstant(
  CalendarDate date,
  ClockTime time, {
  int dayOffset = 0,
}) => DateTime(
  date.year,
  date.month,
  date.day + dayOffset,
  time.hour,
  time.minute,
  time.second,
).toUtc();

/// Az [instant] pillanat helyi naptári napja.
CalendarDate localDateOf(DateTime instant) {
  final local = instant.toLocal();
  // A `!` biztonságos: egy létező pillanat helyi napja mindig létező nap.
  return CalendarDate.tryFromParts(
    year: local.year,
    month: local.month,
    day: local.day,
  )!;
}

/// Az [instant] pillanat helyi ideje a napon belül.
ClockTime localClockOf(DateTime instant) {
  final local = instant.toLocal();
  return (hour: local.hour, minute: local.minute, second: local.second);
}

/// Hány naptári nappal később van az [instant] helyi napja a [from]
/// napnál (negatív, ha korábban).
int localDayOffset(CalendarDate from, DateTime instant) {
  final day = localDateOf(instant);
  // UTC-éjfelek különbsége: így a nyári időszámítás 23 vagy 25 órás
  // napja nem csonkítja az eredményt.
  final start = DateTime.utc(from.year, from.month, from.day);
  final end = DateTime.utc(day.year, day.month, day.day);
  return end.difference(start).inDays;
}
