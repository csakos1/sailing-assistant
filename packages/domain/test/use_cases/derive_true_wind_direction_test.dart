import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const sut = DeriveTrueWindDirection();
  final ts = DateTime.utc(2026);

  BoatState boat({Bearing? cog, Speed? sog}) => BoatState(
    lastUpdate: ts,
    courseOverGround: cog,
    speedOverGround: sog,
  );

  WindData wind({Angle? twaBow}) => WindData(
    apparentAngle: const Angle(degrees: 0),
    apparentSpeed: const Speed(metersPerSecond: 5),
    timestamp: ts,
    trueAngleWater: twaBow,
  );

  group('DeriveTrueWindDirection', () {
    test('derives live TWD as COG + bow TWA above the SOG gate', () {
      // Adott: COG 300, bow TWA -50 (port), SOG 3 m/s (> 0.7717).
      final result = sut(
        boatState: boat(
          cog: const Bearing.true_(300),
          sog: const Speed(metersPerSecond: 3),
        ),
        wind: wind(twaBow: const Angle(degrees: -50)),
      );
      // Akkor: TWD = 300 + (-50) = 250, trueNorth, minőség live.
      expect(result.quality, TwdQuality.live);
      expect(
        result.twd,
        isA<Bearing>()
            .having((b) => b.degrees, 'degrees', closeTo(250, 1e-9))
            .having(
              (b) => b.reference,
              'reference',
              BearingReference.trueNorth,
            ),
      );
    });

    test('wraps mod 360 regardless of bow TWA sign convention', () {
      // Adott: COG 350, bow TWA 20 → 370 → 10 (a + operátor mod-360-al wrap).
      final result = sut(
        boatState: boat(
          cog: const Bearing.true_(350),
          sog: const Speed(metersPerSecond: 3),
        ),
        wind: wind(twaBow: const Angle(degrees: 20)),
      );
      expect(
        result.twd,
        isA<Bearing>().having((b) => b.degrees, 'degrees', closeTo(10, 1e-9)),
      );
    });

    test('holds the last good TWD when SOG is below the gate', () {
      // Adott: SOG 0.5 m/s (< 0.7717), van utolsó jó TWD.
      const lastGood = Bearing.true_(123);
      final result = sut(
        boatState: boat(
          cog: const Bearing.true_(300),
          sog: const Speed(metersPerSecond: 0.5),
        ),
        wind: wind(twaBow: const Angle(degrees: -50)),
        lastGoodTwd: lastGood,
      );
      // Akkor: held, az utolsó jó értékkel (a friss COG-ot eldobja).
      expect(result.quality, TwdQuality.held);
      expect(result.twd, lastGood);
    });

    test('is unavailable below the gate with no last good TWD', () {
      final result = sut(
        boatState: boat(
          cog: const Bearing.true_(300),
          sog: const Speed(metersPerSecond: 0.5),
        ),
        wind: wind(twaBow: const Angle(degrees: -50)),
      );
      expect(result.quality, TwdQuality.unavailable);
      expect(result.twd, isNull);
    });

    test('does not derive exactly at the gate (strict greater-than)', () {
      // Határeset: SOG == 0.7717 → NEM live (szigorú >), held marad.
      final result = sut(
        boatState: boat(
          cog: const Bearing.true_(300),
          sog: const Speed(metersPerSecond: 0.7717),
        ),
        wind: wind(twaBow: const Angle(degrees: -50)),
        lastGoodTwd: const Bearing.true_(123),
      );
      expect(result.quality, TwdQuality.held);
    });

    test('holds the last good TWD when COG is missing', () {
      final result = sut(
        boatState: boat(sog: const Speed(metersPerSecond: 3)),
        wind: wind(twaBow: const Angle(degrees: -50)),
        lastGoodTwd: const Bearing.true_(123),
      );
      expect(result.quality, TwdQuality.held);
      expect(result.twd, const Bearing.true_(123));
    });

    test('holds the last good TWD when bow TWA is missing', () {
      final result = sut(
        boatState: boat(
          cog: const Bearing.true_(300),
          sog: const Speed(metersPerSecond: 3),
        ),
        wind: wind(),
        lastGoodTwd: const Bearing.true_(123),
      );
      expect(result.quality, TwdQuality.held);
    });
  });
}
