import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/app/localization_delegates.dart';
import 'package:phone/features/race_detail/race_detail_screen.dart';
import 'package:phone/features/race_detail/widgets/detail_action_bar.dart';
import 'package:phone/features/race_detail/widgets/detail_course_mark_row.dart';
import 'package:phone/features/race_detail/widgets/detail_start_point_row.dart';
import 'package:phone/features/race_detail/widgets/post_race_analysis_section.dart';
import 'package:phone/features/race_detail/widgets/race_detail_strip.dart';
import 'package:phone/features/race_edit/race_edit_screen.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/local_wall_clock_provider.dart';
import 'package:phone/providers/pending_race_deletions_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';
import 'package:phone/providers/rounding_sample_reader_provider.dart';
import 'package:phone/providers/tick_provider.dart';

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
        // UTC-ben szamol, hogy a gep idozonaja ne szamitson; a tick nem jar,
        // igy az eltelt ido a rogzitett orabol jon (nincs fuggo timer).
        localWallClockProvider.overrideWithValue((instant) => instant.toUtc()),
        tickProvider.overrideWith((ref) => const Stream<DateTime>.empty()),
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
          localizationsDelegates: phoneLocalizationsDelegates,
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

  // A megerosito dialogus egy gombja.
  Finder dialogButton(String label) => find.descendant(
    of: find.byType(ForetackDialog<bool>),
    matching: find.text(label),
  );

  testWidgets('notStarted: a Rajt megerősítés után elindítja a versenyt', (
    tester,
  ) async {
    // ARRANGE
    final race = Race.create(id: 'r1', name: 'Kedd esti', marks: const [mark]);
    await pumpDetail(tester, race);
    final l10n = l10nOf(tester);

    // ACT - 32c: Rajt -> dialogus -> Rajt.
    await tester.tap(find.text(l10n.detailStart));
    await tester.pumpAndSettle();
    expect(find.text(l10n.instrumentsStartMessage), findsOneWidget);
    await tester.tap(dialogButton(l10n.instrumentsStartConfirm));
    await tester.pumpAndSettle();

    // ASSERT - aktivkent mentve a mostani idovel, a sav Celra valt.
    expect(repository.saved, hasLength(1));
    expect(repository.saved.single.status, RaceStatus.active);
    expect(repository.saved.single.startedAt, clock);
    expect(find.text(l10n.detailFinish), findsOneWidget);
    expect(
      rowBackgroundOf(tester, l10n.detailFinish),
      foretackTheme.colorScheme.surfaceContainer,
    );
  });

  testWidgets('notStarted: a Rajt Mégse-re nem indít', (tester) async {
    // ARRANGE
    final race = Race.create(id: 'r1', name: 'Kedd esti', marks: const [mark]);
    await pumpDetail(tester, race);
    final l10n = l10nOf(tester);

    // ACT
    await tester.tap(find.text(l10n.detailStart));
    await tester.pumpAndSettle();
    await tester.tap(dialogButton(l10n.instrumentsStartCancel));
    await tester.pumpAndSettle();

    // ASSERT
    expect(repository.saved, isEmpty);
    expect(container.read(activeRaceProvider), isNull);
  });

  testWidgets('a tervezett rajt AUTOMATIKUS cellát és Rajt most-ot kap', (
    tester,
  ) async {
    // ARRANGE - a rajt ma 14:00, most 12:00 van.
    final race = Race.create(
      id: 'r1',
      name: 'Kekszalag',
      marks: const [mark],
      scheduledStartAt: DateTime.utc(2025, 6, 1, 14),
    );
    await pumpDetail(tester, race);
    final l10n = l10nOf(tester);

    // ASSERT - 32a: a csik a napot es az idot, a sav az automatikus rajtot.
    expect(find.text(l10n.detailScheduledStartLabel), findsOneWidget);
    expect(find.text('MA 14:00'), findsOneWidget);
    expect(find.text(l10n.detailAutomaticStart), findsOneWidget);
    expect(find.text('14:00'), findsOneWidget);

    // ACT - Rajt most -> a dialogus kimondja a tervezett idot.
    await tester.tap(find.text(l10n.detailStartNow));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.detailStartScheduledMessage('14:00')),
      findsOneWidget,
    );
    await tester.tap(dialogButton(l10n.instrumentsStartConfirm));
    await tester.pumpAndSettle();

    // ASSERT - a rajtido a mostani pillanat, nem a tervezett.
    expect(repository.saved.single.startedAt, clock);
  });

  testWidgets('egy lejárt tervezett rajt csak a sima Rajtot kapja', (
    tester,
  ) async {
    // ARRANGE - a rajt ma 08:00 volt, a 3 oras ablak 11:00-kor lejart.
    final race = Race.create(
      id: 'r1',
      name: 'Kekszalag',
      marks: const [mark],
      scheduledStartAt: DateTime.utc(2025, 6, 1, 8),
    );
    await pumpDetail(tester, race);
    final l10n = l10nOf(tester);

    // ASSERT - a csik a rajtidot mutatja, a sav nem iger automatikus rajtot.
    expect(find.text('MA 08:00'), findsOneWidget);
    expect(find.text(l10n.detailAutomaticStart), findsNothing);
    expect(find.text(l10n.detailStart), findsOneWidget);
  });

  testWidgets('nem indít kézzel, ha a dialógus alatt a verseny elindult', (
    tester,
  ) async {
    // ARRANGE
    final race = Race.create(
      id: 'r1',
      name: 'Kekszalag',
      marks: const [mark],
      scheduledStartAt: DateTime.utc(2025, 6, 1, 14),
    );
    await pumpDetail(tester, race);
    final l10n = l10nOf(tester);
    await tester.tap(find.text(l10n.detailStartNow));
    await tester.pumpAndSettle();

    // ACT - a dialogus alatt az engine rajtja atvetelre kerul (ADR 0055
    // D6), majd a felhasznalo megis megerositi a kezi rajtot.
    final engineStart = clock.subtract(const Duration(minutes: 1));
    container.read(activeRaceProvider.notifier).activeRace = race.start(
      at: engineStart,
    );
    await tester.pump();
    await tester.tap(dialogButton(l10n.instrumentsStartConfirm));
    await tester.pumpAndSettle();

    // ASSERT - a kezi rajt elmarad, az atvett rajtido marad.
    expect(repository.saved, isEmpty);
    expect(container.read(activeRaceProvider)?.startedAt, engineStart);
  });

  testWidgets('active: a Cél megerősítés után befejezi a versenyt', (
    tester,
  ) async {
    // ARRANGE - az aktiv race-t a holderbe ultetjuk.
    final race = Race.create(
      id: 'r1',
      name: 'Kedd esti',
      marks: const [mark],
    ).start(at: clock);
    container.read(activeRaceProvider.notifier).activeRace = race;
    await pumpDetail(tester, race);
    final l10n = l10nOf(tester);

    // ACT
    await tester.tap(find.text(l10n.detailFinish));
    await tester.pumpAndSettle();
    expect(find.text(l10n.detailFinishMessage), findsOneWidget);
    await tester.tap(dialogButton(l10n.detailFinishConfirm));
    await tester.pumpAndSettle();

    // ASSERT - befejezett allapot mentve, es az egesz also sav eltunik.
    expect(repository.saved, hasLength(1));
    expect(repository.saved.single.status, RaceStatus.finished);
    expect(find.byType(DetailActionBar), findsNothing);
  });

  testWidgets('active: a Cél Mégse-re a verseny fut tovább', (tester) async {
    // ARRANGE
    final race = Race.create(
      id: 'r1',
      name: 'Kedd esti',
      marks: const [mark],
    ).start(at: clock);
    container.read(activeRaceProvider.notifier).activeRace = race;
    await pumpDetail(tester, race);
    final l10n = l10nOf(tester);

    // ACT
    await tester.tap(find.text(l10n.detailFinish));
    await tester.pumpAndSettle();
    await tester.tap(dialogButton(l10n.detailFinishCancel));
    await tester.pumpAndSettle();

    // ASSERT
    expect(repository.saved, isEmpty);
    expect(container.read(activeRaceProvider)?.status, RaceStatus.active);
  });

  testWidgets('active: a csík az eltelt időt és az aktív bóját mutatja', (
    tester,
  ) async {
    // ARRANGE
    const second = Mark(
      sequence: 2,
      name: 'Z2',
      position: Coordinate(latitude: 46.8, longitude: 17.9),
    );
    final race = Race.create(
      id: 'r1',
      name: 'Kedd esti',
      marks: const [mark, second],
    ).start(at: clock.subtract(const Duration(minutes: 42, seconds: 10)));
    container.read(activeRaceProvider.notifier).activeRace = race;

    // ACT
    await pumpDetail(tester, race);
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    // ASSERT - 32b: az eltelt ido, es csak az elso boja aktiv.
    expect(find.text('00:42:10'), findsOneWidget);
    expect(find.text(l10n.detailActiveMarkTag), findsOneWidget);
    final active = tester.widget<DetailCourseMarkRow>(
      find.widgetWithText(DetailCourseMarkRow, 'Z1'),
    );
    expect(active.isActive, isTrue);
  });

  testWidgets('a rajthely a pálya élén áll, rajt után tompítva', (
    tester,
  ) async {
    // ARRANGE
    final race = Race.create(
      id: 'r1',
      name: 'Kekszalag',
      marks: const [mark],
      startPoint: const StartPoint(
        name: 'Rajtvonal',
        position: Coordinate(latitude: 46.95, longitude: 17.9),
      ),
    );

    // ACT - el nem indult verseny.
    await pumpDetail(tester, race);
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    // ASSERT - a koordinata latszik, es a sor a bojak elott all.
    expect(find.text(l10n.detailStartPointName('Rajtvonal')), findsOneWidget);
    expect(find.text(l10n.detailStartPointTag), findsOneWidget);
    expect(find.text('46.9500, 17.9000'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(DetailStartPointRow)).dy,
      lessThan(tester.getTopLeft(find.byType(DetailCourseMarkRow)).dy),
    );

    // ACT - a verseny elindult.
    final started = race.start(at: DateTime.utc(2025, 6, 1, 11, 17, 50));
    container.read(activeRaceProvider.notifier).activeRace = started;
    await tester.pumpAndSettle();

    // ASSERT - a koordinata helyen a rajt ideje, a sor 60%-ra tompul.
    expect(find.text(l10n.detailStartedAt('11:17:50')), findsOneWidget);
    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(DetailStartPointRow),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, DetailStartPointRow.startedOpacity);
  });

  testWidgets('a fejrész 58 dp magas', (tester) async {
    // ARRANGE & ACT
    final race = Race.create(id: 'r1', name: 'Kedd esti', marks: const [mark]);
    await pumpDetail(tester, race);

    // ASSERT
    expect(tester.getSize(find.byType(AppBar)).height, 58);
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
          localizationsDelegates: phoneLocalizationsDelegates,
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

  testWidgets('a törlés elrejt, és csak az ablak végén töröl', (
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
          localizationsDelegates: phoneLocalizationsDelegates,
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
    // A 35d adatcellaja a verseny nevet es a bojak szamat mutatja.
    final subject = find.byType(ForetackDialogSubjectCell);
    expect(
      find.descendant(of: subject, matching: find.text('Kedd esti')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: subject, matching: find.text('1 BÓJA')),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(ForetackDialog<bool>),
        matching: find.text(l10n.detailDeleteConfirm),
      ),
    );
    await tester.pump();
    // A route-atmenet (Androidon 450 ms) biztosan lefut.
    await tester.pump(const Duration(seconds: 1));

    // ASSERT - visszanavigal, a VISSZAVONAS-snackbar latszik, de a DB-ben
    // meg nincs torles (ADR 0056 D6).
    expect(find.byType(RaceDetailScreen), findsNothing);
    expect(find.text(l10n.detailDeletedMessage), findsOneWidget);
    expect(container.read(pendingRaceDeletionsProvider), {'r1'});
    expect(repository.deleted, isEmpty);

    // ACT - lejar a visszavonasi ablak.
    await tester.pump(raceDeletionUndoWindow + const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // ASSERT
    expect(repository.deleted, ['r1']);
  });

  testWidgets('a VISSZAVONAS megtartja a versenyt', (tester) async {
    // ARRANGE
    final race = Race.create(id: 'r1', name: 'Kedd esti', marks: const [mark]);
    container.read(activeRaceProvider.notifier).activeRace = race;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: foretackTheme,
          locale: const Locale('hu'),
          localizationsDelegates: phoneLocalizationsDelegates,
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
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(ForetackDialog<bool>),
        matching: find.text(l10n.detailDeleteConfirm),
      ),
    );
    await tester.pump();
    // A route-atmenet (Androidon 450 ms) biztosan lefut.
    await tester.pump(const Duration(seconds: 1));

    expect(container.read(activeRaceProvider), isNull);

    // ACT
    await tester.tap(find.text(l10n.detailDeleteUndo.toUpperCase()));
    await tester.pump(raceDeletionUndoWindow + const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // ASSERT - a kivalasztas is visszajon.
    expect(container.read(pendingRaceDeletionsProvider), isEmpty);
    expect(repository.deleted, isEmpty);
    expect(container.read(activeRaceProvider)?.id, 'r1');
  });

  testWidgets('futo versenyen nincs torles', (tester) async {
    // ARRANGE & ACT
    final race = Race.create(
      id: 'r1',
      name: 'Kedd esti',
      marks: const [mark],
    ).start(at: clock);
    await pumpDetail(tester, race);
    await tester.pumpAndSettle();

    // ASSERT - elobb a Cel zarja le (ADR 0056 Pontositas U8).
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('a torles-dialogus a 35d szoveget mutatja', (tester) async {
    // ARRANGE
    final race = Race.create(id: 'r1', name: 'Kedd esti', marks: const [mark]);
    await pumpDetail(tester, race);
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    // ACT
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.text('Törlöd a versenyt?'), findsOneWidget);
    expect(find.text(l10n.detailDeleteMessage), findsOneWidget);
    expect(l10n.detailDeleteMessage, isNot(contains('vissza')));
  });

  testWidgets('a torles Megse-re semmit nem torol, a reszlet marad', (
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
          localizationsDelegates: phoneLocalizationsDelegates,
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
      find.descendant(
        of: find.byType(ForetackDialog<bool>),
        matching: find.text(l10n.detailDeleteCancel),
      ),
    );
    await tester.pumpAndSettle();

    // ASSERT
    expect(repository.deleted, isEmpty);
    expect(find.byType(RaceDetailScreen), findsOneWidget);
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
    expect(find.byType(RaceDetailStrip), findsOneWidget);
    expect(find.text(l10nOf(tester).detailCourseLabel), findsOneWidget);
    expect(find.byType(DetailCourseMarkRow), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(
      tester.getTopLeft(find.byType(RaceDetailStrip)).dy,
      lessThan(tester.getTopLeft(find.byType(DetailCourseMarkRow)).dy),
    );
  });

  testWidgets('keeps the mark coordinate format untouched', (tester) async {
    // ARRANGE & ACT
    final race = Race.create(id: 'r1', name: 'Kedd esti', marks: const [mark]);
    await pumpDetail(tester, race);
    await tester.pumpAndSettle();

    // ASSERT - ADR 0044 D25: tizedes fok, negy jeggyel (felhasznaloi
    // dontes, U6: a makett fok-perce helyett).
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
      lessThan(tester.getTopLeft(find.byType(DetailCourseMarkRow)).dy),
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
