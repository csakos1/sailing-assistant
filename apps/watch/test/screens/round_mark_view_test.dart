import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:watch/screens/round_mark_view.dart';
import 'package:watch/theme/watch_colors.dart';
import 'package:watch/theme/watch_theme.dart';

void main() {
  final colors = watchDarkTheme.extension<WatchColors>()!;

  Widget host({
    required String markName,
    required bool ambient,
    required Future<void> Function() onSend,
  }) => MaterialApp(
    theme: watchDarkTheme,
    home: Scaffold(
      body: RoundMarkView(
        payload: WatchPayload(
          timestamp: DateTime.utc(2026, 6, 2, 10, 30),
          markName: markName,
        ),
        colors: colors,
        ambient: ambient,
        onSend: onSend,
      ),
    ),
  );

  // A haptic platform-csatorna elnémítása (a teszt nem a natív hapticot
  // ellenőrzi, csak az állapot-átmeneteket).
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  // A gomb tartása ~1 s-ig (a kitöltő gyűrű lejár → a parancs elsül).
  Future<void> holdButton(WidgetTester tester) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.flag_rounded)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('hold küldi a parancsot, név-váltásra megerősít', (tester) async {
    var sent = 0;
    Future<void> onSend() async {
      sent++;
    }

    await tester.pumpWidget(
      host(markName: 'Bóya 1', ambient: false, onSend: onSend),
    );
    await holdButton(tester);

    // A hold elsült: a parancs ment, a felirat „Küldve".
    expect(sent, 1);
    expect(find.text('Küldve'), findsOneWidget);

    // Round-trip: a payload bója-neve átvált → didUpdateWidget → megerősítve.
    await tester.pumpWidget(
      host(markName: 'Bóya 2', ambient: false, onSend: onSend),
    );
    await tester.pump();

    expect(find.text('Megkerülve'), findsOneWidget);
  });

  testWidgets('küldési hiba a Nincs kapcsolat feliratot adja', (tester) async {
    Future<void> failingSend() async =>
        throw PlatformException(code: 'NO_NODE');

    await tester.pumpWidget(
      host(markName: 'Bóya 1', ambient: false, onSend: failingSend),
    );
    await holdButton(tester);

    expect(find.text('Nincs kapcsolat'), findsOneWidget);
  });

  testWidgets('ambientben statikus gomb, interakció nélkül', (tester) async {
    await tester.pumpWidget(
      host(markName: 'Bóya 1', ambient: true, onSend: () async {}),
    );

    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    expect(find.text('Tartsd nyomva'), findsNothing);
  });

  testWidgets('alapból a Tartsd nyomva feliratot mutatja', (tester) async {
    await tester.pumpWidget(
      host(markName: 'Bóya 1', ambient: false, onSend: () async {}),
    );

    expect(find.text('Tartsd nyomva'), findsOneWidget);
    expect(find.byIcon(Icons.flag_rounded), findsOneWidget);
  });
}
