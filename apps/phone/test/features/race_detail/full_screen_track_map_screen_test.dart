import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_detail/track_point.dart';
import 'package:phone/features/race_detail/widgets/full_screen_track_map_screen.dart';
import 'package:phone/features/race_detail/widgets/track_speed_legend.dart';
import 'package:phone/l10n/app_localizations.dart';

void main() {
  const marks = [
    Mark(
      sequence: 1,
      name: 'VK',
      position: Coordinate(latitude: 46.946554, longitude: 18.012115),
    ),
    Mark(
      sequence: 2,
      name: 'BS',
      position: Coordinate(latitude: 46.931763, longitude: 18.045607),
    ),
  ];

  const track = [
    TrackPoint(
      position: Coordinate(latitude: 46.946554, longitude: 18.012115),
      sogMps: 2,
    ),
    TrackPoint(
      position: Coordinate(latitude: 46.94, longitude: 18.03),
      sogMps: 4,
    ),
    TrackPoint(
      position: Coordinate(latitude: 46.931763, longitude: 18.045607),
      sogMps: 3,
    ),
  ];

  const stats = TrackStats(
    maxSpeedMps: 4.2,
    avgSpeedMps: 2.5,
    distanceMeters: 5400,
  );

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<TrackPoint> points = const [],
  }) => tester.pumpWidget(
    MaterialApp(
      locale: const Locale('hu'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: FullScreenTrackMapScreen(
        raceName: 'Kedd esti',
        raceStartedAt: DateTime.utc(2026, 7, 18, 16, 30),
        points: points,
        marks: marks,
        stats: stats,
      ),
    ),
  );

  AppLocalizations l10nOf(WidgetTester tester) => AppLocalizations.of(
    tester.element(find.byType(FullScreenTrackMapScreen)),
  )!;

  /// Elnyeli a tile-letoltes hibait a teszt idejere.
  ///
  /// A TestWidgetsFlutterBinding MINDEN HTTP-kerest 400-zal valaszol meg, igy
  /// a TileLayer minden csempere ClientException-t kap. Ez a kornyezet
  /// tulajdonsaga, nem a widget hibaja: a track, a bojak es a feliratok a
  /// tile-hatter nelkul is kirajzolodnak, es a teszt pont ezeket allitja. A
  /// szures szuk: csak a kep-betoltes retegere es csak a sajat tile-URL-unkre
  /// vonatkozik, minden mas hiba tovabbra is elbuktatja a tesztet.
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

  // Az elso negy teszt track NELKUL fut: ilyenkor a TrackMap az ures-agra
  // megy, es nem epul fel FlutterMap. Az AppBar-cim, az export gomb, a
  // legenda es a capture-pont bekotese ettol fuggetlen, tehat itt olcsobban
  // es stabilabban ellenorizheto.
  testWidgets('az AppBar cime a verseny neve', (tester) async {
    // ARRANGE + ACT
    await pumpScreen(tester);

    // ASSERT — F1-D3: a cim a verseny neve, nem statikus felirat.
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Kedd esti'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a sebesseg-legenda a terkep alatt latszik', (tester) async {
    // ARRANGE + ACT
    await pumpScreen(tester);
    final l10n = l10nOf(tester);

    // ASSERT — F1-D5: a gradient-track magyarazat nelkul csak dekoracio.
    expect(find.byType(TrackSpeedLegend), findsOneWidget);
    expect(find.text(l10n.detailTrackLegendTitle), findsOneWidget);
    expect(find.text(l10n.detailTrackLegendUnknown), findsOneWidget);
  });

  testWidgets('az export gomb az AppBar-ban all, tooltippel', (tester) async {
    // ARRANGE + ACT
    await pumpScreen(tester);
    final l10n = l10nOf(tester);

    // ASSERT — F2-D9: az export a LATHATO nezetrol indul, ezert itt a helye
    // es nem a kartya mellett.
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.ios_share),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip(l10n.trackExportAction), findsOneWidget);
  });

  testWidgets('a capture-pont a legendat is lefedi', (tester) async {
    // ARRANGE + ACT
    await pumpScreen(tester);

    // ASSERT — F1-D7 + A1-D2: a kulcsolt RepaintBoundary a Scaffold torzsen
    // belul all, es a legenda az o leszarmazottja, tehat a legenda is
    // rakerul az exportalt kepre. A SafeArea-ra szukites NEM kozmetika: a
    // Navigator modal route-ja is kulcsolt RepaintBoundary-t tesz a fa
    // tetejere, es az az egesz kepernyot fedne.
    final capturePoint = find.descendant(
      of: find.byType(SafeArea),
      matching: find.byWidgetPredicate(
        (widget) => widget is RepaintBoundary && widget.key is GlobalKey,
      ),
    );
    expect(capturePoint, findsOneWidget);
    expect(
      find.descendant(
        of: capturePoint,
        matching: find.byType(TrackSpeedLegend),
      ),
      findsOneWidget,
    );
  });

  testWidgets('track eseten a bojak neve is megjelenik', (tester) async {
    // ARRANGE — ez az EGYETLEN teszt, ami valodi FlutterMap-et epit.
    ignoreTileLoadErrors();

    // ACT
    await pumpScreen(tester, points: track);
    await tester.pump();

    // ASSERT — F1-D6: a nev-felirat a nagy nezet sajatja, a kartyan nincs.
    expect(find.text('VK'), findsOneWidget);
    expect(find.text('BS'), findsOneWidget);

    // A fa elejtese a FlutterMap idozitoit is leallitja a teszt vege elott.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('hianyos terkep-hatternel az export megerositest ker', (
    tester,
  ) async {
    // ARRANGE — a teszt-kornyezet minden csempet 400-zal ver vissza, tehat a
    // TileLayer errorTileCallback-je biztosan tuzel: ez maga a hianyos
    // terkep-hatter fixturaja (F2-D13).
    ignoreTileLoadErrors();
    await pumpScreen(tester, points: track);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final l10n = l10nOf(tester);

    // ACT
    await tester.tap(find.byIcon(Icons.ios_share));
    await tester.pump();

    // ASSERT — nema szurke folt nem elfogadhato kimenet: a felhasznalo
    // dont, MIELOTT a kep elmegy.
    expect(find.text(l10n.trackExportTileWarningTitle), findsOneWidget);

    // ACT — az elutasitas tenyleg megszakit.
    await tester.tap(find.text(l10n.trackExportTileWarningCancel));
    await tester.pump(const Duration(milliseconds: 500));

    // ASSERT
    expect(find.text(l10n.trackExportTileWarningTitle), findsNothing);
    expect(find.byType(SnackBar), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
