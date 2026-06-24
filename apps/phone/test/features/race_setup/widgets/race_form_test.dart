import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_setup/widgets/race_form.dart';
import 'package:phone/l10n/app_localizations.dart';

void main() {
  const markA = Mark(
    sequence: 1,
    name: 'A',
    position: Coordinate(latitude: 46.9, longitude: 18),
  );
  const markB = Mark(
    sequence: 2,
    name: 'B',
    position: Coordinate(latitude: 46.8, longitude: 17.9),
  );

  // A RaceForm-ot egy Scaffold-ba ágyazzuk (Material + textTheme + l10n).
  // Az onSubmit-et a hívó köti be, hogy a kibocsátott párt elkaphassa.
  Future<void> pumpForm(
    WidgetTester tester, {
    required void Function(String name, List<Mark> marks) onSubmit,
    Race? initialRace,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('hu'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RaceForm(initialRace: initialRace, onSubmit: onSubmit),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('edit módban feltölti a mezőket az initialRace-ből', (
    tester,
  ) async {
    // ARRANGE & ACT
    final race = Race.create(
      id: 'r1',
      name: 'Régi',
      marks: const [markA, markB],
    );
    await pumpForm(tester, initialRace: race, onSubmit: (_, _) {});

    // ASSERT — a név és mindkét bója adatai a mezőkbe töltődtek.
    expect(find.text('Régi'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('46.9'), findsOneWidget);
    expect(find.text('17.9'), findsOneWidget);
  });

  testWidgets('a submit a vizuális sorrendből gyártja a sequence-t', (
    tester,
  ) async {
    // ARRANGE
    List<Mark>? emitted;
    final race = Race.create(
      id: 'r1',
      name: 'V',
      marks: const [markA, markB],
    );
    await pumpForm(
      tester,
      initialRace: race,
      onSubmit: (_, marks) => emitted = marks,
    );

    // ACT
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // ASSERT — sorrend és sequence a vizuális sorrendet követi.
    expect(emitted, isNotNull);
    expect(emitted!.map((m) => m.name).toList(), ['A', 'B']);
    expect(emitted!.map((m) => m.sequence).toList(), [1, 2]);
  });

  testWidgets('reorder után a kibocsátott sorrend és sequence frissül', (
    tester,
  ) async {
    // ARRANGE
    List<Mark>? emitted;
    final race = Race.create(
      id: 'r1',
      name: 'V',
      marks: const [markA, markB],
    );
    await pumpForm(
      tester,
      initialRace: race,
      onSubmit: (_, marks) => emitted = marks,
    );

    // ACT — a reordert a ReorderableListView publikus onReorder
    // kontraktusán át hajtjuk (a gesztus-szimuláció widget-tesztben
    // megbízhatatlan); ez ugyanaz a belépő, amit a húzás is hív. A 2.
    // sort (index 1) a lista tetejére (index 0) mozgatjuk.
    final reorderable = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    reorderable.onReorder(1, 0);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // ASSERT — B előre került, a sequence az új vizuális sorrendet tükrözi.
    expect(emitted, isNotNull);
    expect(emitted!.map((m) => m.name).toList(), ['B', 'A']);
    expect(emitted!.map((m) => m.sequence).toList(), [1, 2]);
  });

  testWidgets('a hozzáadás gomb új bója-sort ad', (tester) async {
    // ARRANGE — create: egy bója-sorral indul (név + 1 sor = 4 mező).
    await pumpForm(tester, onSubmit: (_, _) {});
    expect(find.byType(TextFormField), findsNWidgets(4));

    // ACT
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // ASSERT — két sor (név + 2 sor = 7 mező).
    expect(find.byType(TextFormField), findsNWidgets(7));
  });

  testWidgets('a törlés gomb eltávolít egy bója-sort', (tester) async {
    // ARRANGE — két bójával töltünk (név + 2 sor = 7 mező).
    final race = Race.create(
      id: 'r1',
      name: 'V',
      marks: const [markA, markB],
    );
    await pumpForm(tester, initialRace: race, onSubmit: (_, _) {});
    expect(find.byType(TextFormField), findsNWidgets(7));

    // ACT — az első sort töröljük.
    await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
    await tester.pumpAndSettle();

    // ASSERT — egy sor maradt (név + 1 sor = 4 mező).
    expect(find.byType(TextFormField), findsNWidgets(4));
  });

  testWidgets('érvénytelen szélesség blokkolja a submitot', (tester) async {
    // ARRANGE
    var submitted = false;
    await pumpForm(tester, onSubmit: (_, _) => submitted = true);

    // ACT — mezők tree-sorrendben: verseny-név, bója-név, lat, lon.
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'V');
    await tester.enterText(fields.at(1), 'Z1');
    await tester.enterText(fields.at(2), '200');
    await tester.enterText(fields.at(3), '18.05');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // ASSERT — a tartományon kívüli szélesség megállította a mentést.
    expect(submitted, isFalse);
  });

  testWidgets('DDM formátumú koordinátát elfogad és fokra alakít', (
    tester,
  ) async {
    // ARRANGE
    List<Mark>? emitted;
    await pumpForm(tester, onSubmit: (_, marks) => emitted = marks);

    // ACT — mezők tree-sorrendben: verseny-név, bója-név, lat, lon.
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'V');
    await tester.enterText(fields.at(1), 'VK');
    await tester.enterText(fields.at(2), "46° 56.793' N");
    await tester.enterText(fields.at(3), "018° 00.727' E");
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // ASSERT — a DDM-bemenet tizedes-fokra konvertálva került ki.
    expect(emitted, isNotNull);
    expect(emitted!.single.position.latitude, closeTo(46.946554, 1e-4));
    expect(emitted!.single.position.longitude, closeTo(18.012115, 1e-4));
  });

  testWidgets('DMS formátumú koordinátát elfogad', (tester) async {
    // ARRANGE
    List<Mark>? emitted;
    await pumpForm(tester, onSubmit: (_, marks) => emitted = marks);

    // ACT
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'V');
    await tester.enterText(fields.at(1), 'VK');
    await tester.enterText(fields.at(2), '46° 56\' 47.6" N');
    await tester.enterText(fields.at(3), '18° 0\' 43.6" E');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // ASSERT — a DMS-bemenet ugyanarra a fok-értékre konvertál.
    expect(emitted, isNotNull);
    expect(emitted!.single.position.latitude, closeTo(46.94656, 1e-4));
    expect(emitted!.single.position.longitude, closeTo(18.01211, 1e-4));
  });

  testWidgets('értelmezhetetlen koordináta blokkolja a submitot', (
    tester,
  ) async {
    // ARRANGE
    var submitted = false;
    await pumpForm(tester, onSubmit: (_, _) => submitted = true);

    // ACT — a lat egyik formátumként sem értelmezhető.
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'V');
    await tester.enterText(fields.at(1), 'Z1');
    await tester.enterText(fields.at(2), 'abc');
    await tester.enterText(fields.at(3), '18.05');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // ASSERT — az érvénytelen formátum megállította a mentést.
    expect(submitted, isFalse);
  });
}
