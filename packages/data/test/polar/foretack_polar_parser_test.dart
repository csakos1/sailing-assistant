import 'package:data/src/polar/foretack_polar_parser.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  group('parseForetackPolar', () {
    // Valós foretack.pol-cellák (TWA 25/85/145 × TWS 4/6) a header
    // dialektusával; a 0.00 a 2 kn-es és a magas-TWS oszlopokban üres
    // vödröt jelöl.
    const validPol =
        'twa/tws;4;6\n'
        '25;5.20;5.16\n'
        '85;6.53;7.97\n'
        '145;6.59;6.31\n';

    Polar unwrap(Result<Polar, PolarLoadError> result) {
      expect(result, isA<Ok<Polar, PolarLoadError>>());
      return (result as Ok<Polar, PolarLoadError>).value;
    }

    PolarLoadError errorOf(Result<Polar, PolarLoadError> result) {
      expect(result, isA<Err<Polar, PolarLoadError>>());
      return (result as Err<Polar, PolarLoadError>).error;
    }

    group('happy path', () {
      test('érvényes tartalom → kész Polar a helyes tengelyekkel', () {
        // Arrange / Act
        final polar = unwrap(parseForetackPolar(validPol));

        // Assert
        expect(polar.twaAxis, <double>[25, 85, 145]);
        expect(polar.twsAxis, <double>[4, 6]);
        expect(polar.grid[1][1], closeTo(7.97, 1e-9));
      });

      test('a 0.00 sentinel és az üres cella null-ra fordul', () {
        // Arrange
        const pol =
            'twa/tws;4;6;8\n'
            '25;0.00;5.16;\n';

        // Act
        final polar = unwrap(parseForetackPolar(pol));

        // Assert
        expect(polar.grid[0][0], isNull); // 0.00 sentinel
        expect(polar.grid[0][1], closeTo(5.16, 1e-9));
        expect(polar.grid[0][2], isNull); // üres cella
      });

      test('CRLF sorvégeket is tolerál', () {
        final polar = unwrap(
          parseForetackPolar('twa/tws;4\r\n25;5.20\r\n85;6.53\r\n'),
        );
        expect(polar.twaAxis, <double>[25, 85]);
      });

      test('a vezető üres sorokat átugorja', () {
        final polar = unwrap(
          parseForetackPolar('\n\ntwa/tws;4\n25;5.20\n'),
        );
        expect(polar.twsAxis, <double>[4]);
      });
    });

    group('empty', () {
      test('üres string → PolarEmpty', () {
        expect(errorOf(parseForetackPolar('')), isA<PolarEmpty>());
      });

      test('csak whitespace → PolarEmpty', () {
        expect(errorOf(parseForetackPolar('  \n\t\n')), isA<PolarEmpty>());
      });
    });

    group('malformedHeader', () {
      test('rossz prefix → PolarMalformedHeader', () {
        final error = errorOf(parseForetackPolar('foo;4;6\n25;5.2;5.1\n'));
        expect(error, isA<PolarMalformedHeader>());
      });

      test('nem-szám TWS → PolarMalformedHeader', () {
        final error = errorOf(parseForetackPolar('twa/tws;4;x\n25;5;6\n'));
        expect(error, isA<PolarMalformedHeader>());
      });

      test('nem növekvő TWS → PolarMalformedHeader', () {
        final error = errorOf(parseForetackPolar('twa/tws;6;4\n25;5;6\n'));
        expect(error, isA<PolarMalformedHeader>());
      });

      test('üres TWS-tengely → PolarMalformedHeader', () {
        expect(
          errorOf(parseForetackPolar('twa/tws\n25\n')),
          isA<PolarMalformedHeader>(),
        );
      });
    });

    group('malformedRow', () {
      test('rossz mezőszám → PolarMalformedRow a fájl-sorszámmal', () {
        // Arrange: a 25-ös sor (3. fájl-sor) egy cellával kevesebb.
        const pol =
            'twa/tws;4;6\n'
            '20;5.0;5.1\n'
            '25;5.2\n';

        // Act
        final error = errorOf(parseForetackPolar(pol));

        // Assert
        expect(error, isA<PolarMalformedRow>());
        expect((error as PolarMalformedRow).lineNumber, 3);
      });

      test('nem-szám cella → PolarMalformedRow', () {
        final error = errorOf(parseForetackPolar('twa/tws;4\n25;abc\n'));
        expect(error, isA<PolarMalformedRow>());
      });

      test('nem-szám TWA → PolarMalformedRow', () {
        final error = errorOf(parseForetackPolar('twa/tws;4\nxx;5.2\n'));
        expect(error, isA<PolarMalformedRow>());
      });

      test('tartományon kívüli TWA (>180) → PolarMalformedRow', () {
        final error = errorOf(parseForetackPolar('twa/tws;4\n200;5.2\n'));
        expect(error, isA<PolarMalformedRow>());
      });

      test('nem növekvő TWA → PolarMalformedRow', () {
        const pol = 'twa/tws;4\n85;6.5\n25;5.2\n';
        final error = errorOf(parseForetackPolar(pol));
        expect(error, isA<PolarMalformedRow>());
      });

      test('a lineNumber az üres sorok átugrásával is helyes', () {
        // A hibás sor a 4. fájl-sor (egy közbeszúrt üres sor után).
        const pol = 'twa/tws;4\n25;5.2\n\n85;bad\n';
        final error = errorOf(parseForetackPolar(pol));
        expect((error as PolarMalformedRow).lineNumber, 4);
      });
    });

    group('noUsableCells', () {
      test('csak fejléc, nincs adatsor → PolarNoUsableCells', () {
        expect(
          errorOf(parseForetackPolar('twa/tws;4;6\n')),
          isA<PolarNoUsableCells>(),
        );
      });

      test('minden cella 0.00 → PolarNoUsableCells', () {
        const pol =
            'twa/tws;4;6\n'
            '25;0.00;0.00\n'
            '85;0.00;0.00\n';
        expect(
          errorOf(parseForetackPolar(pol)),
          isA<PolarNoUsableCells>(),
        );
      });
    });
  });
}
