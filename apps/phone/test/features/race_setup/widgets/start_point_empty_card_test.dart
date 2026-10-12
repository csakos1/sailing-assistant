import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/race_setup/widgets/start_point_empty_card.dart';

void main() {
  var library = 0;
  var coordinates = 0;

  setUp(() {
    library = 0;
    coordinates = 0;
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      theme: foretackTheme,
      home: Scaffold(
        body: StartPointEmptyCard(
          title: 'Rajthely hozzaadasa',
          libraryLabel: 'Korabbi bojak',
          coordinatesLabel: 'Koordinata',
          onPickFromLibrary: () => library++,
          onEnterCoordinates: () => coordinates++,
        ),
      ),
    ),
  );

  testWidgets('offers the two paths below the title', (tester) async {
    // ARRANGE & ACT
    await pump(tester);

    // ASSERT
    expect(find.text('Rajthely hozzaadasa'), findsOneWidget);
    expect(find.text('Korabbi bojak'), findsOneWidget);
    expect(find.text('Koordinata'), findsOneWidget);
  });

  testWidgets('routes each path to its own callback', (tester) async {
    // ARRANGE
    await pump(tester);

    // ACT
    await tester.tap(find.text('Korabbi bojak'));
    await tester.tap(find.text('Koordinata'));
    await tester.tap(find.text('Koordinata'));

    // ASSERT
    expect(library, 1);
    expect(coordinates, 2);
  });

  testWidgets('splits the paths into two equal cells', (tester) async {
    // ARRANGE & ACT
    await pump(tester);

    // ASSERT
    final cells = find.byType(InkWell);
    expect(cells, findsNWidgets(2));
    final left = tester.getSize(cells.at(0)).width;
    expect(tester.getSize(cells.at(1)).width, left);
  });
}
