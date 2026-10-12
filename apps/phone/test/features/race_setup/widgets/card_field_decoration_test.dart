import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/race_setup/widgets/card_cell_border.dart';
import 'package:phone/features/race_setup/widgets/card_field_decoration.dart';

const TextStyle _style = TextStyle(fontSize: 15, height: cardFieldLineHeight);

// Egy kartya-mezo a megadott cella-magassaggal, egy masik mezovel, hogy a
// fokusz el is veheto legyen.
Future<void> _pump(WidgetTester tester, {required double height}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        home: Scaffold(
          body: Column(
            children: [
              Builder(
                builder: (context) => TextFormField(
                  key: const ValueKey('field'),
                  style: _style,
                  decoration: cardFieldDecoration(
                    context,
                    hint: 'Boja neve',
                    style: _style,
                    height: height,
                  ),
                ),
              ),
              const TextField(key: ValueKey('other')),
            ],
          ),
        ),
      ),
    );

// A vizsgalt mezo decoratora (a masik mezonek is van).
final Finder _decorator = find.descendant(
  of: find.byKey(const ValueKey('field')),
  matching: find.byType(InputDecorator),
);

void main() {
  // A keret a decorator magassagan fut: ha az egyezik a cellaval, a keret
  // pontosan a cellara esik (UF).
  testWidgets('makes the field exactly as tall as the cell', (tester) async {
    // ARRANGE & ACT
    await _pump(tester, height: 48);

    // ASSERT
    final size = tester.getSize(_decorator);
    expect(size.height, closeTo(48, 0.01));
  });

  testWidgets('keeps a 44 dp coordinate cell height', (tester) async {
    // ARRANGE & ACT
    await _pump(tester, height: 44);

    // ASSERT
    final size = tester.getSize(_decorator);
    expect(size.height, closeTo(44, 0.01));
  });

  // Regresszio-or: nyugalomban es fokuszban ugyanaz a keret-tipus, ezert a
  // helyorzo nem ugrik el oldalra vagy fuggolegesen (UF).
  testWidgets('keeps the hint in place when the field gains focus', (
    tester,
  ) async {
    // ARRANGE
    await _pump(tester, height: 48);
    final before = tester.getTopLeft(find.text('Boja neve'));

    // ACT
    await tester.tap(find.byKey(const ValueKey('field')));
    await tester.pumpAndSettle();

    // ASSERT
    expect(tester.getTopLeft(find.text('Boja neve')), before);
  });

  testWidgets('centres the hint vertically in the cell', (tester) async {
    // ARRANGE & ACT
    await _pump(tester, height: 48);

    // ASSERT
    final cell = tester.getRect(_decorator);
    final hint = tester.getRect(find.text('Boja neve'));
    expect(hint.center.dy, closeTo(cell.center.dy, 0.01));
  });

  testWidgets('uses the same border type in every state', (tester) async {
    // ARRANGE & ACT
    await _pump(tester, height: 48);

    // ASSERT
    final decoration = tester.widget<InputDecorator>(_decorator).decoration;
    expect(decoration.enabledBorder, isA<CardCellBorder>());
    expect(decoration.focusedBorder, isA<CardCellBorder>());
    expect(decoration.errorBorder, isA<CardCellBorder>());
    expect(decoration.focusedBorder?.borderSide.width, 1.5);
  });
}
