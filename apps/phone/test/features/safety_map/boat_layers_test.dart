import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:phone/features/safety_map/widgets/boat_symbol.dart';
import 'package:phone/features/safety_map/widgets/boat_symbol_layer.dart';
import 'package:phone/features/safety_map/widgets/boat_vector_layer.dart';
import 'package:phone/providers/boat_state_provider.dart';

void main() {
  const tihany = Coordinate(latitude: 46.894, longitude: 17.899);
  const sailing = Speed(metersPerSecond: 3);
  const drifting = Speed(metersPerSecond: 0.2);

  BoatState boatState({
    Coordinate? position = tihany,
    Bearing? course,
    Speed? speed,
  }) => BoatState(
    lastUpdate: DateTime.utc(2026, 7),
    position: position,
    courseOverGround: course,
    speedOverGround: speed,
  );

  // Nincs TileLayer: a rajzolt retegek nem fuggenek a csempektol, es igy a
  // teszt nem futtat halozati kerest, amit el kellene nyomni.
  Future<void> pumpLayers(WidgetTester tester, BoatState boat) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [boatStateProvider.overrideWith(() => _FixedBoat(boat))],
        child: MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(tihany.latitude, tihany.longitude),
                initialZoom: 15,
              ),
              children: const [BoatVectorLayer(), BoatSymbolLayer()],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  List<LatLng> vectorPoints(WidgetTester tester) => tester
      .widget<PolylineLayer>(
        find.byType(PolylineLayer),
      )
      .polylines
      .single
      .points;

  group('BoatVectorLayer', () {
    testWidgets('haladas kozben a COG iranyaba huz vonalat', (tester) async {
      // ARRANGE + ACT -- kelet fele, jol a kuszob folott.
      await pumpLayers(
        tester,
        boatState(course: const Bearing.true_(90), speed: sailing),
      );

      // ASSERT -- a vonal a hajobol indul, es keletre tart: a szelesseg
      // marad, a hosszusag no.
      final points = vectorPoints(tester);
      expect(points, hasLength(2));
      expect(points.first.latitude, closeTo(tihany.latitude, 1e-9));
      expect(points.first.longitude, closeTo(tihany.longitude, 1e-9));
      expect(points.last.latitude, closeTo(tihany.latitude, 1e-4));
      expect(points.last.longitude, greaterThan(tihany.longitude));
    });

    testWidgets('eszaki COG-nal a hosszusag marad, a szelesseg no', (
      tester,
    ) async {
      // ARRANGE + ACT -- ez kulonbozteti meg a valodi vetitest attol, ha a
      // vegpontot valamelyik tengely menten fixen tolnank el.
      await pumpLayers(
        tester,
        boatState(course: const Bearing.true_(0), speed: sailing),
      );

      // ASSERT
      final points = vectorPoints(tester);
      expect(points.last.longitude, closeTo(tihany.longitude, 1e-9));
      expect(points.last.latitude, greaterThan(tihany.latitude));
    });

    testWidgets('a vonal tullog a lathato teruleten', (tester) async {
      // ARRANGE + ACT
      await pumpLayers(
        tester,
        boatState(course: const Bearing.true_(90), speed: sailing),
      );

      // ASSERT -- a D12 lenyege: a vagast a terkep vegzi, tehat a vegpont
      // a lathato hatarokon KIVUL kell legyen.
      final camera = MapCamera.of(tester.element(find.byType(BoatSymbolLayer)));
      expect(
        vectorPoints(tester).last.longitude,
        greaterThan(camera.visibleBounds.east),
      );
    });

    testWidgets('a kuszob alatt nincs vonal', (tester) async {
      // ARRANGE + ACT
      await pumpLayers(
        tester,
        boatState(course: const Bearing.true_(90), speed: drifting),
      );

      // ASSERT -- a hianyzo vonal oszinte, a remego hazudik (D12).
      expect(find.byType(PolylineLayer), findsNothing);
    });

    testWidgets('COG nelkul nincs vonal', (tester) async {
      // ARRANGE + ACT
      await pumpLayers(tester, boatState(speed: sailing));

      // ASSERT
      expect(find.byType(PolylineLayer), findsNothing);
    });
  });

  group('BoatSymbolLayer', () {
    testWidgets('a hajo a poziciojara kerul', (tester) async {
      // ARRANGE + ACT
      await pumpLayers(
        tester,
        boatState(course: const Bearing.true_(45), speed: sailing),
      );

      // ASSERT
      final marker = tester
          .widget<MarkerLayer>(find.byType(MarkerLayer))
          .markers
          .single;
      expect(marker.point.latitude, closeTo(tihany.latitude, 1e-9));
      expect(marker.point.longitude, closeTo(tihany.longitude, 1e-9));
    });

    testWidgets('haladas kozben iranyitott jelet kap', (tester) async {
      // ARRANGE + ACT
      await pumpLayers(
        tester,
        boatState(course: const Bearing.true_(45), speed: sailing),
      );

      // ASSERT
      final symbol = tester.widget<BoatSymbol>(find.byType(BoatSymbol));
      expect(symbol.course, isNotNull);
      expect(symbol.course!.degrees, 45);
    });

    testWidgets('a kuszob alatt irany nelkuli jelet kap', (tester) async {
      // ARRANGE + ACT
      await pumpLayers(
        tester,
        boatState(course: const Bearing.true_(45), speed: drifting),
      );

      // ASSERT -- a jel megmarad (itt vagy), de irany nelkul: egy fagyott
      // nyil ugyanolyan magabiztosan nezne ki, mint az elo.
      final symbol = tester.widget<BoatSymbol>(find.byType(BoatSymbol));
      expect(symbol.course, isNull);
    });

    testWidgets('pozicio nelkul se hajo, se vonal', (tester) async {
      // ARRANGE + ACT
      await pumpLayers(
        tester,
        boatState(
          position: null,
          course: const Bearing.true_(90),
          speed: sailing,
        ),
      );

      // ASSERT
      expect(find.byType(BoatSymbol), findsNothing);
      expect(find.byType(PolylineLayer), findsNothing);
    });
  });
}

/// Rogzitett hajo-allapotot ado notifier a provider-override-hoz.
class _FixedBoat extends BoatStateNotifier {
  _FixedBoat(this._boat);

  final BoatState _boat;

  @override
  BoatState build() => _boat;
}
