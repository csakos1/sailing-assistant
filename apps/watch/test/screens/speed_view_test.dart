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
  );

  Widget host({required bool ambient}) => MaterialApp(
    theme: watchDarkTheme,
    home: Scaffold(
      body: SpeedView(payload: payload, colors: colors, ambient: ambient),
    ),
  );

  // A nézetet egy aktív (nem ambient) lapra helyezi a megadott payloaddal.
  Widget active(WatchPayload p) => MaterialApp(
    theme: watchDarkTheme,
    home: Scaffold(
      body: SpeedView(payload: p, colors: colors, ambient: false),
    ),
  );

  // A nézetet egy fix méretű dobozba helyezi (óra-szimuláció): a kötött kis
  // kijelzőn így ellenőrizhető, hogy nincs RenderFlex-túlcsordulás.
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

  testWidgets('renders SOG with placeholder VMG and steer cells', (
    tester,
  ) async {
    await tester.pumpWidget(host(ambient: false));

    expect(find.text('6.4'), findsOneWidget); // SOG hero
    expect(find.text('VMG'), findsOneWidget);
    expect(find.text('VMG korr'), findsOneWidget);
    expect(find.text('Cél VMG'), findsNothing); // a kétcellás layout megszűnt
    // Három em-dash: a /-VMG, a steer és a cél-% (mind null a payloadban).
    expect(find.text('—'), findsNWidgets(3));
  });

  testWidgets('shows only the hero in ambient mode', (tester) async {
    await tester.pumpWidget(host(ambient: true));

    expect(find.text('6.4'), findsOneWidget);
    expect(find.text('VMG'), findsNothing); // másodlagos sor rejtve
    expect(find.text('VMG korr'), findsNothing); // a steer is rejtve
    expect(find.text('Cél'), findsNothing); // cél-% is rejtve
  });

  testWidgets('target speed %: a cél-% megjelenik (round)', (tester) async {
    final p = WatchPayload(
      timestamp: DateTime.utc(2026, 6, 2, 10, 30),
      sogKnots: 6.4,
      targetSpeedPercent: 83.3,
    );
    await tester.pumpWidget(active(p));

    expect(find.text('83%'), findsOneWidget);
    expect(find.text('Cél'), findsOneWidget);
    // Két placeholder: a /-VMG és a steer (mindkettő null).
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('élő VMG egyedül: cél nélkül az élő áll magában', (
    tester,
  ) async {
    final p = WatchPayload(
      timestamp: DateTime.utc(2026, 6, 2, 10, 30),
      sogKnots: 6.4,
      vmgKnots: 4.5,
    );
    await tester.pumpWidget(active(p));

    expect(find.text('4.5'), findsOneWidget);
    // Két placeholder: a steer és a cél-% (mindkettő null).
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('élő és cél VMG egy cellában jelenik meg', (tester) async {
    final p = WatchPayload(
      timestamp: DateTime.utc(2026, 6, 2, 10, 30),
      sogKnots: 6.4,
      vmgKnots: 4.5,
      targetVmgKnots: 6.1,
    );
    await tester.pumpWidget(active(p));

    expect(find.text('4.5 / 6.1'), findsOneWidget);
    // Két placeholder: a steer és a cél-% (mindkettő null).
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('steer korrekció: stbd jobb oldal, zöld nyíl', (tester) async {
    final p = WatchPayload(
      timestamp: DateTime.utc(2026, 6, 2, 10, 30),
      sogKnots: 6.4,
      vmgSteerCorrection: 8, // pozitív → jobb (starboard)
    );
    await tester.pumpWidget(active(p));

    expect(find.text('8°'), findsOneWidget);
    final arrow = tester.widget<DirectionArrow>(find.byType(DirectionArrow));
    expect(arrow.side, ArrowSide.right);
    expect(arrow.color, colors.starboard);
  });

  testWidgets('steer korrekció: port bal oldal, piros nyíl', (tester) async {
    final p = WatchPayload(
      timestamp: DateTime.utc(2026, 6, 2, 10, 30),
      sogKnots: 6.4,
      vmgSteerCorrection: -8, // negatív → bal (port)
    );
    await tester.pumpWidget(active(p));

    expect(find.text('8°'), findsOneWidget); // magnitúdó; az előjel a nyílon
    final arrow = tester.widget<DirectionArrow>(find.byType(DirectionArrow));
    expect(arrow.side, ArrowSide.left);
    expect(arrow.color, colors.port);
  });

  testWidgets('teljes A-lap: minden érték kitöltve, nincs placeholder', (
    tester,
  ) async {
    final p = WatchPayload(
      timestamp: DateTime.utc(2026, 6, 2, 10, 30),
      sogKnots: 6.4,
      targetSpeedPercent: 83.3,
      vmgKnots: 4.5,
      targetVmgKnots: 6.1,
      vmgSteerCorrection: 8,
    );
    await tester.pumpWidget(active(p));

    expect(find.text('6.4'), findsOneWidget);
    expect(find.text('83%'), findsOneWidget);
    expect(find.text('4.5 / 6.1'), findsOneWidget);
    expect(find.text('8°'), findsOneWidget);
    expect(find.text('—'), findsNothing);
  });

  testWidgets('lemenő VMG: a negatív érték előjellel jelenik meg', (
    tester,
  ) async {
    final p = WatchPayload(
      timestamp: DateTime.utc(2026, 6, 2, 10, 30),
      sogKnots: 5,
      vmgKnots: -3.8,
    );
    await tester.pumpWidget(active(p));

    expect(find.text('-3.8'), findsOneWidget);
  });

  testWidgets('kis viewporton nincs túlcsordulás (42 mm-arány)', (
    tester,
  ) async {
    // A merev tartalom magasabb, mint a kis kijelző; a FittedBox lekicsinyíti.
    await tester.pumpWidget(hostSized(payload, width: 160, height: 96));
    expect(tester.takeException(), isNull);
  });
}
