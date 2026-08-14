import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/text_tones.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/widgets/foretack_switch.dart';

Future<void> _pump(
  WidgetTester tester, {
  required bool value,
  ValueChanged<bool>? onChanged,
}) => tester.pumpWidget(
  MaterialApp(
    theme: foretackTheme,
    home: Scaffold(
      body: Center(
        child: ForetackSwitch(value: value, onChanged: onChanged ?? (_) {}),
      ),
    ),
  ),
);

// A ket AnimatedContainer a fa sorrendjeben: eloszor a sin, utana a butyok.
Finder _boxes() => find.descendant(
  of: find.byType(ForetackSwitch),
  matching: find.byType(AnimatedContainer),
);

// A widget MINDIG ad decoration-t mindket doboznak, ezert a lenti
// allitasokban a nem-null jelzes sosem robban.
List<AnimatedContainer> _painted(WidgetTester tester) =>
    tester.widgetList<AnimatedContainer>(_boxes()).toList();

void main() {
  testWidgets('taps report the opposite value from off', (tester) async {
    // ARRANGE
    final reported = <bool>[];
    await _pump(tester, value: false, onChanged: reported.add);

    // ACT
    await tester.tap(find.byType(ForetackSwitch));
    await tester.pump();

    // ASSERT
    expect(reported, <bool>[true]);
  });

  testWidgets('taps report the opposite value from on', (tester) async {
    // ARRANGE
    final reported = <bool>[];
    await _pump(tester, value: true, onChanged: reported.add);

    // ACT
    await tester.tap(find.byType(ForetackSwitch));
    await tester.pump();

    // ASSERT
    expect(reported, <bool>[false]);
  });

  testWidgets('keeps a 48 dp touch box around a 30 dp track', (tester) async {
    // ARRANGE & ACT
    await _pump(tester, value: false);

    // ASSERT - a rajz 52x30, a tapintasi doboz viszont 48 dp magas:
    // nedves kezzel, mozgo hajon ez a kulonbseg a lenyeg.
    expect(tester.getSize(_boxes().first), const Size(52, 30));
    expect(tester.getSize(find.byType(ForetackSwitch)), const Size(52, 48));
  });

  testWidgets('slides the thumb across when switched on', (tester) async {
    // ARRANGE
    await _pump(tester, value: false);
    final offLeft = tester.getTopLeft(_boxes().last).dx;

    // ACT
    await _pump(tester, value: true);
    await tester.pumpAndSettle();

    // ASSERT
    expect(tester.getTopLeft(_boxes().last).dx, greaterThan(offLeft));
  });

  testWidgets('paints the on state with the primary track', (tester) async {
    // ARRANGE & ACT
    await _pump(tester, value: true);

    // ASSERT - a Mentes gomb inverze: telt primary sin, onPrimary butyok.
    final scheme = foretackTheme.colorScheme;
    final boxes = _painted(tester);
    expect((boxes.first.decoration! as BoxDecoration).color, scheme.primary);
    expect((boxes.last.decoration! as BoxDecoration).color, scheme.onPrimary);
  });

  testWidgets('paints the off state with an outlined track', (tester) async {
    // ARRANGE & ACT
    await _pump(tester, value: false);

    // ASSERT - kikapcsolva a sin ures: csak a kerete es a halk butyok latszik.
    final scheme = foretackTheme.colorScheme;
    final tones = foretackTheme.extension<TextTones>()!;
    final boxes = _painted(tester);
    final track = boxes.first.decoration! as BoxDecoration;
    expect(track.color, Colors.transparent);
    expect(track.border, Border.all(color: scheme.outline));
    expect((boxes.last.decoration! as BoxDecoration).color, tones.low);
  });
}
