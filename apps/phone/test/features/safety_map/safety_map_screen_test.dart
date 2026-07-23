import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:phone/features/safety_map/safety_map_screen.dart';
import 'package:phone/features/safety_map/widgets/cardinal_mark_pin.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/boat_state_provider.dart';
import 'package:phone/providers/safety_mark_repository_provider.dart';
import 'package:phone/widgets/map_attribution.dart';

void main() {
  const tihany = Coordinate(latitude: 46.894, longitude: 17.899);
  const eastwards = Coordinate(latitude: 46.894, longitude: 17.930);

  BoatState boatAt(Coordinate? position) =>
      BoatState(lastUpdate: DateTime.utc(2026, 7), position: position);

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

  Future<_ControllableBoatState> pumpScreen(
    WidgetTester tester, {
    required Coordinate? position,
    List<SafetyMark> marks = const [],
  }) async {
    final notifier = _ControllableBoatState(boatAt(position));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          boatStateProvider.overrideWith(() => notifier),
          safetyMarkRepositoryProvider.overrideWithValue(
            _FakeSafetyMarkRepository(marks),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SafetyMapScreen(),
        ),
      ),
    );
    await tester.pump();
    return notifier;
  }

  // A kamera barmely terkep-leszarmazott contextjebol elerheto; az
  // attribucio biztosan ott van, es nem fugg a kesobbi retegektol.
  LatLng cameraCentre(WidgetTester tester) {
    final context = tester.element(find.byType(MapAttribution));
    return MapCamera.of(context).center;
  }

  Future<void> panMap(WidgetTester tester) async {
    // Kezi gesztus, NEM tester.drag: az utobbi sebesseget ad at, amibol a
    // flutter_map fling-animaciot indit. A fling a kesobbi koppintas UTAN is
    // mozgatna a kamerat, gesztuskent -- azaz ujra elengedne a kovetest,
    // amit a gomb epp visszakapcsolt. A lassu, allo kezzel zart mozdulat
    // nulla koruli sebesseggel er veget, tehat nem indul fling.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FlutterMap)),
    );
    await gesture.moveBy(const Offset(-60, 0));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(-60, 0));
    await tester.pump(const Duration(milliseconds: 100));
    // Allo keret a felemeles elott: ez viszi nulla kore a becsult sebesseget.
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pump();
  }

  group('SafetyMapScreen', () {
    testWidgets('pozicio nelkul nincs terkep es nincs gomb', (tester) async {
      // ARRANGE + ACT
      await pumpScreen(tester, position: null);

      // ASSERT
      expect(find.byType(FlutterMap), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('poziciora kozpontoz, es alapbol nincs gomb', (tester) async {
      // ARRANGE
      ignoreTileLoadErrors();

      // ACT
      await pumpScreen(tester, position: tihany);

      // ASSERT -- a kovetes alapbol aktiv, tehat nincs mit visszakapcsolni.
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(cameraCentre(tester).latitude, closeTo(tihany.latitude, 1e-6));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('kovetes kozben az uj pozicio kozepre kerul', (tester) async {
      // ARRANGE
      ignoreTileLoadErrors();
      final boat = await pumpScreen(tester, position: tihany);

      // ACT
      boat.push(boatAt(eastwards));
      await tester.pump();

      // ASSERT
      final centre = cameraCentre(tester);
      expect(centre.longitude, closeTo(eastwards.longitude, 1e-6));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('pasztazas elengedi a kovetest, es kiteszi a gombot', (
      tester,
    ) async {
      // ARRANGE
      ignoreTileLoadErrors();
      await pumpScreen(tester, position: tihany);

      // ACT
      await panMap(tester);

      // ASSERT
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('elengedett kovetes utan az uj pozicio nem rant vissza', (
      tester,
    ) async {
      // ARRANGE
      ignoreTileLoadErrors();
      final boat = await pumpScreen(tester, position: tihany);
      await panMap(tester);
      final afterPan = cameraCentre(tester);

      // ACT
      boat.push(boatAt(eastwards));
      await tester.pump();

      // ASSERT -- ez a kovetes-zar lenyege: a pasztazas megmarad.
      final centre = cameraCentre(tester);
      expect(centre.longitude, closeTo(afterPan.longitude, 1e-9));
      expect(centre.longitude, isNot(closeTo(eastwards.longitude, 1e-4)));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a gomb visszakapcsolja a kovetest es eltunik', (tester) async {
      // ARRANGE
      ignoreTileLoadErrors();
      final boat = await pumpScreen(tester, position: tihany);
      await panMap(tester);

      // ACT
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      // A Scaffold ANIMALVA tunteti el a FAB-ot: amikor a build null-t ad
      // vissza, a regi gomb a faban marad, amig az exit-animacio fut. Egy
      // pump() tehat meg nem eleg a findsNothing-hoz.
      await tester.pump(const Duration(milliseconds: 500));

      // ASSERT -- a kamera visszaugrott a hajora. A HOSSZUSAGOT nezzuk: a
      // pasztazas vizszintes volt, tehat a szelesseg akkor is stimmelne, ha
      // a kozepre-igazitas elmaradt volna.
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(cameraCentre(tester).longitude, closeTo(tihany.longitude, 1e-6));

      // ASSERT -- es a kovetes tenylegesen VISSZAKAPCSOLT: az uj pozicio
      // ismet kozepre kerul. Ez az invarians; a gomb eltunese csak a jele.
      boat.push(boatAt(eastwards));
      await tester.pump();
      expect(
        cameraCentre(tester).longitude,
        closeTo(eastwards.longitude, 1e-6),
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a katalogus jeloloi kirajzolodnak a terkepre', (tester) async {
      // ARRANGE
      ignoreTileLoadErrors();

      // ACT -- a jelolok a repositoryn at jonnek, tehat a teszt a teljes
      // lancot meri: repository -> FutureProvider -> reteg-epites.
      await pumpScreen(
        tester,
        position: tihany,
        marks: const [
          CardinalMark(
            position: Coordinate(latitude: 46.8945, longitude: 17.8995),
            label: 'Cso E1',
            direction: CardinalDirection.south,
          ),
          FixedStructure(
            position: Coordinate(latitude: 46.8935, longitude: 17.8985),
            label: 'Platform',
          ),
        ],
      );
      await tester.pump();

      // ASSERT -- a fajta hatarozza meg a jelet: a kardinalis sajat rajzot
      // kap, a fix epitmeny nevet.
      expect(find.byType(CardinalMarkPin), findsOneWidget);
      expect(find.text('Platform'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('pozicio nelkul a jelolok sem rajzolodnak', (tester) async {
      // ARRANGE + ACT -- nincs terkep, tehat nincs mire rajzolni.
      await pumpScreen(
        tester,
        position: null,
        marks: const [
          FixedStructure(
            position: Coordinate(latitude: 46.8935, longitude: 17.8985),
            label: 'Platform',
          ),
        ],
      );
      await tester.pump();

      // ASSERT
      expect(find.text('Platform'), findsNothing);
    });
  });
}

/// Kivulrol leptetheto [BoatState]-forras: a `build()` a kezdo-allapotot
/// adja, a `push` pedig ugy frissit, ahogy egy uj engine-snapshot tenne.
class _ControllableBoatState extends BoatStateNotifier {
  _ControllableBoatState(this._initial);

  final BoatState _initial;

  @override
  BoatState build() => _initial;

  // A ket lint itt egymasnak feszul: a use_setters_to_change_properties
  // settert kerne, az avoid_setters_without_getters pedig gettert
  // kovetelne hozza. A getter halott kod lenne (a teszt sosem olvassa
  // vissza), ezert a metodus-alak marad, celzott ignore-ral.
  // ignore: use_setters_to_change_properties
  void push(BoatState next) => state = next;
}

/// A katalogus helyett rogzitett listat ado repository.
///
/// A kepernyo-teszt igy nem a valodi 14 elemtol fugg, hanem attol, amit a
/// teszt megad -- a katalogus tartalmat a sajat tesztje orzi.
class _FakeSafetyMarkRepository implements SafetyMarkRepository {
  const _FakeSafetyMarkRepository(this._marks);

  final List<SafetyMark> _marks;

  @override
  Future<List<SafetyMark>> loadSafetyMarks() async => _marks;
}
