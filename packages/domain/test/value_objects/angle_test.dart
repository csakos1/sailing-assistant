import 'package:domain/domain.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('Angle', () {
    group('default konstruktor', () {
      test('a megadott degrees mezőt tárolja', () {
        const a = Angle(degrees: 45);

        expect(a.degrees, equals(45));
      });

      test('nem normalize, nem validál — kívülérő érték is létrehozható', () {
        // A default const ctor a teljesítményért nem normalize-zal és
        // nem validál; ha valaki ide ad 200-at, az így marad.
        const a = Angle(degrees: 200);

        expect(a.degrees, equals(200));
      });
    });

    group('checked factory', () {
      test('érvényes input -> Angle', () {
        final a = Angle.checked(degrees: 45);

        expect(a.degrees, equals(45));
      });

      test('normalize-zal a [-180, +180) tartományba', () {
        // Tartományon belüli értékek változatlanok.
        expect(Angle.checked(degrees: 0).degrees, equals(0));
        expect(Angle.checked(degrees: 90).degrees, equals(90));
        expect(Angle.checked(degrees: -90).degrees, equals(-90));
        expect(Angle.checked(degrees: 179).degrees, equals(179));
        expect(Angle.checked(degrees: -179).degrees, equals(-179));

        // Tartomány-határok: +180 a felső szél, -180-ra esik (felső kizárt).
        expect(Angle.checked(degrees: 180).degrees, equals(-180));
        expect(Angle.checked(degrees: -180).degrees, equals(-180));

        // Tartományon kívüli értékek wrap-elnek.
        expect(Angle.checked(degrees: 181).degrees, equals(-179));
        expect(Angle.checked(degrees: -181).degrees, equals(179));
        expect(Angle.checked(degrees: 270).degrees, equals(-90));
        expect(Angle.checked(degrees: -270).degrees, equals(90));
        expect(Angle.checked(degrees: 360).degrees, equals(0));
        expect(Angle.checked(degrees: -360).degrees, equals(0));
        expect(Angle.checked(degrees: 540).degrees, equals(-180));
        expect(Angle.checked(degrees: -540).degrees, equals(-180));
        expect(Angle.checked(degrees: 720).degrees, equals(0));
      });

      test('NaN -> ArgumentError', () {
        expect(
          () => Angle.checked(degrees: double.nan),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('infinity -> ArgumentError', () {
        expect(
          () => Angle.checked(degrees: double.infinity),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => Angle.checked(degrees: double.negativeInfinity),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('tryFromDegrees', () {
      test('érvényes input -> Ok(Angle)', () {
        final result = Angle.tryFromDegrees(degrees: 45);

        switch (result) {
          case Ok(value: final a):
            expect(a.degrees, equals(45));
          case Err():
            fail('Expected Ok, got Err');
        }
      });

      test('NaN -> Err(AngleNotFinite)', () {
        final result = Angle.tryFromDegrees(degrees: double.nan);

        switch (result) {
          case Ok():
            fail('Expected Err, got Ok');
          case Err(error: final err):
            expect(err, isA<AngleNotFinite>());
            final notFinite = err as AngleNotFinite;
            expect(notFinite.value.isNaN, isTrue);
        }
      });

      test('infinity -> Err(AngleNotFinite)', () {
        final result = Angle.tryFromDegrees(
          degrees: double.negativeInfinity,
        );

        switch (result) {
          case Ok():
            fail('Expected Err, got Ok');
          case Err(error: final err):
            expect(err, isA<AngleNotFinite>());
            final notFinite = err as AngleNotFinite;
            expect(notFinite.value.isInfinite, isTrue);
        }
      });
    });

    group('equality', () {
      test('azonos degrees -> egyenlő', () {
        const a = Angle(degrees: 45);
        const b = Angle(degrees: 45);

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('különböző degrees -> nem egyenlő', () {
        const a = Angle(degrees: 45);
        const b = Angle(degrees: -45);

        expect(a, isNot(equals(b)));
      });

      test(
        'normalize-zott Angle != default ctor-ral kapott nem-normalize-zott',
        () {
          // A normalize a tryFromDegrees-ben/checked-ben 200-at -160-ra
          // teszi, de a default ctor 200-at változtatás nélkül tárolja.
          // Literál szempontból a két érték különbözik — fontos szemantika.
          const literal = Angle(degrees: 200);
          final normalized = Angle.checked(degrees: 200);

          expect(literal.degrees, equals(200));
          expect(normalized.degrees, equals(-160));
          expect(literal, isNot(equals(normalized)));
        },
      );
    });

    group('toString', () {
      test('debug formátumot ad', () {
        const a = Angle(degrees: -45);

        expect(a.toString(), equals('Angle(deg: -45.0)'));
      });
    });

    group('operator +', () {
      test('0 + 0 = 0', () {
        expect(
          const Angle(degrees: 0) + const Angle(degrees: 0),
          equals(const Angle(degrees: 0)),
        );
      });

      test('tartományon belüli összeg változatlan', () {
        expect(
          const Angle(degrees: 30) + const Angle(degrees: 60),
          equals(const Angle(degrees: 90)),
        );
        expect(
          const Angle(degrees: -30) + const Angle(degrees: 60),
          equals(const Angle(degrees: 30)),
        );
      });

      test('tartományon kívüli összeg wrap-elődik [-180, +180)-ba', () {
        // 170 + 30 = 200 → wrap → -160
        expect(
          const Angle(degrees: 170) + const Angle(degrees: 30),
          equals(const Angle(degrees: -160)),
        );
        // -170 + (-30) = -200 → wrap → 160
        expect(
          const Angle(degrees: -170) + const Angle(degrees: -30),
          equals(const Angle(degrees: 160)),
        );
      });

      test('+180 a felső szélen kívül esik, -180-ra wrap-elődik', () {
        // 90 + 90 = 180 → wrap → -180 (a +180 nem érvényes)
        expect(
          const Angle(degrees: 90) + const Angle(degrees: 90),
          equals(const Angle(degrees: -180)),
        );
      });

      test('kommutatív: a + b = b + a', () {
        const a = Angle(degrees: 170);
        const b = Angle(degrees: 30);
        expect(a + b, equals(b + a));
      });
    });

    group('operator -', () {
      test('0 - 0 = 0', () {
        expect(
          const Angle(degrees: 0) - const Angle(degrees: 0),
          equals(const Angle(degrees: 0)),
        );
      });

      test('tartományon belüli különbség változatlan', () {
        expect(
          const Angle(degrees: 60) - const Angle(degrees: 30),
          equals(const Angle(degrees: 30)),
        );
        expect(
          const Angle(degrees: 30) - const Angle(degrees: 60),
          equals(const Angle(degrees: -30)),
        );
      });

      test('tartományon kívüli különbség wrap-elődik', () {
        // -170 - 30 = -200 → wrap → 160
        expect(
          const Angle(degrees: -170) - const Angle(degrees: 30),
          equals(const Angle(degrees: 160)),
        );
        // 170 - (-30) = 200 → wrap → -160
        expect(
          const Angle(degrees: 170) - const Angle(degrees: -30),
          equals(const Angle(degrees: -160)),
        );
      });

      test('nem kommutatív: a - b = -(b - a)', () {
        const a = Angle(degrees: 90);
        const b = Angle(degrees: 30);
        expect(a - b, equals(const Angle(degrees: 60)));
        expect(b - a, equals(const Angle(degrees: -60)));
      });
    });

    group('unary -', () {
      test('-Angle(0) = Angle(0)', () {
        expect(-const Angle(degrees: 0), equals(const Angle(degrees: 0)));
      });

      test('-Angle(45) = Angle(-45)', () {
        expect(-const Angle(degrees: 45), equals(const Angle(degrees: -45)));
      });

      test('-Angle(-45) = Angle(45)', () {
        expect(-const Angle(degrees: -45), equals(const Angle(degrees: 45)));
      });

      test('-Angle(-180) wrap-elődik -180-ra (a +180 nem érvényes)', () {
        // -(-180) = 180 → wrap → -180
        expect(
          -const Angle(degrees: -180),
          equals(const Angle(degrees: -180)),
        );
      });
    });
  });

  group('AngleError', () {
    test('AngleNotFinite equality value alapján', () {
      const a = AngleNotFinite(value: 1);
      const b = AngleNotFinite(value: 1);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('AngleNotFinite toString tartalmazza a value-t', () {
      const err = AngleNotFinite(value: 5);

      expect(err.toString(), contains('5'));
    });
  });
}
