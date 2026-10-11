import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/app/localization_delegates.dart';
import 'package:phone/features/race_detail/race_detail_screen.dart';
import 'package:phone/features/race_list/race_list_screen.dart';
import 'package:phone/features/race_list/widgets/race_list_row.dart';
import 'package:phone/features/race_setup/race_setup_screen.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/race_repository_provider.dart';
import 'package:phone/providers/race_track_stats_provider.dart';
import 'package:phone/providers/track_sample_reader_provider.dart';

import '../web_access/web_access_fakes.dart';

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
    final webStore = MemoryWebAccountStore();
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          raceRepositoryProvider.overrideWithValue(_FakeRaceRepository(races)),
          // A naplo stat-csikja a minta-olvasot hasznalja; enelkul a
          // navigacios teszt a valos adatbazist epitene fel.
          trackSampleReaderProvider.overrideWith((ref) {
            return (raceId) async => const <TrackSample>[];
          }),
          raceTrackStatsReaderProvider.overrideWith(
            (ref) =>
                (raceId) async => null,
          ),
          raceTrackStatsWriterProvider.overrideWith((ref) => _ignoreWrite),
          // A fokepernyo a webes allapotot frissiti (fuggo kerelem, fiok,
          // szalag); enelkul a valodi fiok-fajlt keresne.
          pendingJoinStoreProvider.overrideWithValue(webStore),
          webAccountStoreProvider.overrideWithValue(webStore),
        ],
        child: MaterialApp(
          theme: foretackTheme,
          locale: const Locale('hu'),
          localizationsDelegates: phoneLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RaceListScreen(),
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
    await tester.tap(find.byType(RaceListRow));
    await tester.pumpAndSettle();

    // ASSERT — a detail nyílt meg.
    expect(find.byType(RaceDetailScreen), findsOneWidget);
  });

  testWidgets('az Új verseny gomb a setup képernyőt nyitja', (
    tester,
  ) async {
    // ARRANGE
    await pumpList(tester, const []);
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    // ACT
    await tester.tap(find.widgetWithText(FilledButton, l10n.listAddRace));
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

  testWidgets('a befejezettek nem latszanak, es nincs naplo-gomb', (
    tester,
  ) async {
    // ARRANGE — csak befejezett -> a fo lista ures.
    await pumpList(tester, [finishedRace('r1', 'Charlie')]);
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    // ASSERT — a naplo a hej sajat fule (ADR 0056 D2), itt nincs gombja.
    expect(find.text(l10n.listEmpty), findsOneWidget);
    expect(find.text('Charlie'), findsNothing);
    expect(find.byIcon(Icons.history), findsNothing);
  });

  testWidgets('nincs kulon debug-ikon az AppBar-on', (tester) async {
    // ARRANGE & ACT
    await pumpList(tester, const []);
    await tester.pumpAndSettle();

    // ASSERT — a ket debug-kepernyo a ⋮ menube kerult (ADR 0056 D7).
    expect(find.byIcon(Icons.bug_report_outlined), findsNothing);
    expect(find.byIcon(Icons.memory_outlined), findsNothing);
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

/// A gyorsitotar-iro semmit nem csinalo dublore a teszthez.
Future<void> _ignoreWrite(
  String raceId,
  TrackStats stats, {
  required int sampleCount,
  required DateTime computedAt,
}) async {}
