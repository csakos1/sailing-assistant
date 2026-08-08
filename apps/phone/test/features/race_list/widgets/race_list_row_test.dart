import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/race_list/widgets/race_list_row.dart';
import 'package:phone/l10n/app_localizations.dart';

void main() {
  const first = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.9, longitude: 18.05),
  );
  const second = Mark(
    sequence: 2,
    name: 'Szemes',
    position: Coordinate(latitude: 46.8, longitude: 17.9),
  );
  final clock = DateTime.utc(2025, 6, 1, 12);

  // Ket bojaval, hogy a szamlalo assertje tudjon bukni: egy bojanal az
  // "1 BOJA" veletlenul is kijonne.
  Race notStartedRace() =>
      Race.create(id: 'r1', name: 'Alfa', marks: const [first, second]);

  Race activeRace() => notStartedRace().start(at: clock);

  Future<void> pumpRow(
    WidgetTester tester,
    Race race, {
    VoidCallback? onTap,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        locale: const Locale('hu'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RaceListRow(race: race, onTap: onTap),
        ),
      ),
    );
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(RaceListRow)))!;

  Finder coloredBoxWith(Color color) => find.byWidgetPredicate(
    (widget) => widget is ColoredBox && widget.color == color,
  );

  testWidgets('starts the row content at the left edge, unnumbered', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpRow(tester, notStartedRace());

    // ASSERT - nincs sorszam-oszlop, es a nev a sor bal elenel kezdodik:
    // 4 dp el-sav + 16 dp padding.
    expect(find.text('01'), findsNothing);
    expect(tester.getTopLeft(find.text('Alfa')).dx, 20);
  });

  testWidgets('shows the mark count of the race', (tester) async {
    // ARRANGE & ACT
    await pumpRow(tester, notStartedRace());
    final l10n = l10nOf(tester);

    // ASSERT
    expect(find.text(l10n.listMarkCountCaps(2)), findsOneWidget);
  });

  testWidgets('names the targeted mark only while the race runs', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpRow(tester, activeRace());

    // ASSERT - az aktiv bojara tartunk, tehat az elso boja neve all itt.
    expect(find.text('· Z1'), findsOneWidget);

    // ACT - ugyanaz a verseny, meg nem inditva.
    await pumpRow(tester, notStartedRace());

    // ASSERT
    expect(find.text('· Z1'), findsNothing);
  });

  testWidgets('keeps the mark name in the casing it was typed in', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpRow(tester, activeRace());

    // ASSERT - a boja-nev adat, nem UI-string: nem verzalozzuk.
    expect(find.text('· Z1'), findsOneWidget);
    expect(find.text('· z1'), findsNothing);
  });

  testWidgets('marks the running race with an accent bar', (tester) async {
    // ARRANGE & ACT
    await pumpRow(tester, activeRace());

    // ASSERT
    expect(coloredBoxWith(foretackTheme.colorScheme.primary), findsOneWidget);

    // ACT
    await pumpRow(tester, notStartedRace());

    // ASSERT - nincs kiemeles, de a hely megmarad.
    expect(coloredBoxWith(foretackTheme.colorScheme.primary), findsNothing);
    expect(find.text('Alfa'), findsOneWidget);
  });

  testWidgets('does not dim the name of a race that has not started', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpRow(tester, notStartedRace());

    // ASSERT - kimondott elteres a maketttol: minden nev onSurface.
    final name = tester.widget<Text>(find.text('Alfa'));
    expect(name.style?.color, foretackTheme.colorScheme.onSurface);
  });

  testWidgets('reports a tap on the whole row', (tester) async {
    // ARRANGE
    var taps = 0;
    await pumpRow(tester, notStartedRace(), onTap: () => taps++);

    // ACT
    await tester.tap(find.byType(RaceListRow));
    await tester.pump();

    // ASSERT
    expect(taps, 1);
  });

  testWidgets('names the markless mode instead of a zero count', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpRow(
      tester,
      Race.create(id: 'r2', name: 'Tura', marks: const []),
    );
    final l10n = l10nOf(tester);

    // ASSERT - a nulla nem darabszam, hanem uzemmod.
    expect(find.text(l10n.listNoMarksCaps), findsOneWidget);
    expect(find.text(l10n.listMarkCountCaps(0)), findsNothing);
  });

  testWidgets('names no targeted mark without marks', (tester) async {
    // ARRANGE & ACT - elinditva sincs mire tartani.
    final markless = Race.create(
      id: 'r2',
      name: 'Tura',
      marks: const [],
    ).start(at: clock);
    await pumpRow(tester, markless);

    // ASSERT
    expect(find.textContaining('· '), findsNothing);
  });
}
