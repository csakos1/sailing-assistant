import 'package:domain/domain.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('Bearing', () {
    group('default konstruktor', () {
      test('a megadott degrees/reference mezőket tárolja', () {
        const b = Bearing(degrees: 90, reference: BearingReference.trueNorth);

        expect(b.degrees, equals(90));
        expect(b.reference, equals(BearingReference.trueNorth));
      });

      test('nem normalize, nem validál — kívülérő érték is létrehozható', () {
        // A default const ctor a teljesítményért nem normalize-zal és
        // nem validál; ha valaki ide ad 365-öt, az így marad.
        const b = Bearing(degrees: 365, reference: BearingReference.trueNorth);

        expect(b.degrees, equals(365));
      });
    });

    group('checked factory', () {
      test('érvényes input -> Bearing', () {
        final b = Bearing.checked(
          degrees: 90,
          reference: BearingReference.trueNorth,
        );

        expect(b.degrees, equals(90));
        expect(b.reference, equals(BearingReference.trueNorth));
      });

      test('normalize-zal a [0, 360) tartományba', () {
        const ref = BearingReference.trueNorth;
        expect(
          Bearing.checked(degrees: 365, reference: ref).degrees,
          equals(5),
        );
        expect(
          Bearing.checked(degrees: -10, reference: ref).degrees,
          equals(350),
        );
        expect(
          Bearing.checked(degrees: 360, reference: ref).degrees,
          equals(0),
        );
        expect(
          Bearing.checked(degrees: 720, reference: ref).degrees,
          equals(0),
        );
        expect(
          Bearing.checked(degrees: -720, reference: ref).degrees,
          equals(0),
        );
      });

      test('NaN -> ArgumentError', () {
        expect(
          () => Bearing.checked(
            degrees: double.nan,
            reference: BearingReference.trueNorth,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('infinity -> ArgumentError', () {
        expect(
          () => Bearing.checked(
            degrees: double.infinity,
            reference: BearingReference.trueNorth,
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => Bearing.checked(
            degrees: double.negativeInfinity,
            reference: BearingReference.trueNorth,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('tryFromDegrees', () {
      test('érvényes input -> Ok(Bearing)', () {
        final result = Bearing.tryFromDegrees(
          degrees: 90,
          reference: BearingReference.magneticNorth,
        );

        switch (result) {
          case Ok(value: final b):
            expect(b.degrees, equals(90));
            expect(b.reference, equals(BearingReference.magneticNorth));
          case Err():
            fail('Expected Ok, got Err');
        }
      });

      test(
        'normalize-zal a [0, 360) tartományba pozitív és negatív bemenetekre',
        () {
          const ref = BearingReference.trueNorth;

          Bearing okOrFail(double deg) {
            final r = Bearing.tryFromDegrees(degrees: deg, reference: ref);
            switch (r) {
              case Ok(value: final b):
                return b;
              case Err():
                fail('Expected Ok, got Err for $deg');
            }
          }

          expect(okOrFail(365).degrees, equals(5));
          expect(okOrFail(-10).degrees, equals(350));
          expect(okOrFail(360).degrees, equals(0));
          expect(okOrFail(720).degrees, equals(0));
          expect(okOrFail(-720).degrees, equals(0));
        },
      );

      test('NaN -> Err(BearingNotFinite)', () {
        final result = Bearing.tryFromDegrees(
          degrees: double.nan,
          reference: BearingReference.trueNorth,
        );

        switch (result) {
          case Ok():
            fail('Expected Err, got Ok');
          case Err(error: final err):
            expect(err, isA<BearingNotFinite>());
            final notFinite = err as BearingNotFinite;
            expect(notFinite.value.isNaN, isTrue);
        }
      });

      test('infinity -> Err(BearingNotFinite)', () {
        final result = Bearing.tryFromDegrees(
          degrees: double.negativeInfinity,
          reference: BearingReference.trueNorth,
        );

        switch (result) {
          case Ok():
            fail('Expected Err, got Ok');
          case Err(error: final err):
            expect(err, isA<BearingNotFinite>());
            final notFinite = err as BearingNotFinite;
            expect(notFinite.value.isInfinite, isTrue);
        }
      });
    });

    group('equality', () {
      test('azonos degrees és reference -> egyenlő', () {
        const a = Bearing(degrees: 90, reference: BearingReference.trueNorth);
        const b = Bearing(degrees: 90, reference: BearingReference.trueNorth);

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('különböző degrees -> nem egyenlő', () {
        const a = Bearing(degrees: 90, reference: BearingReference.trueNorth);
        const b = Bearing(degrees: 91, reference: BearingReference.trueNorth);

        expect(a, isNot(equals(b)));
      });

      test(
        'különböző reference -> nem egyenlő, akkor sem ha degrees egyezik',
        () {
          const a = Bearing(degrees: 90, reference: BearingReference.trueNorth);
          const b = Bearing(
            degrees: 90,
            reference: BearingReference.magneticNorth,
          );

          expect(a, isNot(equals(b)));
        },
      );

      test(
        'normalize-zott Bearing != default ctor-ral kapott nem-normalize-zott',
        () {
          // A normalize a tryFromDegrees-ben/checked-ben 360-at 0-ra teszi,
          // de a default ctor 360-ot változtatás nélkül tárolja.
          // Literál szempontból a két érték különbözik — fontos szemantika.
          const literal = Bearing(
            degrees: 360,
            reference: BearingReference.trueNorth,
          );
          final normalized = Bearing.checked(
            degrees: 360,
            reference: BearingReference.trueNorth,
          );

          expect(literal.degrees, equals(360));
          expect(normalized.degrees, equals(0));
          expect(literal, isNot(equals(normalized)));
        },
      );
    });

    group('toString', () {
      test('debug formátumot ad reference névvel', () {
        const b = Bearing(degrees: 270, reference: BearingReference.trueNorth);

        expect(b.toString(), equals('Bearing(deg: 270.0, ref: trueNorth)'));
      });
    });

    group('Bearing.true_ named ctor', () {
      test('a degrees mezőt tárolja és reference == trueNorth', () {
        const b = Bearing.true_(90);
        expect(b.degrees, equals(90));
        expect(b.reference, equals(BearingReference.trueNorth));
      });

      test('const-elhető (const-context-ben is használható)', () {
        const b = Bearing.true_(180);
        expect(b, equals(const Bearing.true_(180)));
      });

      test('nem normalize, nem validál — kívülérő érték is létrehozható', () {
        const b = Bearing.true_(365);
        expect(b.degrees, equals(365));
      });
    });

    group('Bearing.magnetic_ named ctor', () {
      test('a degrees mezőt tárolja és reference == magneticNorth', () {
        const b = Bearing.magnetic_(270);
        expect(b.degrees, equals(270));
        expect(b.reference, equals(BearingReference.magneticNorth));
      });

      test('const-elhető', () {
        const b = Bearing.magnetic_(45);
        expect(b, equals(const Bearing.magnetic_(45)));
      });
    });

    group('operator - (Bearing - Bearing -> Angle)', () {
      test('azonos bearing → Angle(0)', () {
        const b = Bearing.true_(100);
        expect(b - b, equals(const Angle(degrees: 0)));
      });

      test('tartományon belüli különbség', () {
        expect(
          const Bearing.true_(100) - const Bearing.true_(60),
          equals(const Angle(degrees: 40)),
        );
        expect(
          const Bearing.true_(60) - const Bearing.true_(100),
          equals(const Angle(degrees: -40)),
        );
      });

      test('359° → 1° wrap-around: rövidebb út jobbra (+20°)', () {
        // 10 - 350 = -340 → wrap → +20 (jobbra 20°, nem balra 340°)
        expect(
          const Bearing.true_(10) - const Bearing.true_(350),
          equals(const Angle(degrees: 20)),
        );
      });

      test('1° → 359° wrap-around: rövidebb út balra (-20°)', () {
        // 350 - 10 = 340 → wrap → -20 (balra 20°, nem jobbra 340°)
        expect(
          const Bearing.true_(350) - const Bearing.true_(10),
          equals(const Angle(degrees: -20)),
        );
      });

      test('180°-os fordulás → Angle(-180)', () {
        // 180 - 0 = 180 → wrap → -180 (a +180 nem érvényes Angle-ben)
        expect(
          const Bearing.true_(180) - const Bearing.true_(0),
          equals(const Angle(degrees: -180)),
        );
      });

      test('eltérő reference → AssertionError (dev mode)', () {
        const t = Bearing.true_(100);
        const m = Bearing.magnetic_(100);
        expect(() => t - m, throwsA(isA<AssertionError>()));
        expect(() => m - t, throwsA(isA<AssertionError>()));
      });
    });

    group('operator + (Bearing + Angle -> Bearing)', () {
      test('tartományon belüli eltolás', () {
        expect(
          const Bearing.true_(100) + const Angle(degrees: 45),
          equals(const Bearing.true_(145)),
        );
      });

      test('pozitív wrap: 350 + 20 = 10', () {
        expect(
          const Bearing.true_(350) + const Angle(degrees: 20),
          equals(const Bearing.true_(10)),
        );
      });

      test('negatív wrap: 10 + (-20) = 350', () {
        expect(
          const Bearing.true_(10) + const Angle(degrees: -20),
          equals(const Bearing.true_(350)),
        );
      });

      test('reference megőrződik (magnetic + delta → magnetic)', () {
        final result = const Bearing.magnetic_(100) + const Angle(degrees: 30);
        expect(result.degrees, equals(130));
        expect(result.reference, equals(BearingReference.magneticNorth));
      });

      test('TWD = headingTrue + TWA tipikus eset', () {
        const heading = Bearing.true_(100);
        const twa = Angle(degrees: 45);
        expect(heading + twa, equals(const Bearing.true_(145)));
      });
    });
  });

  group('BearingError', () {
    test('BearingNotFinite equality value alapján', () {
      const a = BearingNotFinite(value: 1);
      const b = BearingNotFinite(value: 1);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('BearingNotFinite toString tartalmazza a value-t', () {
      const err = BearingNotFinite(value: 5);

      expect(err.toString(), contains('5'));
    });
  });
}
