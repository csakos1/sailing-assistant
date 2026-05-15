import 'package:domain/domain.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('Speed', () {
    group('default konstruktor', () {
      test('a megadott metersPerSecond mezőt tárolja', () {
        const s = Speed(metersPerSecond: 5);

        expect(s.metersPerSecond, equals(5));
      });

      test('nem validál — negatív érték is létrehozható', () {
        // A default const ctor a teljesítményért nem validál; csak akkor
        // használd ha a hívó garantálja az érvényességet.
        const s = Speed(metersPerSecond: -2);

        expect(s.metersPerSecond, equals(-2));
      });
    });

    group('checked factory', () {
      test('érvényes input -> Speed', () {
        final s = Speed.checked(metersPerSecond: 5);

        expect(s.metersPerSecond, equals(5));
      });

      test('0 elfogadott (drift, lehorgonyzott, szélcsend)', () {
        final s = Speed.checked(metersPerSecond: 0);

        expect(s.metersPerSecond, equals(0));
      });

      test('negatív -> ArgumentError', () {
        expect(
          () => Speed.checked(metersPerSecond: -1),
          throwsA(isA<ArgumentError>()),
        );
        // A 0 elfogadott, a 0 alatti bármi (akár nagyon kis negatív) hiba.
        expect(
          () => Speed.checked(metersPerSecond: -0.0001),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('NaN -> ArgumentError', () {
        expect(
          () => Speed.checked(metersPerSecond: double.nan),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('infinity -> ArgumentError', () {
        expect(
          () => Speed.checked(metersPerSecond: double.infinity),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => Speed.checked(metersPerSecond: double.negativeInfinity),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('tryFromMetersPerSecond', () {
      test('érvényes input -> Ok(Speed)', () {
        final result = Speed.tryFromMetersPerSecond(metersPerSecond: 5);

        switch (result) {
          case Ok(value: final s):
            expect(s.metersPerSecond, equals(5));
          case Err():
            fail('Expected Ok, got Err');
        }
      });

      test('0 elfogadott -> Ok(Speed)', () {
        final result = Speed.tryFromMetersPerSecond(metersPerSecond: 0);

        switch (result) {
          case Ok(value: final s):
            expect(s.metersPerSecond, equals(0));
          case Err():
            fail('Expected Ok, got Err');
        }
      });

      test('negatív -> Err(SpeedNegative)', () {
        final result = Speed.tryFromMetersPerSecond(metersPerSecond: -1);

        switch (result) {
          case Ok():
            fail('Expected Err, got Ok');
          case Err(error: final err):
            expect(err, isA<SpeedNegative>());
            final neg = err as SpeedNegative;
            expect(neg.value, equals(-1));
        }
      });

      test('NaN -> Err(SpeedNotFinite)', () {
        final result = Speed.tryFromMetersPerSecond(
          metersPerSecond: double.nan,
        );

        switch (result) {
          case Ok():
            fail('Expected Err, got Ok');
          case Err(error: final err):
            expect(err, isA<SpeedNotFinite>());
            final notFinite = err as SpeedNotFinite;
            expect(notFinite.value.isNaN, isTrue);
        }
      });

      test('infinity -> Err(SpeedNotFinite)', () {
        final result = Speed.tryFromMetersPerSecond(
          metersPerSecond: double.negativeInfinity,
        );

        switch (result) {
          case Ok():
            fail('Expected Err, got Ok');
          case Err(error: final err):
            expect(err, isA<SpeedNotFinite>());
            final notFinite = err as SpeedNotFinite;
            expect(notFinite.value.isInfinite, isTrue);
        }
      });
    });

    group('equality', () {
      test('azonos metersPerSecond -> egyenlő', () {
        const a = Speed(metersPerSecond: 5);
        const b = Speed(metersPerSecond: 5);

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('különböző metersPerSecond -> nem egyenlő', () {
        const a = Speed(metersPerSecond: 5);
        const b = Speed(metersPerSecond: 6);

        expect(a, isNot(equals(b)));
      });
    });

    group('toString', () {
      test('debug formátumot ad', () {
        const s = Speed(metersPerSecond: 5);

        expect(s.toString(), equals('Speed(m/s: 5.0)'));
      });
    });
  });

  group('SpeedError', () {
    test('SpeedNotFinite equality value alapján', () {
      const a = SpeedNotFinite(value: 1);
      const b = SpeedNotFinite(value: 1);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('SpeedNotFinite toString tartalmazza a value-t', () {
      const err = SpeedNotFinite(value: 5);

      expect(err.toString(), contains('5'));
    });

    test('SpeedNegative equality value alapján', () {
      const a = SpeedNegative(value: -1);
      const b = SpeedNegative(value: -1);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('SpeedNegative toString tartalmazza a value-t', () {
      const err = SpeedNegative(value: -3);

      expect(err.toString(), contains('-3'));
    });
  });
}
