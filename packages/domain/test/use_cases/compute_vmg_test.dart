import 'dart:math';

import 'package:domain/src/use_cases/compute_vmg.dart';
import 'package:test/test.dart';

void main() {
  group('ComputeVmg', () {
    const computeVmg = ComputeVmg();

    test('holtszélben (TWA 0°) a VMG a teljes hajósebesség', () {
      // Arrange / Act
      final vmg = computeVmg(boatSpeedKnots: 6, twaDegrees: 0);

      // Assert: cos(0) = 1 → a VMG a sebességgel egyenlő.
      expect(vmg, closeTo(6, 1e-9));
    });

    test('oldalszélben (TWA 90°) a VMG nulla', () {
      final vmg = computeVmg(boatSpeedKnots: 6, twaDegrees: 90);

      expect(vmg, closeTo(0, 1e-9));
    });

    test('holt-hátszélben (TWA 180°) a VMG a teljes sebesség, negatív', () {
      final vmg = computeVmg(boatSpeedKnots: 6, twaDegrees: 180);

      // cos(180) = -1 → széltől elfelé, ezért előjelesen negatív.
      expect(vmg, closeTo(-6, 1e-9));
    });

    test('felmenő szögnél (TWA 42°) a sebesség cos-vetülete', () {
      final vmg = computeVmg(boatSpeedKnots: 6, twaDegrees: 42);

      expect(vmg, closeTo(6 * cos(42 * pi / 180), 1e-9));
    });

    test('lemenő lábon (TWA 135°) a VMG negatív', () {
      final vmg = computeVmg(boatSpeedKnots: 6, twaDegrees: 135);

      // A 90° fölött a vetület előjelet vált.
      expect(vmg, lessThan(0));
    });

    test('a TWA előjele nem befolyásolja a VMG-t (cos páros)', () {
      final port = computeVmg(boatSpeedKnots: 6, twaDegrees: -45);
      final starboard = computeVmg(boatSpeedKnots: 6, twaDegrees: 45);

      expect(port, closeTo(starboard, 1e-9));
    });

    test('álló hajónál (0 kn) a VMG bármely szögnél nulla', () {
      final vmg = computeVmg(boatSpeedKnots: 0, twaDegrees: 42);

      expect(vmg, closeTo(0, 1e-9));
    });
  });
}
