import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:web_server/src/polar_lab/twa_window_extremes.dart';

import '../polar/polar_fixtures.dart';

void main() {
  final start = DateTime.utc(2026, 7, 26, 10);

  PolarSample sample(int second, double? twaDeg) => PolarSample(
    timestamp: start.add(Duration(seconds: second)),
    twaDeg: twaDeg,
    twsMps: mps(10),
    stwMps: mps(5),
  );

  double unchanged(double degrees) => degrees;

  group('twaWindowExtremes', () {
    test('finds the folded angle extremes around each sample', () {
      final extremes = twaWindowExtremes(
        [sample(0, 60), sample(1, 64), sample(2, -170), sample(3, 175)],
        halfWindowSeconds: 1,
        measure: unchanged,
      );

      // A -170 fok 170 fok: a 2. masodperc ablaka 64, 170, 175.
      expect(extremes, [
        (minimum: 60, maximum: 64),
        (minimum: 60, maximum: 170),
        (minimum: 64, maximum: 175),
        (minimum: 170, maximum: 175),
      ]);
    });

    test('applies the measure to every angle in the window', () {
      final extremes = twaWindowExtremes(
        [sample(0, 179), sample(1, 1)],
        halfWindowSeconds: 1,
        measure: (degrees) => degrees < 90 ? degrees : 180 - degrees,
      );

      expect(extremes, everyElement((minimum: 1, maximum: 1)));
    });

    test('gives null for an invalid own angle and skips it nearby', () {
      // A ket ervenyes minta 2 mp-re van: egymas ablakan kivul.
      final extremes = twaWindowExtremes(
        [sample(0, 60), sample(1, null), sample(2, 61)],
        halfWindowSeconds: 1,
        measure: unchanged,
      );

      expect(extremes, [
        (minimum: 60, maximum: 60),
        null,
        (minimum: 61, maximum: 61),
      ]);
    });

    test('rejects a negative half window', () {
      expect(
        () => twaWindowExtremes([], halfWindowSeconds: -1, measure: unchanged),
        throwsArgumentError,
      );
    });
  });

  group('foldedTwaDegrees', () {
    test('folds onto the half grid and drops invalid angles', () {
      expect(foldedTwaDegrees(-60), 60);
      expect(foldedTwaDegrees(300), 60);
      expect(foldedTwaDegrees(180), 180);
      expect(foldedTwaDegrees(null), isNull);
      expect(foldedTwaDegrees(double.nan), isNull);
    });
  });
}
