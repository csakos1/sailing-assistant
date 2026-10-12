import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/race_setup/widgets/coordinate_card.dart';

// A kartya a szuloje szelessegebol dolgozik, ezert kotott dobozba tesszuk;
// a mezoket kulcsolt placeholderek helyettesitik, hogy a meretukbol merni
// lehessen az elrendezest.
Future<void> _pump(
  WidgetTester tester, {
  required VoidCallback? onRemove,
  double latitudeHeight = 44,
}) => tester.pumpWidget(
  MaterialApp(
    theme: foretackTheme,
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 380,
          child: CoordinateCard(
            rail: const Text('01'),
            nameField: const SizedBox(key: ValueKey('name'), height: 48),
            latitudeField: SizedBox(
              key: const ValueKey('lat'),
              height: latitudeHeight,
            ),
            longitudeField: const SizedBox(key: ValueKey('lon'), height: 44),
            removeTooltip: 'Boja torlese',
            onRemove: onRemove,
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('renders the rail content', (tester) async {
    // ARRANGE & ACT
    await _pump(tester, onRemove: () {});

    // ASSERT
    expect(find.text('01'), findsOneWidget);
  });

  testWidgets('fires the remove callback when the button is tapped', (
    tester,
  ) async {
    // ARRANGE
    var removed = false;
    await _pump(tester, onRemove: () => removed = true);

    // ACT
    await tester.tap(find.byTooltip('Boja torlese'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(removed, isTrue);
  });

  testWidgets('hides the remove button when the card cannot be removed', (
    tester,
  ) async {
    // ARRANGE & ACT
    await _pump(tester, onRemove: null);

    // ASSERT
    expect(find.byIcon(Icons.close), findsNothing);
  });

  // Regresszio-or: a rejtett torles-gomb helye fennmarad, kulonben a
  // nev-mezo szelessege kartyarol kartyara ugralna.
  testWidgets('keeps the name width when the remove button is hidden', (
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

  // 40 dp sin + 1 dp hairline (9e, 33a); a mezo-oszlop csak utana kezdodik.
  testWidgets('reserves the rail on the left', (tester) async {
    // ARRANGE & ACT
    await _pump(tester, onRemove: () {});

    // ASSERT
    final cardLeft = tester.getTopLeft(find.byType(CoordinateCard)).dx;
    final nameLeft = tester.getTopLeft(find.byKey(const ValueKey('name'))).dx;
    expect(nameLeft - cardLeft, 41);
  });

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

  // Egy ketsoros hibauzenet a cellat nyujtja; a szomszed cella kitolti
  // ugyanazt a magassagot, hogy a koztuk futo vonal ne szakadjon meg.
  testWidgets('stretches the neighbour cell to a taller one', (tester) async {
    // ARRANGE & ACT
    await _pump(tester, onRemove: () {}, latitudeHeight: 70);

    // ASSERT
    expect(tester.getSize(find.byKey(const ValueKey('lon'))).height, 70);
  });

  // A rajz 40, a tapintasi doboz 48: nedves kezzel, mozgo hajon a tapintasi
  // meretet nem aldozzuk fel egy vizualis aranyert.
  testWidgets('keeps a 48 dp touch box on the remove button', (tester) async {
    // ARRANGE & ACT
    await _pump(tester, onRemove: () {});

    // ASSERT
    expect(tester.getSize(find.byType(IconButton)), const Size(48, 48));
  });
}
