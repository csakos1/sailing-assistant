import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/race_setup/widgets/form_action_bar.dart';

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onSecondary,
  VoidCallback? onPrimary,
}) => tester.pumpWidget(
  MaterialApp(
    theme: foretackTheme,
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: FormActionBar(
          secondaryLabel: 'Boja hozzaadasa',
          secondaryIcon: Icons.add,
          onSecondary: onSecondary ?? () {},
          primaryLabel: 'Mentes',
          onPrimary: onPrimary ?? () {},
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('renders both labels', (tester) async {
    // ARRANGE & ACT
    await _pump(tester);

    // ASSERT
    expect(find.text('Boja hozzaadasa'), findsOneWidget);
    expect(find.text('Mentes'), findsOneWidget);
  });

  testWidgets('gives both buttons the same width and a 52 dp height', (
    tester,
  ) async {
    // ARRANGE & ACT
    await _pump(tester);

    // ASSERT
    final secondary = tester.getSize(find.byType(OutlinedButton));
    final primary = tester.getSize(find.byType(FilledButton));
    expect(secondary.width, primary.width);
    expect(secondary.height, 52);
    expect(primary.height, 52);
  });

  testWidgets('fires the secondary callback', (tester) async {
    // ARRANGE
    var tapped = false;
    await _pump(tester, onSecondary: () => tapped = true);

    // ACT
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();

    // ASSERT
    expect(tapped, isTrue);
  });

  testWidgets('fires the primary callback', (tester) async {
    // ARRANGE
    var tapped = false;
    await _pump(tester, onPrimary: () => tapped = true);

    // ACT
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // ASSERT
    expect(tapped, isTrue);
  });

  // A sav felso hairline-ja valasztja el a gorgetett torzstol; nelkule a
  // gombok a tartalomra ulnenek ra.
  testWidgets('draws a hairline on top of the bar', (tester) async {
    // ARRANGE & ACT
    await _pump(tester);

    // ASSERT
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(FormActionBar),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.border, isNotNull);
  });
}
