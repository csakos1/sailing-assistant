import 'package:domain/domain.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('Coordinate', () {
    group('default konstruktor', () {
      test('a megadott lat/lon mezőket tárolja', () {
        const coord = Coordinate(latitude: 46.5, longitude: 18);

        expect(coord.latitude, equals(46.5));
        expect(coord.longitude, equals(18.0));
      });

      test('nem validál — kívülérő érték is létrehozható (a hívó felel)', () {
        // A default const ctor a teljesítményért nem validál; ha valaki
        // ide kerget egy érvénytelen értéket, az a hívó bug-ja.
        const coord = Coordinate(latitude: 999, longitude: -999);

        expect(coord.latitude, equals(999));
        expect(coord.longitude, equals(-999));
      });
    });

    group('checked factory', () {
      test('érvényes input esetén Coordinate-ot ad vissza', () {
        final coord = Coordinate.checked(latitude: 46.5, longitude: 18);

        expect(coord.latitude, equals(46.5));
        expect(coord.longitude, equals(18.0));
      });

      test('intervallum-határértékeket elfogadja (lat: ±90, lon: ±180)', () {
        expect(
          () => Coordinate.checked(latitude: -90, longitude: -180),
          returnsNormally,
        );
        expect(
          () => Coordinate.checked(latitude: 90, longitude: 180),
          returnsNormally,
        );
      });

      test('latitude tartományon kívül -> ArgumentError', () {
        expect(
          () => Coordinate.checked(latitude: 90.1, longitude: 0),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => Coordinate.checked(latitude: -90.1, longitude: 0),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('longitude tartományon kívül -> ArgumentError', () {
        expect(
          () => Coordinate.checked(latitude: 0, longitude: 180.1),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => Coordinate.checked(latitude: 0, longitude: -180.1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('NaN -> ArgumentError', () {
        expect(
          () => Coordinate.checked(latitude: double.nan, longitude: 0),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => Coordinate.checked(latitude: 0, longitude: double.nan),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('infinity -> ArgumentError', () {
        expect(
          () => Coordinate.checked(latitude: double.infinity, longitude: 0),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => Coordinate.checked(
            latitude: 0,
            longitude: double.negativeInfinity,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('tryFromDegrees', () {
      test('érvényes input -> Ok(Coordinate)', () {
        final result = Coordinate.tryFromDegrees(
          latitude: 46.5,
          longitude: 18,
        );

        switch (result) {
          case Ok(value: final coord):
            expect(coord.latitude, equals(46.5));
            expect(coord.longitude, equals(18.0));
          case Err():
            fail('Expected Ok, got Err');
        }
      });

      test('intervallum-határértékek elfogadottak', () {
        expect(
          Coordinate.tryFromDegrees(latitude: -90, longitude: -180),
          isA<Ok<Coordinate, CoordinateError>>(),
        );
        expect(
          Coordinate.tryFromDegrees(latitude: 90, longitude: 180),
          isA<Ok<Coordinate, CoordinateError>>(),
        );
      });

      test('latitude tartományon kívül -> Err(CoordinateOutOfRange)', () {
        final result = Coordinate.tryFromDegrees(
          latitude: 90.1,
          longitude: 0,
        );

        switch (result) {
          case Ok():
            fail('Expected Err, got Ok');
          case Err(error: final err):
            expect(err, isA<CoordinateOutOfRange>());
            final range = err as CoordinateOutOfRange;
            expect(range.field, equals('latitude'));
            expect(range.value, equals(90.1));
        }
      });

      test('longitude tartományon kívül -> Err(CoordinateOutOfRange)', () {
        final result = Coordinate.tryFromDegrees(
          latitude: 0,
          longitude: -180.5,
        );

        switch (result) {
          case Ok():
            fail('Expected Err, got Ok');
          case Err(error: final err):
            expect(err, isA<CoordinateOutOfRange>());
            final range = err as CoordinateOutOfRange;
            expect(range.field, equals('longitude'));
            expect(range.value, equals(-180.5));
        }
      });

      test('NaN latitude -> Err(CoordinateNotFinite)', () {
        final result = Coordinate.tryFromDegrees(
          latitude: double.nan,
          longitude: 0,
        );

        switch (result) {
          case Ok():
            fail('Expected Err, got Ok');
          case Err(error: final err):
            expect(err, isA<CoordinateNotFinite>());
            final notFinite = err as CoordinateNotFinite;
            expect(notFinite.field, equals('latitude'));
            expect(notFinite.value.isNaN, isTrue);
        }
      });

      test('infinity longitude -> Err(CoordinateNotFinite)', () {
        final result = Coordinate.tryFromDegrees(
          latitude: 0,
          longitude: double.negativeInfinity,
        );

        switch (result) {
          case Ok():
            fail('Expected Err, got Ok');
          case Err(error: final err):
            expect(err, isA<CoordinateNotFinite>());
            final notFinite = err as CoordinateNotFinite;
            expect(notFinite.field, equals('longitude'));
            expect(notFinite.value.isInfinite, isTrue);
        }
      });
    });

    group('equality', () {
      test('két ugyanolyan lat/lon Coordinate egyenlő', () {
        const a = Coordinate(latitude: 46.5, longitude: 18);
        const b = Coordinate(latitude: 46.5, longitude: 18);

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('különböző lat -> nem egyenlő', () {
        const a = Coordinate(latitude: 46.5, longitude: 18);
        const b = Coordinate(latitude: 46.6, longitude: 18);

        expect(a, isNot(equals(b)));
      });

      test('különböző lon -> nem egyenlő', () {
        const a = Coordinate(latitude: 46.5, longitude: 18);
        const b = Coordinate(latitude: 46.5, longitude: 18.1);

        expect(a, isNot(equals(b)));
      });
    });

    group('toString', () {
      test('debug formátumot ad', () {
        const coord = Coordinate(latitude: 46.5, longitude: 18);

        expect(coord.toString(), equals('Coordinate(lat: 46.5, lon: 18.0)'));
      });
    });
  });

  group('CoordinateError', () {
    group('CoordinateOutOfRange', () {
      test('egyenlőség mező + érték alapján', () {
        const a = CoordinateOutOfRange(field: 'latitude', value: 91);
        const b = CoordinateOutOfRange(field: 'latitude', value: 91);
        const c = CoordinateOutOfRange(field: 'longitude', value: 91);
        const d = CoordinateOutOfRange(field: 'latitude', value: 92);

        expect(a, equals(b));
        expect(a, isNot(equals(c)));
        expect(a, isNot(equals(d)));
      });

      test('toString tartalmazza a field-et és value-t', () {
        const err = CoordinateOutOfRange(field: 'latitude', value: 91);

        expect(err.toString(), contains('latitude'));
        expect(err.toString(), contains('91'));
      });
    });

    group('CoordinateNotFinite', () {
      test('egyenlőség mező + érték alapján', () {
        const a = CoordinateNotFinite(field: 'latitude', value: 1);
        const b = CoordinateNotFinite(field: 'latitude', value: 1);

        expect(a, equals(b));
      });

      test('toString tartalmazza a field-et', () {
        const err = CoordinateNotFinite(field: 'longitude', value: 0);

        expect(err.toString(), contains('longitude'));
      });
    });

    test(
      'CoordinateOutOfRange és CoordinateNotFinite nem egyenlő, akkor sem ha ugyanaz a field+value',
      () {
        const a = CoordinateOutOfRange(field: 'latitude', value: 91);
        const b = CoordinateNotFinite(field: 'latitude', value: 91);

        expect(a, isNot(equals(b)));
      },
    );
  });
}
