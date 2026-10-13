import 'package:domain/domain.dart';
import 'package:test/test.dart';

// Csomo -> m/s, ahogy a muszer adja.
double mps(double knots) => knots * 1852 / 3600;

void main() {
  const flagTwsSpikes = FlagTwsSpikes();
  final start = DateTime.utc(2026, 7, 26, 10);

  PolarSample sample(int second, double? twsKnots) => PolarSample(
    timestamp: start.add(Duration(seconds: second)),
    twaDeg: 60,
    twsMps: twsKnots == null ? null : mps(twsKnots),
    stwMps: mps(5),
  );

  List<bool> flagsOf(List<double?> twsKnots) => flagTwsSpikes([
    for (final (second, tws) in twsKnots.indexed) sample(second, tws),
  ]);

  group('FlagTwsSpikes', () {
    test('gives no flags for no samples', () {
      expect(flagTwsSpikes(const []), isEmpty);
    });

    test('flags a gust far from its rolling median', () {
      // Given: egy 68 kn-os tuske 10 kn-os szelben
      // When / Then: csak a tuske jelolt
      expect(flagsOf([10, 10, 68, 10, 10]), [false, false, true, false, false]);
    });

    test('keeps a deviation below the threshold', () {
      // Given: 4,9 kn elteres a 10 kn-os mediantol (a kuszob 5 kn)
      expect(flagsOf([10, 10, 14.9, 10, 10]), everyElement(isFalse));
    });

    test('flags a deviation just above the threshold', () {
      expect(flagsOf([10, 10, 15.5, 10, 10]), [
        false,
        false,
        true,
        false,
        false,
      ]);
    });

    test('skips samples without wind speed and keeps them unflagged', () {
      // Given: a TWS nelkuli mintak nem szakitjak meg az ablakot
      // When / Then: a tuske a hezagok kozott is latszik, a hezag nem tuske
      expect(
        flagsOf([10, null, 10, 68, null, 10, 10]),
        [false, false, false, true, false, false, false],
      );
    });
  });
}
