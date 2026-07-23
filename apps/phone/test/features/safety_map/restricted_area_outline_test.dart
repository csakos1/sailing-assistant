import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/safety_map/restricted_area_outline.dart';

void main() {
  // Az Ivohely a katalogusbol: 70 m oldalu negyzet a Tihanyi-csonel.
  const area = RestrictedArea(
    position: Coordinate(latitude: 46.894667, longitude: 17.898883),
    label: 'Ivohely',
    sideLength: Distance(meters: 70),
  );

  group('restrictedAreaOutline', () {
    test('negy sarkot ad, korbejarasi sorrendben', () {
      // ACT
      final outline = restrictedAreaOutline(area);

      // ASSERT -- EK, DK, DNy, ENy. A varhato ertekek fuggetlenul, a gombi
      // direkt feladat kepletevel szamolva (R = 6371 km).
      expect(outline, hasLength(4));
      expect(outline[0].latitude, closeTo(46.894981762, 1e-8));
      expect(outline[0].longitude, closeTo(17.899343625, 1e-8));
      expect(outline[1].latitude, closeTo(46.894352237, 1e-8));
      expect(outline[1].longitude, closeTo(17.899343620, 1e-8));
      expect(outline[2].latitude, closeTo(46.894352237, 1e-8));
      expect(outline[2].longitude, closeTo(17.898422380, 1e-8));
      expect(outline[3].latitude, closeTo(46.894981762, 1e-8));
      expect(outline[3].longitude, closeTo(17.898422375, 1e-8));
    });

    test('a negyzet a kozeppontjara szimmetrikus', () {
      // ACT
      final outline = restrictedAreaOutline(area);

      // ASSERT -- az atellenes sarkok felezopontja a kozeppont. Ez az az
      // invarians, ami egy elgepelt iranyszogre is elhasalna.
      final northEast = outline[0];
      final southWest = outline[2];
      expect(
        (northEast.latitude + southWest.latitude) / 2,
        closeTo(area.position.latitude, 1e-8),
      );
      expect(
        (northEast.longitude + southWest.longitude) / 2,
        closeTo(area.position.longitude, 1e-8),
      );
    });

    test('az eszak-deli kiterjedes az oldalhosszal egyezik', () {
      // ACT
      final outline = restrictedAreaOutline(area);

      // ASSERT -- 70 m eszak-deli iranyban 0.000629525 fok ezen a sugaron.
      // A kelet-nyugati fok-kiterjedes nagyobb, mert a szelessegi kor
      // rovidebb -- ez kulonbozteti meg a helyes negyzetet a fokban
      // negyzetes, valojaban teglalap alaku hibas rajztol.
      final latitudeSpan = outline[0].latitude - outline[1].latitude;
      final longitudeSpan = outline[0].longitude - outline[3].longitude;
      expect(latitudeSpan, closeTo(0.000629525, 1e-8));
      expect(longitudeSpan, closeTo(0.000921250, 1e-8));
      expect(longitudeSpan, greaterThan(latitudeSpan));
    });

    test('a nulla oldalhossz negy azonos pontot ad', () {
      // ARRANGE -- degeneralt, de ervenyes bemenet: a Distance non-negativ.
      const degenerate = RestrictedArea(
        position: Coordinate(latitude: 46.9, longitude: 17.9),
        label: 'Pont',
        sideLength: Distance(meters: 0),
      );

      // ACT
      final outline = restrictedAreaOutline(degenerate);

      // ASSERT
      expect(outline, hasLength(4));
      for (final corner in outline) {
        expect(corner.latitude, closeTo(46.9, 1e-9));
        expect(corner.longitude, closeTo(17.9, 1e-9));
      }
    });
  });
}
