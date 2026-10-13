import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:web_server/src/polar_lab/frozen_vane_mask.dart';

import '../polar/polar_fixtures.dart';

void main() {
  final start = DateTime.utc(2026, 7, 26, 10);

  PolarSample sample(int second, double? twaDeg) => PolarSample(
    timestamp: start.add(Duration(seconds: second)),
    twaDeg: twaDeg,
    twsMps: mps(8),
    stwMps: mps(5),
  );

  // Masodpercenkent egy minta a megadott szogekkel.
  List<PolarSample> everySecond(List<double?> angles) => [
    for (final (second, twaDeg) in angles.indexed) sample(second, twaDeg),
  ];

  group('frozenVaneMask', () {
    test('drops a vane stuck at 180 degrees', () {
      final mask = frozenVaneMask(everySecond([180, 180, -180, 179.5, 180]));

      expect(mask, everyElement(isFalse));
    });

    test('drops a vane stuck at 0 degrees', () {
      expect(frozenVaneMask(everySecond([0, 0, 1])), everyElement(isFalse));
    });

    test('keeps the stretch frozen across a jump between the ends', () {
      // ARRANGE: 180 fok, az 5. masodperctol 0 fok
      final samples = [
        for (var second = 0; second < 40; second++)
          sample(second, second < 5 ? 180 : 0),
      ];

      // ACT
      final mask = frozenVaneMask(samples);

      // ASSERT: az ugras korul sem szivarog at minta
      expect(mask, everyElement(isFalse));
    });

    test('keeps a real run that reaches two degrees from the end', () {
      final mask = frozenVaneMask(everySecond([180, 178, 179, 180]));

      expect(mask, everyElement(isTrue));
    });

    test('stops just under two degrees from the end', () {
      final mask = frozenVaneMask(everySecond([180, 178.1, 179, 180]));

      expect(mask, everyElement(isFalse));
    });

    test('keeps samples away from both ends', () {
      expect(frozenVaneMask(everySecond([150, 150, 150])), [true, true, true]);
    });

    test('looks thirty seconds both ways', () {
      // ARRANGE: 180 fok, a 30. masodpercben 170 fok
      final samples = [sample(0, 180), sample(30, 170), sample(61, 180)];

      // ACT
      final mask = frozenVaneMask(samples);

      // ASSERT: a 0. mp ablakaban benne van a 170 fok, a 61.-eben nincs
      expect(mask, [true, true, false]);
    });

    test('keeps an invalid angle', () {
      final mask = frozenVaneMask(everySecond([180, double.nan, 180]));

      expect(mask, [false, true, false]);
    });
  });
}
