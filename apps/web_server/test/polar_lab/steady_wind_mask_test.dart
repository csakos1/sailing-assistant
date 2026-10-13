import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:web_server/src/polar_lab/steady_wind_mask.dart';

import '../polar/polar_fixtures.dart';

void main() {
  final start = DateTime.utc(2026, 7, 26, 10);

  PolarSample sample(int second, double? twaDeg) => PolarSample(
    timestamp: start.add(Duration(seconds: second)),
    twaDeg: twaDeg,
    twsMps: mps(10),
    stwMps: mps(5),
  );

  // Masodpercenkent egy minta a megadott szogekkel.
  List<PolarSample> everySecond(List<double?> angles) => [
    for (final (second, twaDeg) in angles.indexed) sample(second, twaDeg),
  ];

  group('steadyWindMask', () {
    test('keeps a steady wind', () {
      final mask = steadyWindMask(
        everySecond([60, 62, 79.9, 65, 60]),
        halfWindowSeconds: 1,
      );

      expect(mask, [true, true, true, true, true]);
    });

    test('drops every sample whose window spans twenty degrees', () {
      // ARRANGE: egy 80 fokos minta a 60 fokos szelben
      final samples = everySecond([60, 60, 80, 60, 60]);

      // ACT
      final mask = steadyWindMask(samples, halfWindowSeconds: 1);

      // ASSERT: az 1-3. masodperc ablakaban benne van a 80 fok
      expect(mask, [true, false, false, false, true]);
    });

    test('includes the neighbours at the window edge', () {
      final atEdge = steadyWindMask([sample(0, 60), sample(10, 80)]);
      final beyondEdge = steadyWindMask([sample(0, 60), sample(11, 80)]);

      expect(atEdge, [false, false]);
      expect(beyondEdge, [true, true]);
    });

    test('folds the angle so a gybe across 180 degrees is steady', () {
      final mask = steadyWindMask(everySecond([179, -179, 178, -177]));

      expect(mask, everyElement(isTrue));
    });

    test('keeps an invalid angle and ignores it as a neighbour', () {
      final mask = steadyWindMask(
        everySecond([60, double.nan, 75]),
        halfWindowSeconds: 1,
      );

      expect(mask, [true, true, true]);
    });

    test('spans three samples of the ten second legacy log', () {
      // ARRANGE: a regi naplo 10 masodpercenkent ad mintat
      final samples = [
        sample(0, 60),
        sample(10, 60),
        sample(20, 80),
        sample(30, 60),
      ];

      // ACT
      final mask = steadyWindMask(samples);

      // ASSERT: csak a 0. masodperc ablakabol marad ki a 80 fok
      expect(mask, [true, false, false, false]);
    });

    test('gives an empty mask for no samples', () {
      expect(steadyWindMask([]), isEmpty);
    });

    test('rejects a negative half window', () {
      expect(
        () => steadyWindMask([], halfWindowSeconds: -1),
        throwsArgumentError,
      );
    });
  });
}
