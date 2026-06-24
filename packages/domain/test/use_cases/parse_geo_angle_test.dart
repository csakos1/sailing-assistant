import 'package:domain/domain.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

/// Sikeres parse értékét adja vissza, vagy buktatja a tesztet.
double _value(Result<double, GeoAngleParseError> result) => switch (result) {
  Ok(value: final v) => v,
  Err(error: final e) => fail('Vártunk Ok-ot, de Err jött: $e'),
};

/// A parse hibáját adja vissza, vagy buktatja a tesztet, ha Ok jött.
GeoAngleParseError _error(Result<double, GeoAngleParseError> result) =>
    switch (result) {
      Ok(value: final v) => fail('Vártunk Err-t, de Ok jött: $v'),
      Err(error: final e) => e,
    };

void main() {
  group('ParseGeoAngle', () {
    const parse = ParseGeoAngle();

    group('DD (tizedes-fok)', () {
      test('csupasz pozitív szám = N/E', () {
        // Arrange / Act
        final lat = parse(input: '46.946554', axis: GeoAxis.latitude);
        final lon = parse(input: '18.012115', axis: GeoAxis.longitude);

        // Assert
        expect(_value(lat), closeTo(46.946554, 1e-9));
        expect(_value(lon), closeTo(18.012115, 1e-9));
      });

      test('vezető mínusz negatívvá tesz', () {
        final result = parse(input: '-46.946554', axis: GeoAxis.latitude);
        expect(_value(result), closeTo(-46.946554, 1e-9));
      });

      test('N/S betű adja a szélesség előjelét', () {
        final north = parse(input: '46.946554 N', axis: GeoAxis.latitude);
        final south = parse(input: '46.946554 S', axis: GeoAxis.latitude);
        expect(_value(north), closeTo(46.946554, 1e-9));
        expect(_value(south), closeTo(-46.946554, 1e-9));
      });

      test('E/W betű adja a hosszúság előjelét', () {
        final east = parse(input: '18.012115 E', axis: GeoAxis.longitude);
        final west = parse(input: '18.012115 W', axis: GeoAxis.longitude);
        expect(_value(east), closeTo(18.012115, 1e-9));
        expect(_value(west), closeTo(-18.012115, 1e-9));
      });
    });

    group('DDM (fok-perc)', () {
      test('szimbólumokkal és égtáj-betűvel', () {
        final result = parse(input: "46° 56.793' N", axis: GeoAxis.latitude);
        expect(_value(result), closeTo(46.946550, 1e-4));
      });

      test('szimbólumok nélkül, csak szóközzel', () {
        final result = parse(input: '46 56.793 N', axis: GeoAxis.latitude);
        expect(_value(result), closeTo(46.946550, 1e-4));
      });

      test('Balaton VK bója DDM-ben (lat + lon)', () {
        // A VK valós koordinátája 46.946554, 18.012115.
        final lat = parse(input: "46° 56.793' N", axis: GeoAxis.latitude);
        final lon = parse(input: "018° 00.727' E", axis: GeoAxis.longitude);
        expect(_value(lat), closeTo(46.946554, 1e-4));
        expect(_value(lon), closeTo(18.012115, 1e-4));
      });
    });

    group('DMS (fok-perc-másodperc)', () {
      test('szimbólumokkal és égtáj-betűvel', () {
        final result = parse(input: '46° 56\' 47.6" N', axis: GeoAxis.latitude);
        expect(_value(result), closeTo(46.94656, 1e-4));
      });

      test('szimbólumok nélkül, csak szóközzel', () {
        final result = parse(input: '46 56 47.6 N', axis: GeoAxis.latitude);
        expect(_value(result), closeTo(46.94656, 1e-4));
      });
    });

    group('előjel és égtáj-betű', () {
      test('égtáj-betű állhat a szám előtt is', () {
        final result = parse(input: 'S46.9', axis: GeoAxis.latitude);
        expect(_value(result), closeTo(-46.9, 1e-9));
      });

      test('a betűvel EGYEZŐ explicit jel elfogadott', () {
        // -46.9 S: a mínusz és az S is negatív → nincs ellentmondás.
        final result = parse(input: '-46.9 S', axis: GeoAxis.latitude);
        expect(_value(result), closeTo(-46.9, 1e-9));
      });

      test('a betűvel ELLENTMONDÓ jel Unrecognized (P7)', () {
        // -46.9 N: a mínusz negatív, az N pozitív → ellentmondás.
        final result = parse(input: '-46.9 N', axis: GeoAxis.latitude);
        expect(_error(result), isA<Unrecognized>());
      });
    });

    group('toleráns szintaxis', () {
      test('extra körülvevő és belső szóközök sem zavarnak', () {
        final result = parse(
          input: '  46   56.793   N  ',
          axis: GeoAxis.latitude,
        );
        expect(_value(result), closeTo(46.946550, 1e-4));
      });
    });

    group('hibák', () {
      test('üres bemenet → EmptyInput', () {
        expect(
          _error(parse(input: '', axis: GeoAxis.latitude)),
          isA<EmptyInput>(),
        );
        expect(
          _error(parse(input: '   ', axis: GeoAxis.latitude)),
          isA<EmptyInput>(),
        );
      });

      test('értelmezhetetlen szöveg → Unrecognized', () {
        expect(
          _error(parse(input: 'abc', axis: GeoAxis.latitude)),
          isA<Unrecognized>(),
        );
      });

      test('teljes "lat, lon" egy mezőben → Unrecognized (P5)', () {
        final result = parse(
          input: '46.946554, 18.012115',
          axis: GeoAxis.latitude,
        );
        expect(_error(result), isA<Unrecognized>());
      });

      test('60-as vagy nagyobb perc → ComponentOutOfRange', () {
        final result = parse(input: '46 75 N', axis: GeoAxis.latitude);
        final error = _error(result);
        expect(error, isA<ComponentOutOfRange>());
        expect((error as ComponentOutOfRange).component, 'minutes');
      });

      test('60-as vagy nagyobb másodperc → ComponentOutOfRange', () {
        final result = parse(input: '46 30 75 N', axis: GeoAxis.latitude);
        final error = _error(result);
        expect(error, isA<ComponentOutOfRange>());
        expect((error as ComponentOutOfRange).component, 'seconds');
      });

      test('rossz tengelyű betű → CardinalMismatch', () {
        final latWithEast = parse(input: '46.9 E', axis: GeoAxis.latitude);
        final lonWithNorth = parse(input: '18.0 N', axis: GeoAxis.longitude);
        expect(_error(latWithEast), isA<CardinalMismatch>());
        expect(_error(lonWithNorth), isA<CardinalMismatch>());
      });

      test('tartományon kívüli fok → OutOfRange', () {
        final latTooBig = parse(input: '91 N', axis: GeoAxis.latitude);
        final lonTooBig = parse(input: '181 E', axis: GeoAxis.longitude);
        final latTooSmall = parse(input: '-91', axis: GeoAxis.latitude);
        expect(_error(latTooBig), isA<OutOfRange>());
        expect(_error(lonTooBig), isA<OutOfRange>());
        expect(_error(latTooSmall), isA<OutOfRange>());
      });
    });
  });
}
