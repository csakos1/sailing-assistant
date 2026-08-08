import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/text_tones.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/race_detail/widgets/detail_status_strip.dart';
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
  final started = DateTime.utc(2026, 7, 20, 14);
  final ended = DateTime.utc(2026, 7, 20, 18, 48);

  // Ket bojaval, hogy a "2 BOJA" assert tudjon bukni: egy bojanal az
  // "1 BOJA" veletlenul is kijonne.
  Race notStartedRace() =>
      Race.create(id: 'r1', name: 'Alfa', marks: const [first, second]);

  Race activeRace() => notStartedRace().start(at: started);

  Race finishedRace() => activeRace().finish(at: ended);

  Future<void> pumpStrip(WidgetTester tester, Race race) {
    return tester.pumpWidget(
      MaterialApp(
        theme: foretackTheme,
        locale: const Locale('hu'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DetailStatusStrip(race: race)),
      ),
    );
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(DetailStatusStrip)))!;

  // A csikon ket Text all, a Row sorrendjeben: a badge felirata, majd a
  // meta-mezo.
  String metaText(WidgetTester tester) => tester
      .widget<Text>(
        find
            .descendant(
              of: find.byType(DetailStatusStrip),
              matching: find.byType(Text),
            )
            .last,
      )
      .data!;

  testWidgets('shows the mark count before the start', (tester) async {
    // ARRANGE & ACT
    await pumpStrip(tester, notStartedRace());

    // ASSERT
    expect(find.text('NEM INDULT'), findsOneWidget);
    expect(metaText(tester), l10nOf(tester).listMarkCountCaps(2));
  });

  testWidgets('keeps the mark count while the race runs', (tester) async {
    // ARRANGE & ACT
    await pumpStrip(tester, activeRace());

    // ASSERT - futas alatt a boja-szam marad a meta, nem az eltelt ido.
    expect(find.text('FOLYAMATBAN'), findsOneWidget);
    expect(metaText(tester), l10nOf(tester).listMarkCountCaps(2));
  });

  testWidgets('shows the finish date in caps with the year', (tester) async {
    // ARRANGE & ACT
    await pumpStrip(tester, finishedRace());

    // ASSERT - a datum verzal, tartalmazza az evet, es nem a boja-szam.
    final meta = metaText(tester);
    expect(find.text('BEFEJEZETT'), findsOneWidget);
    expect(meta, meta.toUpperCase());
    expect(meta, contains('2026'));
    expect(meta, isNot(l10nOf(tester).listMarkCountCaps(2)));
  });

  testWidgets('stands 45 dp tall with the hairline below', (tester) async {
    // ARRANGE & ACT
    await pumpStrip(tester, notStartedRace());

    // ASSERT - 44 dp tartalom + 1 px valaszto, a keret NEM a dobozon belul.
    expect(
      tester.getSize(find.byType(DetailStatusStrip)).height,
      45,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ColoredBox &&
            widget.color == foretackTheme.colorScheme.outlineVariant,
      ),
      findsOneWidget,
    );
  });

  testWidgets('paints the meta with the low text tone', (tester) async {
    // ARRANGE & ACT
    await pumpStrip(tester, notStartedRace());

    // ASSERT
    // A foretackTheme regisztralja a TextTones-t, tehat sosem null.
    final tones = foretackTheme.extension<TextTones>()!;
    final meta = tester.widget<Text>(
      find
          .descendant(
            of: find.byType(DetailStatusStrip),
            matching: find.byType(Text),
          )
          .last,
    );
    expect(meta.style?.color, tones.low);
  });

  testWidgets('names the markless mode instead of a zero count', (
    tester,
  ) async {
    // ARRANGE & ACT
    await pumpStrip(
      tester,
      Race.create(id: 'r2', name: 'Tura', marks: const []),
    );

    // ASSERT - a nulla nem darabszam, hanem uzemmod.
    final l10n = l10nOf(tester);
    expect(metaText(tester), l10n.listNoMarksCaps);
    expect(metaText(tester), isNot(l10n.listMarkCountCaps(0)));
  });

  testWidgets('keeps the finish date for a markless race', (tester) async {
    // ARRANGE - a datum-ag elsobbseget elvez a boja-felirat felett.
    final markless = Race.create(
      id: 'r2',
      name: 'Tura',
      marks: const [],
    ).start(at: started).finish(at: ended);

    // ACT
    await pumpStrip(tester, markless);

    // ASSERT
    expect(metaText(tester), contains('2026'));
    expect(metaText(tester), isNot(l10nOf(tester).listNoMarksCaps));
  });
}
