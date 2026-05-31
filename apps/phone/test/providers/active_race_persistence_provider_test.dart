import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/active_race_persistence_provider.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';
import 'package:phone/providers/settings_repository_provider.dart';

/// Fake settings-tár: a readActiveRaceId a `storedId`-t adja, a
/// writeActiveRaceId gyűjti az írásokat (és frissíti a storedId-t).
class _FakeSettingsRepository implements SettingsRepository {
  String? storedId;
  final List<String?> writes = [];

  @override
  Future<String?> readActiveRaceId() async => storedId;

  @override
  Future<void> writeActiveRaceId(String? id) async {
    writes.add(id);
    storedId = id;
  }
}

/// Fake race-repo: a getRace a beállított `race`-t adja (a restore-hoz).
class _FakeRaceRepository implements RaceRepository {
  Race? race;

  @override
  Future<Race?> getRace(String id) async => race;

  @override
  Future<void> save(Race race) async {}

  @override
  Stream<List<Race>> watchRaces() => const Stream<List<Race>>.empty();

  @override
  Future<void> delete(String id) async {}
}

void main() {
  late ProviderContainer container;
  late _FakeSettingsRepository settings;
  late _FakeRaceRepository repo;

  const markA = Mark(
    sequence: 1,
    name: '1. bója',
    position: Coordinate(latitude: 46.9, longitude: 17.9),
  );

  Race makeRace() =>
      Race.create(id: 'race-1', name: 'Teszt', marks: const [markA]);

  ActiveRaceNotifier activeRace() =>
      container.read(activeRaceProvider.notifier);

  /// Életre kelti a (keep-alive) perzisztencia-providert, és lebontja a végén.
  void activatePersistence() {
    final sub = container.listen(activeRacePersistenceProvider, (_, _) {});
    addTearDown(sub.close);
  }

  setUp(() {
    settings = _FakeSettingsRepository();
    repo = _FakeRaceRepository();
    container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settings),
        raceRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
  });

  group('restore', () {
    test('tárolt id-re betölti az aktív race-t', () async {
      // ARRANGE
      settings.storedId = 'race-1';
      repo.race = makeRace();

      // ACT
      activatePersistence();
      await pumpEventQueue();

      // ASSERT
      expect(container.read(activeRaceProvider), equals(makeRace()));
    });

    test('tárolt id nélkül nem állít be aktív race-t', () async {
      // ACT — storedId == null (default)
      activatePersistence();
      await pumpEventQueue();

      // ASSERT
      expect(container.read(activeRaceProvider), isNull);
    });

    test('no-clobber: meglévő aktív race-t nem ír felül', () async {
      // ARRANGE — a user már választott egy MÁSIK race-t
      final other = Race.create(
        id: 'race-2',
        name: 'Másik',
        marks: const [markA],
      );
      activeRace().activeRace = other;
      settings.storedId = 'race-1';
      repo.race = makeRace();

      // ACT
      activatePersistence();
      await pumpEventQueue();

      // ASSERT — a választott race marad
      expect(container.read(activeRaceProvider), equals(other));
    });
  });

  group('perzisztálás', () {
    test('kiválasztáskor menti az id-t', () async {
      // ARRANGE
      activatePersistence();
      await pumpEventQueue(); // a restore lefut (no-op, üres tár)

      // ACT
      activeRace().activeRace = makeRace(); // notStarted
      await pumpEventQueue();

      // ASSERT
      expect(settings.writes.last, equals('race-1'));
    });

    test('befejezett race esetén törli a tárolt id-t', () async {
      // ARRANGE
      activatePersistence();
      await pumpEventQueue();
      final finished = makeRace()
          .start(at: DateTime(2025, 6, 1, 12))
          .roundCurrentMark(
            at: DateTime(2025, 6, 1, 13),
          ); // 1 bója → auto-finish

      // ACT
      activeRace().activeRace = finished;
      await pumpEventQueue();

      // ASSERT — finished → null írás (delete-on-unset)
      expect(finished.status, equals(RaceStatus.finished));
      expect(settings.writes.last, isNull);
    });

    test('deaktiváláskor (null) törli a tárolt id-t', () async {
      // ARRANGE
      activatePersistence();
      await pumpEventQueue();
      activeRace().activeRace = makeRace();
      await pumpEventQueue();

      // ACT
      activeRace().activeRace = null;
      await pumpEventQueue();

      // ASSERT
      expect(settings.writes.last, isNull);
    });
  });
}
