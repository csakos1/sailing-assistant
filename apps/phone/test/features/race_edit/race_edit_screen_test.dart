import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_edit/race_edit_screen.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/mark_library_repository_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';

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

  late _FakeRaceRepository repository;
  late _FakeMarkLibraryRepository library;

  setUp(() {
    repository = _FakeRaceRepository();
    library = _FakeMarkLibraryRepository();
  });

  // Az edit-screent egy home-route fölé pusholjuk, hogy a mentés utáni pop
  // tiszta visszatérést adjon, és a navigáció assertelhető legyen.
  Future<void> openEdit(WidgetTester tester, Race race) async {
    // Nagyobb teszt-viewport: a (picker-gombbal magasabb) űrlap teljesen
    // épüljön fel — különben a lusta ListView az AppBar alatt lapozott
    // Mentés gombot nem építené meg, és a find.byType(FilledButton) 0-t adna.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          raceRepositoryProvider.overrideWithValue(repository),
          markLibraryRepositoryProvider.overrideWithValue(library),
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
                    builder: (_) => RaceEditScreen(race: race),
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

  testWidgets('feltölti a meglévő versenyt, a cím editTitle', (tester) async {
    // ARRANGE & ACT
    final race = Race.create(
      id: 'r1',
      name: 'Régi',
      marks: const [markA, markB],
    );
    await openEdit(tester, race);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(RaceEditScreen)),
    )!;

    // ASSERT — a cím az edit-cím, a mezők feltöltve.
    expect(find.text(l10n.editTitle), findsOneWidget);
    expect(find.text('Régi'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('mentés megőrzi az id-t, frissíti a nevet, és visszanavigál', (
    tester,
  ) async {
    // ARRANGE
    final race = Race.create(
      id: 'r1',
      name: 'Régi',
      marks: const [markA, markB],
    );
    await openEdit(tester, race);

    // ACT — átírjuk a verseny nevét, majd mentünk.
    await tester.enterText(find.byType(TextFormField).first, 'Új név');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // ASSERT — ugyanaz az id, friss név, a bóyák megmaradtak; pop megtörtént.
    expect(repository.saved, hasLength(1));
    final saved = repository.saved.single;
    expect(saved.id, 'r1');
    expect(saved.name, 'Új név');
    expect(saved.status, RaceStatus.notStarted);
    expect(saved.marks.map((m) => m.name).toList(), ['A', 'B']);
    expect(saved.marks.map((m) => m.sequence).toList(), [1, 2]);
    expect(find.byType(RaceEditScreen), findsNothing);
  });

  testWidgets('mentéskor a bóyák a könyvtárba kerülnek az új névvel', (
    tester,
  ) async {
    // ARRANGE
    final race = Race.create(
      id: 'r1',
      name: 'Régi',
      marks: const [markA, markB],
    );
    await openEdit(tester, race);

    // ACT — átnevezés + mentés.
    await tester.enterText(find.byType(TextFormField).first, 'Új név');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // ASSERT — mindkét bója a frissített verseny-névvel kerül a könyvtárba.
    expect(library.saved, hasLength(2));
    expect(
      library.saved.map((m) => m.name).toList(),
      ['A', 'B'],
    );
    expect(
      library.saved.every((m) => m.sourceRaceName == 'Új név'),
      isTrue,
    );
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
