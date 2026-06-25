import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_detail/race_detail_screen.dart';
import 'package:phone/features/race_edit/race_edit_screen.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';
import 'package:phone/providers/rounding_sample_reader_provider.dart';

void main() {
  const mark = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.9, longitude: 18.05),
  );
  final clock = DateTime.utc(2025, 6, 1, 12);

  late _FakeRaceRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _FakeRaceRepository();
    container = ProviderContainer(
      overrides: [
        raceRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => clock),
        // A befejezett verseny mostantól a debug-only post-race szekciót is
        // rendereli (ADR 0034); üres readerrel a valódi AppDatabase helyett.
        roundingSampleReaderProvider.overrideWithValue(
          (_) async => const <RoundingSample>[],
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> pumpDetail(WidgetTester tester, Race race) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('hu'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RaceDetailScreen(race: race),
        ),
      ),
    );
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(RaceDetailScreen)))!;

  testWidgets('notStarted: az Indítás elindítja és aktívvá teszi a versenyt', (
    tester,
  ) async {
    // ARRANGE
    final race = Race.create(id: 'r1', name: 'Kedd esti', marks: const [mark]);
    await pumpDetail(tester, race);
    final l10n = l10nOf(tester);

    // ACT
    expect(find.widgetWithText(FilledButton, l10n.detailStart), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, l10n.detailStart));
    await tester.pumpAndSettle();

    // ASSERT — aktívként mentve, és a gomb Befejezésre vált.
    expect(repository.saved, hasLength(1));
    expect(repository.saved.single.status, RaceStatus.active);
    expect(
      find.widgetWithText(FilledButton, l10n.detailFinish),
      findsOneWidget,
    );
  });

  testWidgets('active: a Befejezés befejezi a versenyt', (tester) async {
    // ARRANGE — az aktív race-t a holderbe ültetjük.
    final race = Race.create(
      id: 'r1',
      name: 'Kedd esti',
      marks: const [mark],
    ).start(at: clock);
    container.read(activeRaceProvider.notifier).activeRace = race;
    await pumpDetail(tester, race);
    final l10n = l10nOf(tester);

    // ACT
    expect(
      find.widgetWithText(FilledButton, l10n.detailFinish),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, l10n.detailFinish));
    await tester.pumpAndSettle();

    // ASSERT — befejezett állapot mentve, nincs több akció-gomb.
    expect(repository.saved, hasLength(1));
    expect(repository.saved.single.status, RaceStatus.finished);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('notStarted: a Szerkesztés akció a RaceEditScreen-t nyitja', (
    tester,
  ) async {
    // ARRANGE
    final race = Race.create(id: 'r1', name: 'Kedd esti', marks: const [mark]);
    await pumpDetail(tester, race);
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    // ACT — a Szerkesztés ikon az edit-képernyőre navigál.
    expect(find.byTooltip(l10n.detailEdit), findsOneWidget);
    await tester.tap(find.byTooltip(l10n.detailEdit));
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.byType(RaceEditScreen), findsOneWidget);
  });

  testWidgets('active: nincs Szerkesztés akció', (tester) async {
    // ARRANGE — aktív versenyt nyitunk.
    final race = Race.create(
      id: 'r1',
      name: 'Kedd esti',
      marks: const [mark],
    ).start(at: clock);
    container.read(activeRaceProvider.notifier).activeRace = race;
    await pumpDetail(tester, race);
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    // ASSERT — szerkesztés csak notStarted-nél (ADR 0029 D1).
    expect(find.byTooltip(l10n.detailEdit), findsNothing);
  });

  testWidgets('a watchRaces frissülése után az új adatot mutatja (D5)', (
    tester,
  ) async {
    // ARRANGE — a lista a szerkesztett (átnevezett) verziót sugározza; a
    // detail a pillanatkép helyett ezt mutatja (ADR 0029 D5).
    final original = Race.create(
      id: 'r1',
      name: 'Régi',
      marks: const [mark],
    );
    final edited = Race.create(
      id: 'r1',
      name: 'Új',
      marks: const [mark],
    );
    final repo = _FakeRaceRepository(watch: Stream.value([edited]));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          raceRepositoryProvider.overrideWithValue(repo),
          clockProvider.overrideWithValue(() => clock),
        ],
        child: MaterialApp(
          locale: const Locale('hu'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RaceDetailScreen(race: original),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // ASSERT — a reaktív lista friss neve látszik, nem a pillanatkép.
    expect(find.text('Új'), findsOneWidget);
    expect(find.text('Régi'), findsNothing);
  });

  testWidgets('a törlés megerősítés után töröl és visszanavigál', (
    tester,
  ) async {
    // ARRANGE — detail egy home-route fölött, hogy a pop tiszta legyen.
    final race = Race.create(id: 'r1', name: 'Kedd esti', marks: const [mark]);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('hu'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RaceDetailScreen(race: race),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    // ACT — törlés ikon → megerősítés.
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.detailDeleteConfirm),
    );
    await tester.pumpAndSettle();

    // ASSERT
    expect(repository.deleted, ['r1']);
    expect(find.byType(RaceDetailScreen), findsNothing);
  });

  testWidgets('SafeArea: az alsó akció-gomb a nav-inset fölött marad', (
    tester,
  ) async {
    // ARRANGE — 3-gombos navigációt szimulálunk alsó view-paddinggel.
    tester.view.padding = const FakeViewPadding(bottom: 96);
    addTearDown(tester.view.reset);
    final race = Race.create(id: 'r1', name: 'Kedd esti', marks: const [mark]);
    await pumpDetail(tester, race);
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    // ACT — az alsó (Indítás) gomb alsó pereme logikai pixelben.
    final dpr = tester.view.devicePixelRatio;
    final screenHeight = tester.view.physicalSize.height / dpr;
    final bottomInset = 96 / dpr;
    final button = find.widgetWithText(FilledButton, l10n.detailStart);
    final buttonBottom = tester.getBottomRight(button).dy;

    // ASSERT — a gomb a rendszer-inset sávja fölött van; SafeArea nélkül a
    // bottom Padding(16) a navsáv alá vinné a gombot, ezt védi ez a teszt.
    expect(buttonBottom, lessThanOrEqualTo(screenHeight - bottomInset));
  });
}

class _FakeRaceRepository implements RaceRepository {
  _FakeRaceRepository({Stream<List<Race>>? watch})
    : _watch = watch ?? const Stream<List<Race>>.empty();

  final Stream<List<Race>> _watch;
  final saved = <Race>[];
  final deleted = <String>[];

  @override
  Future<void> save(Race race) async {
    saved.add(race);
  }

  @override
  Future<void> delete(String id) async {
    deleted.add(id);
  }

  @override
  Future<Race?> getRace(String id) async => null;

  @override
  Stream<List<Race>> watchRaces() => _watch;
}
