import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_detail/race_detail_screen.dart';
import 'package:phone/features/race_list/race_list_screen.dart';
import 'package:phone/features/race_list/widgets/finished_races_sheet.dart';
import 'package:phone/features/race_setup/race_setup_screen.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/race_repository_provider.dart';

void main() {
  const mark = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.9, longitude: 18.05),
  );
  final clock = DateTime.utc(2025, 6, 1, 12);

  // A státusz-átmenetek a domain factory-kon mennek (start/finish), így a
  // fixture-ök valós, invariáns-érvényes Race-eket adnak.
  Race activeRace(String id, String name) =>
      Race.create(id: id, name: name, marks: const [mark]).start(at: clock);

  Race finishedRace(String id, String name) =>
      activeRace(id, name).finish(at: clock);

  Future<void> pumpList(WidgetTester tester, List<Race> races) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          raceRepositoryProvider.overrideWithValue(_FakeRaceRepository(races)),
        ],
        child: const MaterialApp(
          locale: Locale('hu'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RaceListScreen(),
        ),
      ),
    );
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(RaceListScreen)))!;

  testWidgets('a versenyek megjelennek, sorra koppintva a detail nyílik', (
    tester,
  ) async {
    // ARRANGE
    final race = Race.create(id: 'r1', name: 'Kedd esti', marks: const [mark]);
    await pumpList(tester, [race]);
    await tester.pumpAndSettle();

    // ASSERT — a verseny neve látszik.
    expect(find.text('Kedd esti'), findsOneWidget);

    // ACT — sorra koppintunk.
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    // ASSERT — a detail nyílt meg.
    expect(find.byType(RaceDetailScreen), findsOneWidget);
  });

  testWidgets('a FAB a setup képernyőt nyitja', (tester) async {
    // ARRANGE
    await pumpList(tester, const []);
    await tester.pumpAndSettle();

    // ACT
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.byType(RaceSetupScreen), findsOneWidget);
  });

  testWidgets('üres lista esetén az üres-állapot szöveg jelenik meg', (
    tester,
  ) async {
    // ARRANGE
    await pumpList(tester, const []);
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    // ASSERT
    expect(find.text(l10n.listEmpty), findsOneWidget);
  });

  testWidgets('a fő lista csak a függőben lévőket mutatja, aktív elöl', (
    tester,
  ) async {
    // ARRANGE — notStarted + active + finished vegyesen.
    final notStarted = Race.create(
      id: 'r1',
      name: 'Alfa',
      marks: const [mark],
    );
    await pumpList(tester, [
      notStarted,
      activeRace('r2', 'Bravo'),
      finishedRace('r3', 'Charlie'),
    ]);
    await tester.pumpAndSettle();

    // ASSERT — a függőben lévők látszanak, a befejezett NEM a fő listában.
    expect(find.text('Alfa'), findsOneWidget);
    expect(find.text('Bravo'), findsOneWidget);
    expect(find.text('Charlie'), findsNothing);

    // ASSERT — aktív elöl: a 'Bravo' sor az 'Alfa' fölött van.
    final activeY = tester.getTopLeft(find.text('Bravo')).dy;
    final notStartedY = tester.getTopLeft(find.text('Alfa')).dy;
    expect(activeY, lessThan(notStartedY));
  });

  testWidgets('a befejezett-gomb megjelenik, ha van befejezett', (
    tester,
  ) async {
    // ARRANGE — csak befejezett -> a fő lista üres.
    await pumpList(tester, [finishedRace('r1', 'Charlie')]);
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    // ASSERT — a befejezett-gomb + az üres fő lista együtt látszik.
    expect(find.text(l10n.listFinishedRacesTitle), findsOneWidget);
    expect(find.text(l10n.listEmpty), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
  });

  testWidgets('a befejezett-gomb rejtett befejezett nélkül', (
    tester,
  ) async {
    // ARRANGE — csak notStarted.
    final race = Race.create(id: 'r1', name: 'Alfa', marks: const [mark]);
    await pumpList(tester, [race]);
    await tester.pumpAndSettle();

    // ASSERT — nincs befejezett-gomb.
    expect(find.byIcon(Icons.history), findsNothing);
  });

  testWidgets('a befejezett-gombra koppintva a modal nyílik', (
    tester,
  ) async {
    // ARRANGE
    await pumpList(tester, [finishedRace('r1', 'Charlie')]);
    await tester.pumpAndSettle();

    // ACT — a befejezett-gombra koppintunk.
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    // ASSERT — a sheet nyílt meg, benne a befejezett verseny neve.
    expect(find.byType(FinishedRacesSheet), findsOneWidget);
    expect(find.text('Charlie'), findsOneWidget);
  });
}

class _FakeRaceRepository implements RaceRepository {
  _FakeRaceRepository(this.races);

  final List<Race> races;

  @override
  Stream<List<Race>> watchRaces() => Stream<List<Race>>.value(races);

  @override
  Future<void> save(Race race) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<Race?> getRace(String id) async => null;
}
