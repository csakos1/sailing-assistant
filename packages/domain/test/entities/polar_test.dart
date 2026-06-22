import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('Polar', () {
    // Valós foretack.pol-cellák (TWA 25/85/145 × TWS 4..14 részhalmaz).
    Polar buildPolar() => Polar(
      twaAxis: const <double>[25, 85, 145],
      twsAxis: const <double>[4, 6, 8, 10, 12, 14],
      grid: const <List<double?>>[
        [5.20, 5.16, 6.43, 6.69, 6.60, 6.41],
        [6.53, 7.97, 8.48, 8.77, 9.20, 9.17],
        [6.59, 6.31, 6.65, 7.83, 8.67, 9.41],
      ],
    );

    group('konstrukció', () {
      test('érvényes bemenet → a tengelyek és a rács megmaradnak', () {
        // Arrange / Act
        final polar = buildPolar();

        // Assert
        expect(polar.twaAxis, <double>[25, 85, 145]);
        expect(polar.twsAxis, <double>[4, 6, 8, 10, 12, 14]);
        expect(polar.grid[1][3], closeTo(8.77, 1e-9));
      });

      test('a no-go küszöb 25°', () {
        expect(Polar.noGoThresholdDegrees, 25);
      });

      test('üres-vödör cellát null-ként tárol', () {
        // Arrange / Act
        final polar = Polar(
          twaAxis: const <double>[30, 90],
          twsAxis: const <double>[6, 10],
          grid: const <List<double?>>[
            [null, 7],
            [8, 9],
          ],
        );

        // Assert
        expect(polar.grid[0][0], isNull);
        expect(polar.grid[1][0], closeTo(8, 1e-9));
      });
    });

    group('immutability', () {
      test('a tengely-lista nem módosítható', () {
        final polar = buildPolar();
        expect(() => polar.twaAxis.add(180), throwsUnsupportedError);
      });

      test('a rács belső sora nem módosítható', () {
        final polar = buildPolar();
        expect(() => polar.grid[0][0] = 0, throwsUnsupportedError);
      });
    });

    group('equality (Equatable)', () {
      test('azonos tengelyek és rács → egyenlő', () {
        expect(buildPolar(), equals(buildPolar()));
      });

      test('eltérő rács-cella → nem egyenlő', () {
        final other = Polar(
          twaAxis: const <double>[25, 85, 145],
          twsAxis: const <double>[4, 6, 8, 10, 12, 14],
          grid: const <List<double?>>[
            [5.20, 5.16, 6.43, 6.69, 6.60, 6.41],
            [6.53, 7.97, 8.48, 9.99, 9.20, 9.17],
            [6.59, 6.31, 6.65, 7.83, 8.67, 9.41],
          ],
        );
        expect(buildPolar(), isNot(equals(other)));
      });
    });

    group('invariáns-assertek', () {
      test('üres TWA-tengely → AssertionError', () {
        expect(
          () => Polar(
            twaAxis: const <double>[],
            twsAxis: const <double>[4],
            grid: const <List<double?>>[],
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('nem szigorúan növekvő TWA-tengely → AssertionError', () {
        expect(
          () => Polar(
            twaAxis: const <double>[85, 25],
            twsAxis: const <double>[4],
            grid: const <List<double?>>[
              [5],
              [6],
            ],
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('tartományon kívüli TWA (>180) → AssertionError', () {
        expect(
          () => Polar(
            twaAxis: const <double>[25, 200],
            twsAxis: const <double>[4],
            grid: const <List<double?>>[
              [5],
              [6],
            ],
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('a rács sor-száma nem egyezik a TWA-tengellyel → Assertion', () {
        expect(
          () => Polar(
            twaAxis: const <double>[25, 85],
            twsAxis: const <double>[4],
            grid: const <List<double?>>[
              [5],
            ],
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('a rács oszlop-száma nem egyezik a TWS-tengellyel → Assertion', () {
        expect(
          () => Polar(
            twaAxis: const <double>[25],
            twsAxis: const <double>[4, 6],
            grid: const <List<double?>>[
              [5],
            ],
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });
  });
}
