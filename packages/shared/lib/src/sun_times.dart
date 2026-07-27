// Napkelte/napnyugta a NOAA sunrise-egyenlettel (ADR 0039 D6–D8). Tiszta Dart,
// semmi Flutter és semmi domain: a `shared` nem függhet a `domain`-től, ezért a
// pozíció két `double`, nem `Coordinate`. Az órán fut, hogy az éjszakai mód
// payload és kapcsolat nélkül is helyes legyen.

import 'dart:math' as math;

/// A Balaton középpontjának földrajzi szélessége fokban (ADR 0039 D6).
///
/// A tó két vége között a napnyugta ~3,5 perc eltérés, ezért egyetlen
/// referencia-pont elég; a valódi GPS-pozíció nem adna mérhető pontosságot,
/// cserébe adatfüggést adna egy funkciónak, aminek adat nélkül is mennie kell.
const double balatonReferenceLatitude = 46.83;

/// A Balaton középpontjának földrajzi hosszúsága fokban (ADR 0039 D6).
const double balatonReferenceLongitude = 17.7;

// A napkorong felső peremének magassága a horizonton, a légköri fénytöréssel
// együtt (−50 ívperc): a hivatalos napkelte/napnyugta ehhez van definiálva.
const double _sunriseElevationDegrees = -0.833;

// A Föld tengelyferdesége fokban.
const double _obliquityDegrees = 23.4397;

// A J2000.0 epocha julián dátuma (2000-01-01 12:00 UTC).
const double _j2000 = 2451545;

/// Az adott UTC-naphoz tartozó napkelte és napnyugta, UTC-ben.
///
/// A [dayUtc] idő-része nem számít, csak a naptári nap. A visszaadott két
/// időpont mindig UTC. A számítás a NOAA sunrise-egyenlet; a pontossága a
/// mérsékelt övben perc alatti, ami a napszak-döntéshez bőven elég.
///
/// Sarkkörön túl a Nap nem feltétlenül kel fel vagy nyugszik le, ezért a
/// szélességre assert vigyáz: a hívó dolga, hogy értelmes helyre kérdezzen.
({DateTime sunriseUtc, DateTime sunsetUtc}) sunTimesUtc({
  required DateTime dayUtc,
  required double latitudeDegrees,
  required double longitudeDegrees,
}) {
  assert(dayUtc.isUtc, 'dayUtc must be a UTC timestamp');
  assert(
    latitudeDegrees.abs() < 60,
    'beyond 60 degrees the sun may not rise or set at all',
  );

  final dayNumber = (_julianDayAtMidnightUtc(dayUtc) - _j2000 + 0.0008).round();
  final meanSolarTime = dayNumber - longitudeDegrees / 360;
  final meanAnomaly = (357.5291 + 0.98560028 * meanSolarTime) % 360;
  final equationOfCentre =
      1.9148 * _sinDeg(meanAnomaly) +
      0.02 * _sinDeg(2 * meanAnomaly) +
      0.0003 * _sinDeg(3 * meanAnomaly);
  final eclipticLongitude =
      (meanAnomaly + equationOfCentre + 180 + 102.9372) % 360;
  final transit =
      _j2000 +
      meanSolarTime +
      0.0053 * _sinDeg(meanAnomaly) -
      0.0069 * _sinDeg(2 * eclipticLongitude);

  final sinDeclination =
      _sinDeg(eclipticLongitude) * _sinDeg(_obliquityDegrees);
  final cosDeclination = math.cos(math.asin(sinDeclination));
  // A clamp csak lebegőpontos túlcsordulás ellen véd: 60 fok alatt a hányados
  // matematikailag mindig a [-1, 1] tartományban van.
  final cosHourAngle =
      ((_sinDeg(_sunriseElevationDegrees) -
                  _sinDeg(latitudeDegrees) * sinDeclination) /
              (_cosDeg(latitudeDegrees) * cosDeclination))
          .clamp(-1.0, 1.0);
  final hourAngleDegrees = math.acos(cosHourAngle) * 180 / math.pi;

  return (
    sunriseUtc: _utcFromJulianDay(transit - hourAngleDegrees / 360),
    sunsetUtc: _utcFromJulianDay(transit + hourAngleDegrees / 360),
  );
}

/// Igaz, ha [nowUtc] a napnyugta és a napkelte közé esik az adott helyen.
///
/// Az [offset] **szimmetrikusan szűkíti** az éjszakát: a napnyugta után
/// ennyivel kezdődik, és a napkelte előtt ennyivel ér véget. Így egyetlen szám
/// tolja mindkét váltást a helyes irányba (napnyugtakor még világos van).
///
/// A határok a nappalhoz tartoznak: pontosan napkeltekor és napnyugtakor a
/// függvény `false`-t ad.
bool isNightAt({
  required DateTime nowUtc,
  required double latitudeDegrees,
  required double longitudeDegrees,
  Duration offset = Duration.zero,
}) {
  assert(nowUtc.isUtc, 'nowUtc must be a UTC timestamp');

  final times = sunTimesUtc(
    dayUtc: nowUtc,
    latitudeDegrees: latitudeDegrees,
    longitudeDegrees: longitudeDegrees,
  );

  // Az éjfél-átfordulás miatt ez az egyszerű predikátum csak akkor helyes, ha a
  // napkelte és a napnyugta ugyanarra az UTC-napra esik. A Balatonon (17,7° K)
  // a delelés ~10:49 UTC, tehát ez teljesül — másutt hangosan bukjon el.
  assert(
    _isSameUtcDay(times.sunriseUtc, nowUtc) &&
        _isSameUtcDay(times.sunsetUtc, nowUtc),
    'sunrise and sunset must fall on the same UTC day as nowUtc',
  );

  final nightStart = times.sunsetUtc.add(offset);
  final nightEnd = times.sunriseUtc.subtract(offset);
  return nowUtc.isAfter(nightStart) || nowUtc.isBefore(nightEnd);
}

double _sinDeg(double degrees) => math.sin(degrees * math.pi / 180);

double _cosDeg(double degrees) => math.cos(degrees * math.pi / 180);

bool _isSameUtcDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// A naptári nap 00:00 UTC-jének julián dátuma (Fliegel–Van Flandern).
double _julianDayAtMidnightUtc(DateTime dayUtc) {
  final leapShift = (14 - dayUtc.month) ~/ 12;
  final year = dayUtc.year + 4800 - leapShift;
  final month = dayUtc.month + 12 * leapShift - 3;
  final julianDayNumber =
      dayUtc.day +
      (153 * month + 2) ~/ 5 +
      365 * year +
      year ~/ 4 -
      year ~/ 100 +
      year ~/ 400 -
      32045;
  return julianDayNumber - 0.5;
}

DateTime _utcFromJulianDay(double julianDay) {
  final millisSinceEpoch = ((julianDay - _j2000) * Duration.millisecondsPerDay)
      .round();
  return DateTime.utc(2000, 1, 1, 12).add(
    Duration(milliseconds: millisSinceEpoch),
  );
}
