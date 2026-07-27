import 'package:shared/shared.dart';
import 'package:test/test.dart';

// Siofok; a kozolt horgony-ertekek erre a telepulesre vonatkoznak.
const double _siofokLatitude = 46.905;
const double _siofokLongitude = 18.058;

// Kozolt napkelte/napnyugta Siofokra, UTC-re valtva (nyaron CEST = UTC+2,
// telen CET = UTC+1). A tureshatart a forras perc-felbontasa es a telepules
// kozeppontjanak bizonytalansaga indokolja.
final _summerSolstice = DateTime.utc(2026, 6, 21);
final _publishedSummerSunrise = DateTime.utc(2026, 6, 21, 2, 52);
final _publishedSummerSunset = DateTime.utc(2026, 6, 21, 18, 46);

final _winterSolstice = DateTime.utc(2026, 12, 21);
final _publishedWinterSunrise = DateTime.utc(2026, 12, 21, 6, 30);
final _publishedWinterSunset = DateTime.utc(2026, 12, 21, 15, 1);

void _expectWithinMinutes(DateTime actual, DateTime expected, int minutes) {
  final drift = actual.difference(expected).abs();
  expect(
    drift.inSeconds,
    lessThanOrEqualTo(minutes * 60),
    reason: 'expected $expected, got $actual',
  );
}

({DateTime sunriseUtc, DateTime sunsetUtc}) _siofok(DateTime day) =>
    sunTimesUtc(
      dayUtc: day,
      latitudeDegrees: _siofokLatitude,
      longitudeDegrees: _siofokLongitude,
    );

bool _nightOverBalaton(DateTime now, {Duration offset = Duration.zero}) =>
    isNightAt(
      nowUtc: now,
      latitudeDegrees: balatonReferenceLatitude,
      longitudeDegrees: balatonReferenceLongitude,
      offset: offset,
    );

void main() {
  group('sunTimesUtc', () {
    test('matches published Siofok times at the summer solstice', () {
      final times = _siofok(_summerSolstice);

      _expectWithinMinutes(times.sunriseUtc, _publishedSummerSunrise, 2);
      _expectWithinMinutes(times.sunsetUtc, _publishedSummerSunset, 2);
    });

    test('matches published Siofok times at the winter solstice', () {
      final times = _siofok(_winterSolstice);

      _expectWithinMinutes(times.sunriseUtc, _publishedWinterSunrise, 2);
      _expectWithinMinutes(times.sunsetUtc, _publishedWinterSunset, 2);
    });

    test('returns UTC timestamps with sunrise before sunset', () {
      final times = _siofok(_summerSolstice);

      expect(times.sunriseUtc.isUtc, isTrue);
      expect(times.sunsetUtc.isUtc, isTrue);
      expect(times.sunriseUtc.isBefore(times.sunsetUtc), isTrue);
    });

    test('ignores the time of day in the argument', () {
      final fromMidnight = _siofok(DateTime.utc(2026, 6, 21));
      final fromEvening = _siofok(DateTime.utc(2026, 6, 21, 22, 13, 44));

      expect(fromEvening.sunriseUtc, fromMidnight.sunriseUtc);
      expect(fromEvening.sunsetUtc, fromMidnight.sunsetUtc);
    });

    test('day is more than seven hours longer at the summer solstice', () {
      final summer = _siofok(_summerSolstice);
      final winter = _siofok(_winterSolstice);

      final summerLength = summer.sunsetUtc.difference(summer.sunriseUtc);
      final winterLength = winter.sunsetUtc.difference(winter.sunriseUtc);

      expect(
        summerLength - winterLength,
        greaterThan(const Duration(hours: 7)),
      );
    });

    test('the Balaton reference lags Siofok by one to four minutes', () {
      // A referencia-pont nyugatabbra van, ezert ott KESOBB kel es KESOBB
      // nyugszik a nap. Ez az elojel bukik, ha a hosszusag elojele elcsuszik.
      final siofok = _siofok(_summerSolstice);
      final balaton = sunTimesUtc(
        dayUtc: _summerSolstice,
        latitudeDegrees: balatonReferenceLatitude,
        longitudeDegrees: balatonReferenceLongitude,
      );

      final sunriseLag = balaton.sunriseUtc.difference(siofok.sunriseUtc);
      final sunsetLag = balaton.sunsetUtc.difference(siofok.sunsetUtc);

      expect(sunriseLag, greaterThan(const Duration(seconds: 30)));
      expect(sunriseLag, lessThan(const Duration(minutes: 4)));
      expect(sunsetLag, greaterThan(const Duration(seconds: 30)));
      expect(sunsetLag, lessThan(const Duration(minutes: 4)));
    });
  });

  group('isNightAt', () {
    test('one minute after sunset is night, one minute before is day', () {
      final sunset = sunTimesUtc(
        dayUtc: _summerSolstice,
        latitudeDegrees: balatonReferenceLatitude,
        longitudeDegrees: balatonReferenceLongitude,
      ).sunsetUtc;

      expect(_nightOverBalaton(sunset.add(const Duration(minutes: 1))), isTrue);
      expect(
        _nightOverBalaton(sunset.subtract(const Duration(minutes: 1))),
        isFalse,
      );
    });

    test('one minute before sunrise is night, one minute after is day', () {
      final sunrise = sunTimesUtc(
        dayUtc: _summerSolstice,
        latitudeDegrees: balatonReferenceLatitude,
        longitudeDegrees: balatonReferenceLongitude,
      ).sunriseUtc;

      expect(
        _nightOverBalaton(sunrise.subtract(const Duration(minutes: 1))),
        isTrue,
      );
      expect(
        _nightOverBalaton(sunrise.add(const Duration(minutes: 1))),
        isFalse,
      );
    });

    test('the same clock hour is night in winter and day in summer', () {
      // 17:00 UTC: decemberben mar reg lement a nap (15:01 UTC), juniusban meg
      // fenn van (18:46 UTC). Ez fogja meg a szisztematikus evszak-hibat.
      expect(_nightOverBalaton(DateTime.utc(2026, 12, 21, 17)), isTrue);
      expect(_nightOverBalaton(DateTime.utc(2026, 6, 21, 17)), isFalse);
    });

    test('a positive offset keeps it day for a while after sunset', () {
      final sunset = sunTimesUtc(
        dayUtc: _summerSolstice,
        latitudeDegrees: balatonReferenceLatitude,
        longitudeDegrees: balatonReferenceLongitude,
      ).sunsetUtc;
      final tenPastSunset = sunset.add(const Duration(minutes: 10));

      expect(_nightOverBalaton(tenPastSunset), isTrue);
      expect(
        _nightOverBalaton(tenPastSunset, offset: const Duration(minutes: 30)),
        isFalse,
      );
    });

    test('a positive offset brings the morning switch forward', () {
      final sunrise = sunTimesUtc(
        dayUtc: _summerSolstice,
        latitudeDegrees: balatonReferenceLatitude,
        longitudeDegrees: balatonReferenceLongitude,
      ).sunriseUtc;
      final tenBeforeSunrise = sunrise.subtract(const Duration(minutes: 10));

      expect(_nightOverBalaton(tenBeforeSunrise), isTrue);
      expect(
        _nightOverBalaton(
          tenBeforeSunrise,
          offset: const Duration(minutes: 30),
        ),
        isFalse,
      );
    });
  });
}
