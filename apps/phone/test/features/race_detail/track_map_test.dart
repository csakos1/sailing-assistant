import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:phone/features/race_detail/track_point.dart';
import 'package:phone/features/race_detail/widgets/track_map.dart';

void main() {
  const emptyLabel = 'nincs track-adat';

  // Az ures-allapotu ag nem epit FlutterMap-et, a MERET-szerzodest viszont
  // ugyanabbol a `height` mezobol adja, mint a rajzolt ag -- ezert eleg ide.
  // A rajzolt agat a lenti csoport fedi, valodi terkeppel.
  const emptyMap = TrackMap(points: [], marks: [], emptyLabel: emptyLabel);

  Future<void> pumpMap(
    WidgetTester tester,
    TrackMap map, {
    double? hostHeight,
  }) {
    // hostHeight nelkul kotetlen a fuggoleges hely (mint a szulo ListView-ban)
    // -> a widget sajat magassaga ervenyesul.
    final body = hostHeight == null
        ? SingleChildScrollView(child: map)
        : SizedBox(height: hostHeight, child: map);
    return tester.pumpWidget(MaterialApp(home: Scaffold(body: body)));
  }

  testWidgets('a default magassag 220 marad', (tester) async {
    // ARRANGE + ACT
    await pumpMap(tester, emptyMap);

    // ASSERT — a meglevo hivo egyetlen karaktert sem valtozott, tehat a mai
    // kartya-magassagot a defaultnak kell oriznie (ADR 0036 F1-D1).
    expect(tester.getSize(find.byType(TrackMap)).height, 220);
  });

  testWidgets('null magassagnal kitolti a kapott helyet', (tester) async {
    // ARRANGE + ACT — ez a nagy nezet modja (Expanded alatt).
    await pumpMap(
      tester,
      const TrackMap(
        points: [],
        marks: [],
        emptyLabel: emptyLabel,
        height: null,
      ),
      hostHeight: 400,
    );

    // ASSERT
    expect(tester.getSize(find.byType(TrackMap)).height, 400);
  });

  testWidgets('pont nelkul az ures-allapot szovege latszik', (tester) async {
    // ARRANGE + ACT
    await pumpMap(tester, emptyMap);

    // ASSERT
    expect(find.text(emptyLabel), findsOneWidget);
  });

  group('a kamera ujrailleszt a viewport meretvaltozasakor', () {
    // Szandekosan MAGAS (eszak-deli) fixtura-track: allo hosztban a fit a
    // magassagra szorit, es ugyanazzal a zoommal fekvo hosztba forgatva a
    // track ket vege kilogna. Igy a lenti teszt kepes elbukni (ADR 0036
    // A2-D2), ha az ujraillesztes elmarad.
    const south = Coordinate(latitude: 46.9, longitude: 18);
    const middle = Coordinate(latitude: 46.92, longitude: 18.002);
    const north = Coordinate(latitude: 46.95, longitude: 18);

    const track = <TrackPoint>[
      TrackPoint(position: south, sogMps: 2),
      TrackPoint(position: middle, sogMps: 4),
      TrackPoint(position: north, sogMps: 6),
    ];
    const marks = <Mark>[Mark(sequence: 1, name: 'E', position: north)];

    final expectedVisible = <LatLng>[
      for (final c in <Coordinate>[south, middle, north])
        LatLng(c.latitude, c.longitude),
    ];

    // A TestWidgetsFlutterBinding SZANDEKOSAN 400-azza az osszes HTTP-kerest,
    // tehat a tile-hiany a tesztkornyezet definicioja, nem hiba. Minden mas
    // kivetel tovabbra is buktat. (Kanonikus minta, ADR 0036 F1-S2.)
    void ignoreTileLoadErrors() {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final isTileFailure =
            details.library == 'image resource service' ||
            details.exception.toString().contains('tile.openstreetmap.org');
        if (isTileFailure) return;
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);
    }

    Future<void> pumpViewport(
      WidgetTester tester, {
      required double width,
      required double height,
    }) async {
      // Ugyanaz a widget-fa, mas meretu hoszt: ez az eszkoz-forgatas
      // megfeleloje -- az elem-fa frissul, a State (es benne a MapController)
      // megmarad.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                height: height,
                child: const TrackMap(
                  points: track,
                  marks: marks,
                  emptyLabel: emptyLabel,
                  height: null,
                ),
              ),
            ),
          ),
        ),
      );
      // Egy keret a meretvaltozas-esemenynek es a halasztott illesztesnek, egy
      // pedig az abbol kovetkezo ujraepitesnek.
      await tester.pump();
      await tester.pump();
    }

    LatLngBounds visibleBounds(WidgetTester tester) {
      final context = tester.element(find.byType(PolylineLayer));
      return MapCamera.of(context).visibleBounds;
    }

    testWidgets('allo nezetben a teljes track latszik', (tester) async {
      // ARRANGE
      ignoreTileLoadErrors();

      // ACT
      await pumpViewport(tester, width: 300, height: 500);

      // ASSERT — ez a kiindulas: a kezdeti illesztes mar ma is helyes.
      final bounds = visibleBounds(tester);
      for (final point in expectedVisible) {
        expect(bounds.contains(point), isTrue, reason: '$point kilog');
      }

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('fekvove forgatva is a teljes track latszik', (tester) async {
      // ARRANGE
      ignoreTileLoadErrors();
      await pumpViewport(tester, width: 300, height: 500);

      // ACT — allobol fekvobe: a viewport meretvaltozasa.
      await pumpViewport(tester, width: 500, height: 300);

      // ASSERT — ujraillesztes nelkul a kamera megtartana a zoomot, es a
      // magas track ket vege kicsuszna a nezetbol.
      final bounds = visibleBounds(tester);
      for (final point in expectedVisible) {
        expect(bounds.contains(point), isTrue, reason: '$point kilog');
      }

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
