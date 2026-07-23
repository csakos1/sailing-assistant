import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/safety_map/widgets/cardinal_mark_pin.dart';
import 'package:phone/features/safety_map/widgets/safety_mark_layers.dart';

void main() {
  const cardinal = CardinalMark(
    position: Coordinate(latitude: 46.887482, longitude: 17.897225),
    label: 'Cso D1',
    direction: CardinalDirection.north,
  );
  const structure = FixedStructure(
    position: Coordinate(latitude: 46.946500, longitude: 18.011817),
    label: 'Siofok',
  );
  const shallow = ShallowWaterMark(
    position: Coordinate(latitude: 46.739683, longitude: 17.340183),
    label: 'Gyorok',
  );
  const area = RestrictedArea(
    position: Coordinate(latitude: 46.894667, longitude: 17.898883),
    label: 'Ivohely',
    sideLength: Distance(meters: 70),
  );

  PolygonLayer polygonLayerOf(List<Widget> layers) =>
      layers.whereType<PolygonLayer>().single;

  MarkerLayer markerLayerOf(List<Widget> layers) =>
      layers.whereType<MarkerLayer>().single;

  group('buildSafetyMarkLayers', () {
    test('ures katalogusra is ket ures reteget ad', () {
      // ACT -- a hivo mindig ugyanazt a ket reteget kapja, tehat a
      // terkep gyerek-listaja nem valtozik a betoltes alatt.
      final layers = buildSafetyMarkLayers(const []);

      // ASSERT
      expect(layers, hasLength(2));
      expect(polygonLayerOf(layers).polygons, isEmpty);
      expect(markerLayerOf(layers).markers, isEmpty);
    });

    test('a terulet a poligon-retegbe, a tobbi a marker-retegbe kerul', () {
      // ACT
      final layers = buildSafetyMarkLayers(const [
        cardinal,
        structure,
        shallow,
        area,
      ]);

      // ASSERT
      expect(polygonLayerOf(layers).polygons, hasLength(1));
      expect(markerLayerOf(layers).markers, hasLength(3));
    });

    test('a poligon-reteg all elol, hogy ne takarja a bojakat', () {
      // ACT
      final layers = buildSafetyMarkLayers(const [area, cardinal]);

      // ASSERT -- a sorrend a rajzolasi sorrend, nem veletlen.
      expect(layers.first, isA<PolygonLayer>());
      expect(layers.last, isA<MarkerLayer>());
    });

    test('a terulet negy sarokkal es cimkevel rajzolodik', () {
      // ACT
      final polygon = polygonLayerOf(
        buildSafetyMarkLayers(const [area]),
      ).polygons.single;

      // ASSERT
      expect(polygon.points, hasLength(4));
      expect(polygon.label, 'Ivohely');
    });

    test('a kardinalis a sajat jelet kapja, a poziciojara', () {
      // ACT
      final marker = markerLayerOf(
        buildSafetyMarkLayers(const [cardinal]),
      ).markers.single;

      // ASSERT -- a fajta hatarozza meg a jelet, nem a cimke.
      expect(marker.child, isA<CardinalMarkPin>());
      expect(
        (marker.child as CardinalMarkPin).direction,
        CardinalDirection.north,
      );
      expect(marker.point.latitude, closeTo(cardinal.position.latitude, 1e-9));
      expect(
        marker.point.longitude,
        closeTo(cardinal.position.longitude, 1e-9),
      );
      expect(marker.height, CardinalMarkPin.height);
    });

    test('a fix epitmeny NEM kardinalis jelet kap', () {
      // ACT
      final marker = markerLayerOf(
        buildSafetyMarkLayers(const [structure]),
      ).markers.single;

      // ASSERT -- ez fogna meg, ha a switch egy agat masikra vezetnenk.
      expect(marker.child, isNot(isA<CardinalMarkPin>()));
      expect(marker.point.latitude, closeTo(structure.position.latitude, 1e-9));
    });
  });
}
