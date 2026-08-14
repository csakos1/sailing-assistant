import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/race_setup/widgets/form_action_bar.dart';
import 'package:phone/features/race_setup/widgets/form_bar_action.dart';

FormBarAction _action(String label, VoidCallback onTap) =>
    FormBarAction(label: label, icon: Icons.add, onTap: onTap);

Future<void> _pump(
  WidgetTester tester, {
  List<FormBarAction> actions = const [],
  VoidCallback? onPrimary,
}) => tester.pumpWidget(
  MaterialApp(
    theme: foretackTheme,
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: FormActionBar(
          secondaryActions: actions,
          primaryLabel: 'Mentes',
          onPrimary: onPrimary ?? () {},
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('renders every label', (tester) async {
    // ARRANGE & ACT
    await _pump(
      tester,
      actions: [
        _action('Boja hozzaadasa', () {}),
        _action('Korabbi bojak', () {}),
      ],
    );

    // ASSERT
    expect(find.text('Boja hozzaadasa'), findsOneWidget);
    expect(find.text('Korabbi bojak'), findsOneWidget);
    expect(find.text('Mentes'), findsOneWidget);
  });

  testWidgets('gives the cells the same width and a 56 dp height', (
    tester,
  ) async {
    // ARRANGE & ACT
    await _pump(
      tester,
      actions: [_action('Egy', () {}), _action('Ketto', () {})],
    );

    // ASSERT
    final left = tester.getSize(find.byType(TextButton).first);
    final right = tester.getSize(find.byType(TextButton).last);
    expect(left.width, right.width);
    expect(left.height, 56);
    expect(right.height, 56);
  });

  testWidgets('fires the callback of the tapped cell', (tester) async {
    // ARRANGE
    final tapped = <String>[];
    await _pump(
      tester,
      actions: [
        _action('Egy', () => tapped.add('egy')),
        _action('Ketto', () => tapped.add('ketto')),
      ],
    );

    // ACT
    await tester.tap(find.text('Ketto'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(tapped, <String>['ketto']);
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
    await _pump(tester, actions: [_action('Egy', () {})]);

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

  // Boja nelkuli versenynel nincs mit hozzaadni, ezert a felso sor eltunik
  // (ADR 0046 D4). Az ures lista ugyanaz, ami korabban a harom null volt.
  testWidgets('drops the secondary row when the action list is empty', (
    tester,
  ) async {
    // ARRANGE & ACT
    await _pump(tester);

    // ASSERT
    expect(find.byType(TextButton), findsNothing);
    expect(find.text('Mentes'), findsOneWidget);
  });

  testWidgets('stretches the primary button across the whole bar', (
    tester,
  ) async {
    // ARRANGE & ACT
    await _pump(tester, actions: [_action('Egy', () {})]);

    // ASSERT
    final bar = tester.getSize(find.byType(FormActionBar));
    final primary = tester.getSize(find.byType(FilledButton));
    expect(primary.width, bar.width);
    expect(primary.height, 60);
  });

  // Egyetlen akcional nincs oszto vonal, tehat a cella a teljes sort kapja.
  testWidgets('gives a single action the whole row', (tester) async {
    // ARRANGE & ACT
    await _pump(tester, actions: [_action('Egy', () {})]);

    // ASSERT
    final bar = tester.getSize(find.byType(FormActionBar));
    expect(tester.getSize(find.byType(TextButton)).width, bar.width);
  });
}
