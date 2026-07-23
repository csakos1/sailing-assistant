import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const ivohely = Coordinate(latitude: 46.894667, longitude: 17.898883);
  const siofok = Coordinate(latitude: 46.9465, longitude: 18.011817);

  group('egyenloseg', () {
    test('azonos fajta es azonos mezok -> egyenlo', () {
      // ARRANGE + ACT
      const a = CardinalMark(
        position: ivohely,
        label: 'Cso 1',
        direction: CardinalDirection.north,
      );
      const b = CardinalMark(
        position: ivohely,
        label: 'Cso 1',
        direction: CardinalDirection.north,
      );

      // ASSERT
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('eltero kardinalis irany -> nem egyenlo', () {
      const eszaki = CardinalMark(
        position: ivohely,
        label: 'Cso 1',
        direction: CardinalDirection.north,
      );
      const deli = CardinalMark(
        position: ivohely,
        label: 'Cso 1',
        direction: CardinalDirection.south,
      );

      expect(eszaki, isNot(equals(deli)));
    });

    // Ez a hierarchia lenyegi tulajdonsaga: a rajzolas fajta szerint
    // valaszt jelet, tehat ket kulonbozo fajta soha nem eshet egybe,
    // meg akkor sem, ha minden kozos mezojuk azonos.
    test('kulonbozo fajta azonos pozicioval -> nem egyenlo', () {
      const kardinalis = CardinalMark(
        position: siofok,
        label: 'Siofok',
        direction: CardinalDirection.north,
      );
      const epitmeny = FixedStructure(position: siofok, label: 'Siofok');

      expect(kardinalis, isNot(equals(epitmeny)));
    });

    test('a terulet oldalhossza resze az egyenlosegnek', () {
      const kicsi = RestrictedArea(
        position: ivohely,
        label: 'Ivohely',
        sideLength: Distance(meters: 70),
      );
      const nagy = RestrictedArea(
        position: ivohely,
        label: 'Ivohely',
        sideLength: Distance(meters: 140),
      );

      expect(kicsi, isNot(equals(nagy)));
    });
  });

  group('invariansok', () {
    test('ures cimke -> AssertionError', () {
      // ARRANGE - futasidoben eloallitott ures string. Const literallal
      // az assert mar fordito-hiba lenne, nem dobott AssertionError,
      // es a prefer_const_constructors is const-ot kovetelne.
      final uresCimke = ''.substring(0);

      // ACT + ASSERT
      expect(
        () => FixedStructure(position: siofok, label: uresCimke),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('katalogus-hasznalat', () {
    // A katalogus const listakent epul fel a data-retegben, es a
    // megjelenites kimerito switch-csel rendel jelet. Ez a teszt
    // mindkettot egyszerre rogziti: ha barmelyik leaf const-olhatatlanna
    // valna, vagy egy uj fajta bekerulne, ez a teszt nem fordulna.
    test('mind a negy fajta const, es kimeritoen lefedheto', () {
      const jelolok = <SafetyMark>[
        CardinalMark(
          position: ivohely,
          label: 'Cso 1',
          direction: CardinalDirection.west,
        ),
        FixedStructure(position: siofok, label: 'Siofok'),
        RestrictedArea(
          position: ivohely,
          label: 'Ivohely',
          sideLength: Distance(meters: 70),
        ),
        ShallowWaterMark(position: siofok, label: 'Gyorok'),
      ];

      final fajtak = jelolok.map(_fajta).toList();

      expect(fajtak, ['kardinalis', 'epitmeny', 'terulet', 'gazlo']);
    });
  });
}

String _fajta(SafetyMark jelolo) => switch (jelolo) {
  CardinalMark() => 'kardinalis',
  FixedStructure() => 'epitmeny',
  RestrictedArea() => 'terulet',
  ShallowWaterMark() => 'gazlo',
};
