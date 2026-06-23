import 'dart:math';

import 'package:domain/src/entities/polar.dart';
import 'package:domain/src/use_cases/lookup_target_speed.dart';
import 'package:domain/src/use_cases/lookup_target_vmg.dart';
import 'package:test/test.dart';

void main() {
  const lookupTargetVmg = LookupTargetVmg();
  const lookupTargetSpeed = LookupTargetSpeed();

  // Determinisztikus kis polár. A TWS = 12 csomós oszlop a tengely utolsó
  // eleme (perem), így a lookup tisztán a 2. oszlopot használja.
  final polar = Polar(
    twaAxis: const [25, 50, 90, 130, 180],
    twsAxis: const [6, 12],
    grid: const [
      [3.0, 3.5],
      [5.0, 5.8],
      [6.0, 7.0],
      [5.5, 6.5],
      [4.0, 5.0],
    ],
  );

  group('LookupTargetVmg', () {
    test(
      'felmenőn pozitív VMG, legalább akkora, mint az aktuális szögön',
      () {
        // Given: felmenő TWA (45°), TWS 12 csomó. A sáv optimuma a max VMG.
        const tws = 12.0;
        final atFortyFive = lookupTargetSpeed(
          polar: polar,
          twaDegrees: 45,
          twsKnots: tws,
        )!;
        final vmgAtFortyFive = atFortyFive * cos(45 * pi / 180);

        // When.
        final result = lookupTargetVmg(
          polar: polar,
          twaDegrees: 45,
          twsKnots: tws,
        );

        // Then: az optimum a sáv maximuma, így >= a 45°-os VMG, és pozitív.
        expect(result, isNotNull);
        expect(result, greaterThan(0));
        expect(result, greaterThanOrEqualTo(vmgAtFortyFive));
      },
    );

    test(
      'lemenőn negatív VMG, legalább annyira mély, mint az aktuális szögön',
      () {
        // Given: lemenő TWA (150°). A sáv optimuma a legnegatívabb VMG.
        const tws = 12.0;
        final atOneFifty = lookupTargetSpeed(
          polar: polar,
          twaDegrees: 150,
          twsKnots: tws,
        )!;
        final vmgAtOneFifty = atOneFifty * cos(150 * pi / 180);

        // When.
        final result = lookupTargetVmg(
          polar: polar,
          twaDegrees: 150,
          twsKnots: tws,
        );

        // Then: a legnegatívabb VMG a cél, így <= a 150°-os (mély) VMG.
        expect(result, isNotNull);
        expect(result, lessThan(0));
        expect(result, lessThanOrEqualTo(vmgAtOneFifty));
      },
    );

    test('a halz-előjel nem számít: a |TWA| dönti el a sávot', () {
      // Given/When: ±45° ugyanazt a felmenő sávot pásztázza.
      final port = lookupTargetVmg(
        polar: polar,
        twaDegrees: -45,
        twsKnots: 12,
      );
      final starboard = lookupTargetVmg(
        polar: polar,
        twaDegrees: 45,
        twsKnots: 12,
      );

      // Then.
      expect(port, starboard);
    });

    test('üres rács-környezetben null', () {
      // Given: minden vödör üres.
      final emptyPolar = Polar(
        twaAxis: const [25, 90, 180],
        twsAxis: const [6, 12],
        grid: const [
          [null, null],
          [null, null],
          [null, null],
        ],
      );

      // When.
      final result = lookupTargetVmg(
        polar: emptyPolar,
        twaDegrees: 45,
        twsKnots: 12,
      );

      // Then.
      expect(result, isNull);
    });

    test('nem-véges bemenetre null', () {
      expect(
        lookupTargetVmg(polar: polar, twaDegrees: double.nan, twsKnots: 12),
        isNull,
      );
      expect(
        lookupTargetVmg(
          polar: polar,
          twaDegrees: 45,
          twsKnots: double.infinity,
        ),
        isNull,
      );
    });
  });
}
