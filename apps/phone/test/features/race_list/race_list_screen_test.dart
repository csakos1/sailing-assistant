import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_detail/race_detail_screen.dart';
import 'package:phone/features/race_list/race_list_screen.dart';
import 'package:phone/features/race_setup/race_setup_screen.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/race_repository_provider.dart';

void main() {
  const mark = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.9, longitude: 18.05),
  );

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
    final l10n = AppLocalizations.of(
      tester.element(find.byType(RaceListScreen)),
    )!;

    // ASSERT
    expect(find.text(l10n.listEmpty), findsOneWidget);
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
