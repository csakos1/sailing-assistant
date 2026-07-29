import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/race_detail/race_detail_screen.dart';
import 'package:phone/features/race_detail/widgets/detail_action_bar.dart';
import 'package:phone/features/race_detail/widgets/detail_mark_row.dart';
import 'package:phone/features/race_detail/widgets/detail_status_strip.dart';
import 'package:phone/features/race_detail/widgets/post_race_analysis_section.dart';
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
          theme: foretackTheme,
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

  // Az akcio-sav sorai Material-bol szinezodnek; a kitoltott sor a primary.
  Color rowBackgroundOf(WidgetTester tester, String label) {
    final row = find.ancestor(
      of: find.text(label),
      matching: find.byType(Material),
    );
    return tester.widget<Material>(row.first).color!;
  }

  testWidgets('notStarted: az Indítás elindítja és aktívvá teszi a versenyt', (
    tester,
  ) async {
    // ARRANGE
    final race = Race.create(id: 'r1', name: 'Kedd esti', marks: const [mark]);
    await pumpDetail(tester, race);
    final l10n = l10nOf(tester);

    // ACT
    expect(find.text(l10n.detailStart), findsOneWidget);
    await tester.tap(find.text(l10n.detailStart));
    await tester.pumpAndSettle();

    // ASSERT — aktívként mentve, a felirat Befejezésre vált, és a kitöltés
    // átvándorol az élő nézet sorára.
    expect(repository.saved, hasLength(1));
    expect(repository.saved.single.status, RaceStatus.active);
    expect(find.text(l10n.detailFinish), findsOneWidget);
    expect(
      rowBackgroundOf(tester, l10n.liveOpen),
      foretackTheme.colorScheme.primary,
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
    expect(find.text(l10n.detailFinish), findsOneWidget);
    await tester.tap(find.text(l10n.detailFinish));
    await tester.pumpAndSettle();

    // ASSERT — befejezett állapot mentve, és az egész alsó sáv eltűnik.
    expect(repository.saved, hasLength(1));
    expect(repository.saved.single.status, RaceStatus.finished);
    expect(find.byType(DetailActionBar), findsNothing);
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
          theme: foretackTheme,
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
          theme: foretackTheme,
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

  testWidgets('SafeArea: az alsó akció-sáv a nav-inset fölött marad', (
    tester,
  ) async {
    // ARRANGE — 3-gombos navigációt szimulálunk alsó view-paddinggel.
    tester.view.padding = const FakeViewPadding(bottom: 96);
    addTearDown(tester.view.reset);
    final race = Race.create(id: 'r1', name: 'Kedd esti', marks: const [mark]);
    await pumpDetail(tester, race);
    await tester.pumpAndSettle();

    // ACT — az alsó sáv alsó pereme logikai pixelben.
    final dpr = tester.view.devicePixelRatio;
    final screenHeight = tester.view.physicalSize.height / dpr;
    final bottomInset = 96 / dpr;
    final barBottom = tester.getBottomRight(find.byType(DetailActionBar)).dy;

    // ASSERT — a sáv a rendszer-inset sávja fölött van; SafeArea nélkül a
    // navsáv alá csúszna, ezt védi ez a teszt.
    expect(barBottom, lessThanOrEqualTo(screenHeight - bottomInset));
  });

  testWidgets('renders the status strip above the course list', (tester) async {
    // ARRANGE & ACT
    final race = Race.create(id: 'r1', name: 'Kedd esti', marks: const [mark]);
    await pumpDetail(tester, race);
    await tester.pumpAndSettle();

    // ASSERT - a csik es a szakasz-cimke all a bojak folott, es a bojak a
    // sajat sor-widgetjukben (nem ListTile-ban).
    expect(find.byType(DetailStatusStrip), findsOneWidget);
    expect(find.text(l10nOf(tester).detailCourseLabel), findsOneWidget);
    expect(find.byType(DetailMarkRow), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(
      tester.getTopLeft(find.byType(DetailStatusStrip)).dy,
      lessThan(tester.getTopLeft(find.byType(DetailMarkRow)).dy),
    );
  });

  testWidgets('keeps the mark coordinate format untouched', (tester) async {
    // ARRANGE & ACT
    final race = Race.create(id: 'r1', name: 'Kedd esti', marks: const [mark]);
    await pumpDetail(tester, race);
    await tester.pumpAndSettle();

    // ASSERT - ADR 0044 D25: tizedes fok, negy jeggyel.
    expect(find.text('46.9000, 18.0500'), findsOneWidget);
  });

  testWidgets('puts the track section above the list when finished', (
    tester,
  ) async {
    // ARRANGE & ACT
    final race = Race.create(
      id: 'r1',
      name: 'Kedd esti',
      marks: const [mark],
    ).start(at: clock).finish(at: clock.add(const Duration(hours: 3)));
    await pumpDetail(tester, race);
    await tester.pumpAndSettle();

    // ASSERT - a track-szekcio a palya-lista FOLE kerul, es nincs also sav.
    expect(find.byType(PostRaceAnalysisSection), findsOneWidget);
    expect(find.byType(DetailActionBar), findsNothing);
    expect(
      tester.getTopLeft(find.byType(PostRaceAnalysisSection)).dy,
      lessThan(tester.getTopLeft(find.byType(DetailMarkRow)).dy),
    );
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
