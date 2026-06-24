import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_setup/race_setup_screen.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/id_provider.dart';
import 'package:phone/providers/mark_library_repository_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';

void main() {
  late _FakeRaceRepository repository;
  late _FakeMarkLibraryRepository library;

  setUp(() {
    repository = _FakeRaceRepository();
    library = _FakeMarkLibraryRepository();
  });

  // A setupot egy home-route fölé pusholjuk, hogy a mentés utáni pop tiszta
  // visszatérést adjon, és a navigáció is assertelhető legyen. A markLibrary
  // override-olható (a hiba-tűrés teszthez dobó fake-re).
  Future<void> openSetup(
    WidgetTester tester, {
    MarkLibraryRepository? markLibrary,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          idProvider.overrideWithValue(() => 'fixed-id'),
          raceRepositoryProvider.overrideWithValue(repository),
          markLibraryRepositoryProvider.overrideWithValue(
            markLibrary ?? library,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('hu'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RaceSetupScreen(),
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
  }

  // Közös segéd: kitölti a mezőket egy érvényes versennyel, majd ment.
  Future<void> enterValidRaceAndSubmit(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Kedd esti');
    await tester.enterText(fields.at(1), 'Z1');
    await tester.enterText(fields.at(2), '46.9');
    await tester.enterText(fields.at(3), '18.05');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
  }

  testWidgets('érvényes adatokkal a race mentésre kerül és visszanavigál', (
    tester,
  ) async {
    // ARRANGE
    await openSetup(tester);

    // ACT
    await enterValidRaceAndSubmit(tester);

    // ASSERT
    expect(repository.saved, hasLength(1));
    final race = repository.saved.single;
    expect(race.id, 'fixed-id');
    expect(race.name, 'Kedd esti');
    expect(race.status, RaceStatus.notStarted);
    expect(race.marks, hasLength(1));
    expect(race.marks.single.name, 'Z1');
    expect(race.marks.single.position.latitude, 46.9);
    expect(race.marks.single.position.longitude, 18.05);
    expect(find.byType(RaceSetupScreen), findsNothing);
  });

  testWidgets('tartományon kívüli szélesség esetén nincs mentés', (
    tester,
  ) async {
    // ARRANGE
    await openSetup(tester);

    // ACT — a szélesség a -90..90 tartományon kívül.
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Kedd esti');
    await tester.enterText(fields.at(1), 'Z1');
    await tester.enterText(fields.at(2), '200');
    await tester.enterText(fields.at(3), '18.05');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // ASSERT — a validáció megállította a mentést, a képernyő marad.
    expect(repository.saved, isEmpty);
    expect(find.byType(RaceSetupScreen), findsOneWidget);
  });

  testWidgets('mentéskor a bóyák a könyvtárba is kerülnek', (tester) async {
    // ARRANGE
    await openSetup(tester);

    // ACT
    await enterValidRaceAndSubmit(tester);

    // ASSERT — a könyvtár a forrás-verseny nevével kapja a bóját (L5).
    expect(library.saved, hasLength(1));
    expect(library.saved.single.name, 'Z1');
    expect(library.saved.single.sourceRaceName, 'Kedd esti');
  });

  testWidgets('a könyvtár-írás hibája nem blokkolja a verseny-mentést', (
    tester,
  ) async {
    // ARRANGE — dobó könyvtár-fake.
    await openSetup(tester, markLibrary: _ThrowingMarkLibraryRepository());

    // ACT
    await enterValidRaceAndSubmit(tester);

    // ASSERT — a verseny mentése sikeres, és a pop megtörtént (best-effort).
    expect(repository.saved, hasLength(1));
    expect(find.byType(RaceSetupScreen), findsNothing);
  });
}

class _FakeRaceRepository implements RaceRepository {
  final saved = <Race>[];

  @override
  Future<void> save(Race race) async {
    saved.add(race);
  }

  @override
  Future<void> delete(String id) async {}

  @override
  Future<Race?> getRace(String id) async => null;

  @override
  Stream<List<Race>> watchRaces() => const Stream<List<Race>>.empty();
}

class _FakeMarkLibraryRepository implements MarkLibraryRepository {
  final saved = <SavedMark>[];

  @override
  Future<void> saveAll(Iterable<SavedMark> marks) async {
    saved.addAll(marks);
  }

  @override
  Stream<List<SavedMark>> watchAll() => const Stream<List<SavedMark>>.empty();
}

class _ThrowingMarkLibraryRepository implements MarkLibraryRepository {
  @override
  Future<void> saveAll(Iterable<SavedMark> marks) async {
    throw StateError('könyvtár-írás hiba');
  }

  @override
  Stream<List<SavedMark>> watchAll() => const Stream<List<SavedMark>>.empty();
}
