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

        // Then: az optimum a sáv maximuma, így >= a 45°-os VMG, és pozitív;
        // az optimum-szög a felmenő sávban (pozitív magnitúdó).
        expect(result, isNotNull);
        expect(result?.vmgKnots, greaterThan(0));
        expect(result?.vmgKnots, greaterThanOrEqualTo(vmgAtFortyFive));
        expect(result?.optimumTwaDegrees, inInclusiveRange(25, 89));
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

        // Then: a legnegatívabb VMG a cél, így <= a 150°-os (mély) VMG; az
        // optimum-szög a lemenő sávban (pozitív magnitúdó, > 90).
        expect(result, isNotNull);
        expect(result?.vmgKnots, lessThan(0));
        expect(result?.vmgKnots, lessThanOrEqualTo(vmgAtOneFifty));
        expect(result?.optimumTwaDegrees, inInclusiveRange(91, 180));
      },
    );

    test('a halz-előjel nem számít: a |TWA| dönti el a sávot', () {
      // Given/When: ±45° ugyanazt a felmenő sávot pásztázza, így a teljes
      // result-rekord (VMG + optimum-szög) is azonos.
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

      // Then: a rekordok strukturálisan egyenlők.
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

    test('lemenőn az utolsó kitöltött TWA-sornál megáll', () {
      // Given: a 180°-os sor teljesen üres (ADR 0058, P.4). A 175°-os sor
      // értéke nem terjedhet ki 179°-ig, ezért az optimum 175°:
      // 6.4 × cos 175° = -6.3756 (és nem 180° / -6.4).
      final trimmed = Polar(
        twaAxis: const <double>[25, 50, 90, 130, 175, 180],
        twsAxis: const <double>[6, 12],
        grid: const <List<double?>>[
          [3.0, 3.5],
          [5.0, 5.8],
          [6.0, 7.0],
          [5.5, 6.5],
          [5.0, 6.4],
          [null, null],
        ],
      );

      // When.
      final result = lookupTargetVmg(
        polar: trimmed,
        twaDegrees: 150,
        twsKnots: 12,
      );

      // Then.
      expect(result?.optimumTwaDegrees, 175);
      expect(result?.vmgKnots, closeTo(-6.37565, 1e-4));
    });

    test('a legalsó TWS-oszlop alatt a horgony arányosan skáláz', () {
      // Given: a TWS 3 csomó a 6 csomós első oszlop fele (ADR 0058 D5);
      // a skálázás minden szögön azonos, így az optimum-szög nem változik.
      final atFirstColumn = lookupTargetVmg(
        polar: polar,
        twaDegrees: 45,
        twsKnots: 6,
      );

      // When.
      final belowFirstColumn = lookupTargetVmg(
        polar: polar,
        twaDegrees: 45,
        twsKnots: 3,
      );

      // Then: az első expect már őrzi a nem-null-t, a `!` ezért biztos.
      expect(atFirstColumn, isNotNull);
      expect(
        belowFirstColumn?.vmgKnots,
        closeTo(atFirstColumn!.vmgKnots / 2, 1e-9),
      );
      expect(
        belowFirstColumn?.optimumTwaDegrees,
        atFirstColumn.optimumTwaDegrees,
      );
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
