import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/race_setup/widgets/form_section_header.dart';

Future<void> _pump(WidgetTester tester, {int? count}) => tester.pumpWidget(
  MaterialApp(
    theme: foretackTheme,
    home: Scaffold(
      body: SizedBox(
        width: 400,
        child: FormSectionHeader(label: 'BOJAK', count: count),
      ),
    ),
  ),
);

// A cimke utani vonal: az egyetlen 1 dp magas SizedBox a fejlecben.
Finder _line() => find.descendant(
  of: find.byType(FormSectionHeader),
  matching: find.byWidgetPredicate(
    (widget) => widget is SizedBox && widget.height == 1,
  ),
);

void main() {
  testWidgets('shows the label and the count', (tester) async {
    // ARRANGE & ACT
    await _pump(tester, count: 2);

    // ASSERT
    expect(find.text('BOJAK'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('omits the count when there is none', (tester) async {
    // ARRANGE & ACT
    await _pump(tester);

    // ASSERT
    expect(find.text('BOJAK'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });

  // Regresszio-or: a vonal a cimke utan a TELJES maradekot kapja, nem a
  // felet (a Flexible + Expanded par hibaja).
  testWidgets('lets the line take all the remaining width', (tester) async {
    // ARRANGE & ACT
    await _pump(tester);

    // ASSERT - 400 - 2 x 20 margo - cimke - 10 koz, a 0 szeles szam elott
    // meg egy 10 koz.
    final label = tester.getSize(find.text('BOJAK')).width;
    expect(tester.getSize(_line()).width, 400 - 40 - label - 20);
  });
}
