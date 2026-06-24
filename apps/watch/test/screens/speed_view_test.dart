import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:watch/screens/speed_view.dart';
import 'package:watch/theme/watch_colors.dart';
import 'package:watch/theme/watch_theme.dart';

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

  testWidgets('renders SOG, live VMG and target VMG placeholders', (
    tester,
  ) async {
    await tester.pumpWidget(host(ambient: false));

    expect(find.text('6.4'), findsOneWidget); // SOG hero
    expect(find.text('VMG'), findsOneWidget);
    expect(find.text('Cél VMG'), findsOneWidget);
    // Harom em-dash: elo VMG + target VMG + cel-% (mind null a payloadban).
    expect(find.text('—'), findsNWidgets(3));
  });

  testWidgets('shows only the hero in ambient mode', (tester) async {
    await tester.pumpWidget(host(ambient: true));

    expect(find.text('6.4'), findsOneWidget);
    expect(find.text('VMG'), findsNothing); // másodlagos sor rejtve
    expect(find.text('Cél VMG'), findsNothing); // target VMG is rejtve
    expect(find.text('Cél'), findsNothing); // cél-% is rejtve
  });

  testWidgets('target speed %: a cél-% megjelenik (round)', (tester) async {
    final p = WatchPayload(
      timestamp: DateTime.utc(2026, 6, 2, 10, 30),
      sogKnots: 6.4,
      currentTwa: 32,
      targetSpeedPercent: 83.3,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: watchDarkTheme,
        home: Scaffold(
          body: SpeedView(payload: p, colors: colors, ambient: false),
        ),
      ),
    );

    expect(find.text('83%'), findsOneWidget);
    expect(find.text('Cél'), findsOneWidget);
    // Ket placeholder: elo VMG + target VMG (mindketto null).
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('live VMG: a VMG-érték megjelenik csomóban', (tester) async {
    final p = WatchPayload(
      timestamp: DateTime.utc(2026, 6, 2, 10, 30),
      sogKnots: 6.4,
      currentTwa: 32,
      vmgKnots: 4.5,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: watchDarkTheme,
        home: Scaffold(
          body: SpeedView(payload: p, colors: colors, ambient: false),
        ),
      ),
    );

    expect(find.text('4.5'), findsOneWidget);
    // Ket placeholder: target VMG + cel-% (mindketto null).
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('target VMG: a cél-VMG megjelenik csomóban', (tester) async {
    final p = WatchPayload(
      timestamp: DateTime.utc(2026, 6, 2, 10, 30),
      sogKnots: 6.4,
      currentTwa: 32,
      targetVmgKnots: 6.1,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: watchDarkTheme,
        home: Scaffold(
          body: SpeedView(payload: p, colors: colors, ambient: false),
        ),
      ),
    );

    expect(find.text('6.1'), findsOneWidget);
    expect(find.text('Cél VMG'), findsOneWidget);
    // Ket placeholder: elo VMG + cel-% (mindketto null).
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('lemenő VMG: a negatív érték előjellel jelenik meg', (
    tester,
  ) async {
    final p = WatchPayload(
      timestamp: DateTime.utc(2026, 6, 2, 10, 30),
      sogKnots: 5,
      currentTwa: 150,
      vmgKnots: -3.8,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: watchDarkTheme,
        home: Scaffold(
          body: SpeedView(payload: p, colors: colors, ambient: false),
        ),
      ),
    );

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
