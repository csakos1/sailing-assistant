import 'package:domain/domain.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('Depth', () {
    group('default konstruktor', () {
      test('a megadott meters mezőt tárolja', () {
        const d = Depth(meters: 4.2);

        expect(d.meters, equals(4.2));
      });

      test('nem validál — negatív érték is létrehozható', () {
        // A default const ctor a teljesítményért nem validál; csak akkor
        // használd, ha a hívó garantálja az érvényességet.
        const d = Depth(meters: -1);

        expect(d.meters, equals(-1));
      });
    });

    group('checked factory', () {
      test('érvényes input -> Depth', () {
        final d = Depth.checked(meters: 3.4);

        expect(d.meters, equals(3.4));
      });

      test('0 elfogadott (a jeladó szintjén kiszáradt víz)', () {
        final d = Depth.checked(meters: 0);

        expect(d.meters, equals(0));
      });

      test('negatív -> ArgumentError', () {
        expect(
          () => Depth.checked(meters: -1),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => Depth.checked(meters: -0.0001),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('NaN -> ArgumentError', () {
        expect(
          () => Depth.checked(meters: double.nan),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('infinity -> ArgumentError', () {
        expect(
          () => Depth.checked(meters: double.infinity),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => Depth.checked(meters: double.negativeInfinity),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('tryFromMeters', () {
      test('érvényes input -> Ok', () {
        final result = Depth.tryFromMeters(meters: 2.5);

        expect(result, isA<Ok<Depth, DepthError>>());
        expect(
          switch (result) {
            Ok(value: final d) => d.meters,
            Err() => null,
          },
          equals(2.5),
        );
      });

      test('NaN -> Err(DepthNotFinite)', () {
        final result = Depth.tryFromMeters(meters: double.nan);

        expect(result, isA<Err<Depth, DepthError>>());
        expect(
          switch (result) {
            Ok() => null,
            Err(error: final e) => e,
          },
          isA<DepthNotFinite>(),
        );
      });

      test('infinity -> Err(DepthNotFinite)', () {
        final result = Depth.tryFromMeters(meters: double.infinity);

        expect(
          switch (result) {
            Ok() => null,
            Err(error: final e) => e,
          },
          isA<DepthNotFinite>(),
        );
      });

      test('negatív -> Err(DepthNegative)', () {
        final result = Depth.tryFromMeters(meters: -0.5);

        expect(
          switch (result) {
            Ok() => null,
            Err(error: final e) => e,
          },
          isA<DepthNegative>(),
        );
      });
    });

    group('equality', () {
      test('azonos meters -> egyenlő, azonos hashCode', () {
        const a = Depth(meters: 2.5);
        const b = Depth(meters: 2.5);

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('eltérő meters -> nem egyenlő', () {
        const a = Depth(meters: 2.5);
        const b = Depth(meters: 2.6);

        expect(a, isNot(equals(b)));
      });
    });

    test('toString olvasható', () {
      const d = Depth(meters: 2.5);

      expect(d.toString(), contains('2.5'));
    });
  });
}
