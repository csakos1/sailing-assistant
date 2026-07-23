import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:phone/features/safety_map/widgets/race_mark_layer.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/widgets/mark_pin.dart';

void main() {
  const first = Mark(
    sequence: 1,
    name: 'VK',
    position: Coordinate(latitude: 46.8940, longitude: 17.8990),
  );
  const second = Mark(
    sequence: 2,
    name: 'BS',
    position: Coordinate(latitude: 46.8955, longitude: 17.9010),
  );
  const third = Mark(
    sequence: 3,
    name: 'CEL',
    position: Coordinate(latitude: 46.8930, longitude: 17.8975),
  );

  Race courseOf(List<Mark> marks) =>
      Race.create(id: 'r1', name: 'Teszt', marks: marks);

  // Nincs TileLayer: a bojak rajzolasa nem fugg a csempektol.
  Future<void> pumpLayer(WidgetTester tester, Race? race) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [activeRaceProvider.overrideWith(() => _FixedRace(race))],
        child: MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(first.position.latitude, 17.899),
                initialZoom: 14,
              ),
              children: const [RaceMarkLayer()],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  List<MarkPin> pinsOf(WidgetTester tester) =>
      tester.widgetList<MarkPin>(find.byType(MarkPin)).toList();

  group('RaceMarkLayer', () {
    testWidgets('aktiv verseny nelkul nem rajzol bojat', (tester) async {
      // ARRANGE + ACT
      await pumpLayer(tester, null);

      // ASSERT -- a kepernyo enelkul is hasznalhato marad.
      expect(find.byType(MarkPin), findsNothing);
    });

    testWidgets('a palya minden bojajat kirajzolja', (tester) async {
      // ARRANGE + ACT
      await pumpLayer(tester, courseOf([first, second, third]));

      // ASSERT
      final pins = pinsOf(tester);
      expect(pins, hasLength(3));
      expect(pins.map((pin) => pin.label), ['1', '2', '3']);
      expect(pins.map((pin) => pin.name), ['VK', 'BS', 'CEL']);
    });

    testWidgets('a bojak a sajat poziciojukra kerulnek', (tester) async {
      // ARRANGE + ACT
      await pumpLayer(tester, courseOf([first, second]));

      // ASSERT
      final markers = tester
          .widget<MarkerLayer>(find.byType(MarkerLayer))
          .markers;
      expect(markers.first.point.latitude, closeTo(46.8940, 1e-9));
      expect(markers.last.point.longitude, closeTo(17.9010, 1e-9));
    });

    testWidgets('indulas elott az elso boja a kiemelt', (tester) async {
      // ARRANGE + ACT -- notStarted eseten az activeMarkIndex nulla.
      await pumpLayer(tester, courseOf([first, second, third]));

      // ASSERT
      expect(pinsOf(tester).map((pin) => pin.isActive), [true, false, false]);
    });

    testWidgets('megkerules utan a kovetkezo boja a kiemelt', (tester) async {
      // ARRANGE -- a domain sajat atmeneteivel lepunk, nem kezzel allitott
      // indexszel: igy a teszt a valodi eletciklust koveti.
      final race =
          courseOf([
                first,
                second,
                third,
              ])
              .start(at: DateTime.utc(2026, 7, 20, 10))
              .roundCurrentMark(
                at: DateTime.utc(2026, 7, 20, 10, 5),
              );

      // ACT
      await pumpLayer(tester, race);

      // ASSERT
      expect(pinsOf(tester).map((pin) => pin.isActive), [false, true, false]);
    });

    testWidgets('a kiemeles nem valtoztat marker-meretet', (tester) async {
      // ARRANGE + ACT
      await pumpLayer(tester, courseOf([first, second]));

      // ASSERT -- a Marker kozepre igazit, tehat egy nagyobb aktiv doboz a
      // bojat a valos koordinatajatol elcsusztatva rajzolna ki.
      final markers = tester
          .widget<MarkerLayer>(find.byType(MarkerLayer))
          .markers;
      expect(markers.first.width, markers.last.width);
      expect(markers.first.height, markers.last.height);
    });
  });
}

/// Rogzitett versenyt ado notifier a provider-override-hoz.
class _FixedRace extends ActiveRaceNotifier {
  _FixedRace(this._race);

  final Race? _race;

  @override
  Race? build() => _race;
}
