import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('LookupTargetSpeed', () {
    const lookup = LookupTargetSpeed();

    // Valós foretack.pol-cellák (TWA 25/85/145 × TWS 4..14 részhalmaz).
    final polar = Polar(
      twaAxis: const <double>[25, 85, 145],
      twsAxis: const <double>[4, 6, 8, 10, 12, 14],
      grid: const <List<double?>>[
        [5.20, 5.16, 6.43, 6.69, 6.60, 6.41],
        [6.53, 7.97, 8.48, 8.77, 9.20, 9.17],
        [6.59, 6.31, 6.65, 7.83, 8.67, 9.41],
      ],
    );

    group('exact grid-találat', () {
      test('rács-ponton a cella értékét adja', () {
        // Arrange / Act
        final target = lookup(polar: polar, twaDegrees: 85, twsKnots: 10);

        // Assert
        expect(target, closeTo(8.77, 1e-9));
      });

      test('a no-go határán (25°) még van target', () {
        final target = lookup(polar: polar, twaDegrees: 25, twsKnots: 10);
        expect(target, closeTo(6.69, 1e-9));
      });
    });

    group('interpoláció', () {
      test('TWS-ben félúton bilineárisan interpolál', () {
        // TWS 11 a 10 (8.77) és 12 (9.20) között, TWA 85 rács-ponton.
        final target = lookup(polar: polar, twaDegrees: 85, twsKnots: 11);
        expect(target, closeTo(8.985, 1e-9));
      });

      test('TWA-ban félúton bilineárisan interpolál', () {
        // TWA 55 a 25 (5.20) és 85 (6.53) között, TWS 4 rács-ponton.
        final target = lookup(polar: polar, twaDegrees: 55, twsKnots: 4);
        expect(target, closeTo(5.865, 1e-9));
      });

      test('mindkét tengelyen belső pont → négy-sarok bilineáris', () {
        // TWA 55 (25↔85), TWS 11 (10↔12); a négy sarok átlaga:
        // (6.69+6.60+8.77+9.20)/4 = 7.815.
        final target = lookup(polar: polar, twaDegrees: 55, twsKnots: 11);
        expect(target, closeTo(7.815, 1e-9));
      });
    });

    group('tartomány-szél clamp', () {
      test('TWS a felső szél fölött → az utolsó oszlopra clamp', () {
        final target = lookup(polar: polar, twaDegrees: 85, twsKnots: 20);
        expect(target, closeTo(9.17, 1e-9));
      });

      test('TWS az alsó szél alatt → az első oszlopra clamp', () {
        final target = lookup(polar: polar, twaDegrees: 85, twsKnots: 2);
        expect(target, closeTo(6.53, 1e-9));
      });

      test('TWA a felső szél fölött → az utolsó sorra clamp', () {
        final target = lookup(polar: polar, twaDegrees: 170, twsKnots: 10);
        expect(target, closeTo(7.83, 1e-9));
      });
    });

    group('no-go', () {
      test('a küszöb alatti TWA → null', () {
        final target = lookup(polar: polar, twaDegrees: 20, twsKnots: 10);
        expect(target, isNull);
      });

      test('épp a küszöb alatt (24.9°) → null', () {
        final target = lookup(polar: polar, twaDegrees: 24.9, twsKnots: 10);
        expect(target, isNull);
      });
    });

    group('halz-szimmetria', () {
      test('negatív (port) TWA ugyanazt adja, mint a pozitív', () {
        final port = lookup(polar: polar, twaDegrees: -85, twsKnots: 10);
        final starboard = lookup(polar: polar, twaDegrees: 85, twsKnots: 10);
        expect(port, equals(starboard));
      });
    });

    group('védőháló', () {
      test('NaN TWA → null', () {
        final target = lookup(
          polar: polar,
          twaDegrees: double.nan,
          twsKnots: 10,
        );
        expect(target, isNull);
      });

      test('végtelen TWS → null', () {
        final target = lookup(
          polar: polar,
          twaDegrees: 85,
          twsKnots: double.infinity,
        );
        expect(target, isNull);
      });
    });

    group('üres-vödör interpoláció', () {
      // 2×2 rács egy hiányzó sarokkal a (30,6) cellában.
      final sparse = Polar(
        twaAxis: const <double>[30, 90],
        twsAxis: const <double>[6, 10],
        grid: const <List<double?>>[
          [null, 7],
          [8, 9],
        ],
      );

      test('a hiányzó cella pontján → null', () {
        final target = lookup(polar: sparse, twaDegrees: 30, twsKnots: 6);
        expect(target, isNull);
      });

      test('cella-középen a meglévő sarkokból interpolál', () {
        // (0.5,0.5): a megmaradó (7,8,9) sarkok újranormált átlaga = 8.
        final target = lookup(polar: sparse, twaDegrees: 60, twsKnots: 8);
        expect(target, closeTo(8, 1e-9));
      });
    });
  });
}
