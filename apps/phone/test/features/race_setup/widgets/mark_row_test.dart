import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/race_setup/widgets/mark_row.dart';

// A sor a szuloje szelessegebol dolgozik, ezert kotott dobozba tesszuk;
// a mezoket kulcsolt placeholderek helyettesitik, hogy a szelessegukbol
// merni lehessen a beloszabalyt.
Future<void> _pump(
  WidgetTester tester, {
  required VoidCallback? onRemove,
  int number = 1,
}) => tester.pumpWidget(
  MaterialApp(
    theme: foretackTheme,
    home: Scaffold(
      body: SizedBox(
        width: 380,
        child: MarkRow(
          number: number,
          dragHandle: const Icon(Icons.drag_indicator),
          nameField: const SizedBox(key: ValueKey('name'), height: 48),
          latitudeField: const SizedBox(key: ValueKey('lat'), height: 48),
          longitudeField: const SizedBox(key: ValueKey('lon'), height: 48),
          removeTooltip: 'Boja torlese',
          onRemove: onRemove,
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('renders the sequence number and the drag handle', (
    tester,
  ) async {
    // ARRANGE & ACT
    await _pump(tester, onRemove: () {}, number: 3);

    // ASSERT
    expect(find.text('3'), findsOneWidget);
    expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
  });

  testWidgets('fires the remove callback when the button is tapped', (
    tester,
  ) async {
    // ARRANGE
    var removed = false;
    await _pump(tester, onRemove: () => removed = true);

    // ACT
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // ASSERT
    expect(removed, isTrue);
  });

  testWidgets('hides the remove button when the row cannot be removed', (
    tester,
  ) async {
    // ARRANGE & ACT
    await _pump(tester, onRemove: null);

    // ASSERT
    expect(find.byIcon(Icons.close), findsNothing);
  });

  // Regresszio-or: a rejtett torles-gomb helye fennmarad, kulonben a mezok
  // szelessege sorrol sorra ugralna.
  testWidgets('keeps the field width when the remove button is hidden', (
    tester,
  ) async {
    // ARRANGE
    await _pump(tester, onRemove: () {});
    final withButton = tester.getSize(find.byKey(const ValueKey('name'))).width;

    // ACT
    await _pump(tester, onRemove: null);
    final withoutButton = tester
        .getSize(find.byKey(const ValueKey('name')))
        .width;

    // ASSERT
    expect(withoutButton, withButton);
  });

  // A ket koordinata-mezo egyenlo felet kap, es a sor felul igazodik, hogy a
  // ketsoros hibauzenet ne nyujtsa meg a szomszedjat (ADR 0044 D6).
  testWidgets('splits the coordinate row into two equal halves', (
    tester,
  ) async {
    // ARRANGE & ACT
    await _pump(tester, onRemove: () {});

    // ASSERT
    final latitude = tester.getSize(find.byKey(const ValueKey('lat'))).width;
    final longitude = tester.getSize(find.byKey(const ValueKey('lon'))).width;
    expect(latitude, longitude);
  });

  // A 44 dp-s sin a sorszamnak es a drag-handle-nek van fenntartva; a
  // mezo-oszlop csak utana kezdodik (ADR 0044 D45).
  testWidgets('reserves the 44 dp rail on the left', (tester) async {
    // ARRANGE & ACT
    await _pump(tester, onRemove: () {});

    // ASSERT - 44 dp sin + 10 dp mezo-padding.
    final rowLeft = tester.getTopLeft(find.byType(MarkRow)).dx;
    final nameLeft = tester.getTopLeft(find.byKey(const ValueKey('name'))).dx;
    expect(nameLeft - rowLeft, 54);
  });

  // A rajz 44, a tapintasi doboz 48 (ADR 0044 D49): nedves kezzel, mozgo
  // hajon a tapintasi meretet nem aldozzuk fel egy vizualis aranyert.
  testWidgets('keeps a 48 dp touch box on the remove button', (tester) async {
    // ARRANGE & ACT
    await _pump(tester, onRemove: () {});

    // ASSERT
    expect(
      tester.getSize(find.byType(IconButton)),
      const Size(48, 48),
    );
  });
}
