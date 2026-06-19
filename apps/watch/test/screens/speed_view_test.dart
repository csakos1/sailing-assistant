import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:watch/screens/speed_view.dart';
import 'package:watch/theme/watch_colors.dart';
import 'package:watch/theme/watch_theme.dart';
import 'package:watch/widgets/direction_arrow.dart';

void main() {
  final colors = watchDarkTheme.extension<WatchColors>()!;
  final payload = WatchPayload(
    timestamp: DateTime.utc(2026, 6, 2, 10, 30),
    sogKnots: 6.4,
    currentTwa: 32, // stbd → jobb oldal
  );

  Widget host({required bool ambient}) => MaterialApp(
    theme: watchDarkTheme,
    home: Scaffold(
      body: SpeedView(payload: payload, colors: colors, ambient: ambient),
    ),
  );

  // A nézetet egy fix méretű dobozba helyezi (óra-szimuláció): így a kötött
  // kis kijelzőn ellenőrizhető, hogy nincs RenderFlex-túlcsordulás.
  Widget hostSized(
    WatchPayload p, {
    required double width,
    required double height,
  }) => MaterialApp(
    theme: watchDarkTheme,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          height: height,
          child: SpeedView(payload: p, colors: colors, ambient: false),
        ),
      ),
    ),
  );

  testWidgets('renders SOG, VMG placeholder and TWA with an arrow', (
    tester,
  ) async {
    await tester.pumpWidget(host(ambient: false));

    expect(find.text('6.4'), findsOneWidget); // SOG hero
    expect(find.text('VMG'), findsOneWidget);
    expect(find.text('—'), findsOneWidget); // VMG v1 placeholder
    expect(find.text('32°'), findsOneWidget); // TWA most
    expect(find.byType(DirectionArrow), findsOneWidget);
  });

  testWidgets('shows only the hero in ambient mode', (tester) async {
    await tester.pumpWidget(host(ambient: true));

    expect(find.text('6.4'), findsOneWidget);
    expect(find.text('TWA'), findsNothing); // másodlagos sor rejtve
    expect(find.byType(DirectionArrow), findsNothing);
  });

  testWidgets('kis viewporton nincs túlcsordulás (42 mm-arány)', (
    tester,
  ) async {
    // A merev tartalom magasabb, mint a kis kijelző; a FittedBox lekicsinyíti.
    await tester.pumpWidget(hostSized(payload, width: 160, height: 96));
    expect(tester.takeException(), isNull);
  });
}
