import 'package:domain/domain.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('Distance', () {
    group('default konstruktor', () {
      test('a megadott meters mezőt tárolja', () {
        const d = Distance(meters: 1500);

        expect(d.meters, equals(1500));
      });

      test('nem validál — negatív érték is létrehozható', () {
        // A default const ctor a teljesítményért nem validál; csak akkor
        // használd ha a hívó garantálja az érvényességet.
        const d = Distance(meters: -100);

        expect(d.meters, equals(-100));
      });
    });

    group('checked factory', () {
      test('érvényes input -> Distance', () {
        final d = Distance.checked(meters: 1500);

        expect(d.meters, equals(1500));
      });

      test('0 elfogadott (azonos pont, nincs elválasztás)', () {
        final d = Distance.checked(meters: 0);

        expect(d.meters, equals(0));
      });

      test('negatív -> ArgumentError', () {
        expect(
          () => Distance.checked(meters: -1),
          throwsA(isA<ArgumentError>()),
        );
        // A 0 elfogadott, a 0 alatti bármi (akár nagyon kis negatív) hiba.
        expect(
          () => Distance.checked(meters: -0.0001),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('NaN -> ArgumentError', () {
        expect(
          () => Distance.checked(meters: double.nan),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('infinity -> ArgumentError', () {
        expect(
          () => Distance.checked(meters: double.infinity),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => Distance.checked(meters: double.negativeInfinity),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('tryFromMeters', () {
      test('érvényes input -> Ok(Distance)', () {
        final result = Distance.tryFromMeters(meters: 1500);

        switch (result) {
          case Ok(value: final d):
            expect(d.meters, equals(1500));
          case Err():
            fail('Expected Ok, got Err');
        }
      });

      test('0 elfogadott -> Ok(Distance)', () {
        final result = Distance.tryFromMeters(meters: 0);

        switch (result) {
          case Ok(value: final d):
            expect(d.meters, equals(0));
          case Err():
            fail('Expected Ok, got Err');
        }
      });

      test('negatív -> Err(DistanceNegative)', () {
        final result = Distance.tryFromMeters(meters: -1);

        switch (result) {
          case Ok():
            fail('Expected Err, got Ok');
          case Err(error: final err):
            expect(err, isA<DistanceNegative>());
            final neg = err as DistanceNegative;
            expect(neg.value, equals(-1));
        }
      });

      test('NaN -> Err(DistanceNotFinite)', () {
        final result = Distance.tryFromMeters(meters: double.nan);

        switch (result) {
          case Ok():
            fail('Expected Err, got Ok');
          case Err(error: final err):
            expect(err, isA<DistanceNotFinite>());
            final notFinite = err as DistanceNotFinite;
            expect(notFinite.value.isNaN, isTrue);
        }
      });

      test('infinity -> Err(DistanceNotFinite)', () {
        final result = Distance.tryFromMeters(
          meters: double.negativeInfinity,
        );

        switch (result) {
          case Ok():
            fail('Expected Err, got Ok');
          case Err(error: final err):
            expect(err, isA<DistanceNotFinite>());
            final notFinite = err as DistanceNotFinite;
            expect(notFinite.value.isInfinite, isTrue);
        }
      });
    });

    group('equality', () {
      test('azonos meters -> egyenlő', () {
        const a = Distance(meters: 1500);
        const b = Distance(meters: 1500);

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('különböző meters -> nem egyenlő', () {
        const a = Distance(meters: 1500);
        const b = Distance(meters: 1501);

        expect(a, isNot(equals(b)));
      });
    });

    group('toString', () {
      test('debug formátumot ad', () {
        const d = Distance(meters: 1500);

        expect(d.toString(), equals('Distance(m: 1500.0)'));
      });
    });
  });

  group('DistanceError', () {
    test('DistanceNotFinite equality value alapján', () {
      const a = DistanceNotFinite(value: 1);
      const b = DistanceNotFinite(value: 1);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('DistanceNotFinite toString tartalmazza a value-t', () {
      const err = DistanceNotFinite(value: 5);

      expect(err.toString(), contains('5'));
    });

    test('DistanceNegative equality value alapján', () {
      const a = DistanceNegative(value: -1);
      const b = DistanceNegative(value: -1);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('DistanceNegative toString tartalmazza a value-t', () {
      const err = DistanceNegative(value: -3);

      expect(err.toString(), contains('-3'));
    });
  });
}
