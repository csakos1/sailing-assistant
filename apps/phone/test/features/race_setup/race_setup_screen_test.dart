import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_setup/race_setup_screen.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/id_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';

void main() {
  late _FakeRaceRepository repository;

  setUp(() {
    repository = _FakeRaceRepository();
  });

  // A setupot egy home-route fölé pusholjuk, hogy a mentés utáni pop tiszta
  // visszatérést adjon, és a navigáció is assertelhető legyen.
  Future<void> openSetup(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          idProvider.overrideWithValue(() => 'fixed-id'),
          raceRepositoryProvider.overrideWithValue(repository),
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

  testWidgets('érvényes adatokkal a race mentésre kerül és visszanavigál', (
    tester,
  ) async {
    // ARRANGE
    await openSetup(tester);

    // ACT — mezők tree-sorrendben: verseny-név, bója-név, lat, lon.
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Kedd esti');
    await tester.enterText(fields.at(1), 'Z1');
    await tester.enterText(fields.at(2), '46.9');
    await tester.enterText(fields.at(3), '18.05');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

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
