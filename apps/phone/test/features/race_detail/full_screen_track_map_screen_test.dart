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
        points: points,
        marks: marks,
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

  // Az elso ket teszt track NELKUL fut: ilyenkor a TrackMap az ures-agra
  // megy, es nem epul fel FlutterMap. Az AppBar-cim es a legenda bekotese
  // ettol fuggetlen, tehat itt olcsobban es stabilabban ellenorizheto.
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
}
