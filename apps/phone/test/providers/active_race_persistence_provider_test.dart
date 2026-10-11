import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/active_race_persistence_provider.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/last_recording_reader_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';
import 'package:phone/providers/race_start_signal_provider.dart';
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

  @override
  Future<InstrumentsRaceChoice?> readInstrumentsRaceChoice() async => null;

  @override
  Future<void> writeInstrumentsRaceChoice(
    InstrumentsRaceChoice? choice,
  ) async {}
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
  // A visszatoltes jelzese a folytathatosagot nezi (6 ora, ADR 0054 E3).
  final startedAt = DateTime.utc(2026, 7, 30, 9);
  var now = startedAt.add(const Duration(minutes: 30));
  DateTime? lastRecordedAt;

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
    now = startedAt.add(const Duration(minutes: 30));
    lastRecordedAt = null;
    settings = _FakeSettingsRepository();
    repo = _FakeRaceRepository();
    container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settings),
        raceRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(() => now),
        lastRecordingReaderProvider.overrideWithValue(
          (_) async => lastRecordedAt,
        ),
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

    test('futó verseny visszatöltése a Műszerekre váltást jelzi', () async {
      // ARRANGE
      settings.storedId = 'race-1';
      repo.race = makeRace().start(at: startedAt);

      // ACT
      activatePersistence();
      await pumpEventQueue();

      // ASSERT
      expect(
        container.read(raceStartSignalProvider),
        (raceId: 'race-1', serial: 1),
      );
    });

    test('régóta félbehagyott verseny visszatöltése nem jelez', () async {
      // ARRANGE — a legutobbi felvetel 7 oraja volt
      now = startedAt.add(const Duration(hours: 8));
      lastRecordedAt = startedAt.add(const Duration(hours: 1));
      settings.storedId = 'race-1';
      repo.race = makeRace().start(at: startedAt);

      // ACT
      activatePersistence();
      await pumpEventQueue();

      // ASSERT — a verseny visszatoltodik, de nincs ful-valtas
      expect(container.read(activeRaceProvider)?.id, 'race-1');
      expect(container.read(raceStartSignalProvider), isNull);
    });

    test('friss felvétel mellett a hosszú verseny is jelez', () async {
      // ARRANGE — a ketnapos Kekszalag: a rajt regi, a felvetel friss
      now = startedAt.add(const Duration(hours: 20));
      lastRecordedAt = now.subtract(const Duration(minutes: 3));
      settings.storedId = 'race-1';
      repo.race = makeRace().start(at: startedAt);

      // ACT
      activatePersistence();
      await pumpEventQueue();

      // ASSERT
      expect(container.read(raceStartSignalProvider)?.raceId, 'race-1');
    });

    test('el nem indult verseny visszatöltése nem jelez', () async {
      // ARRANGE
      settings.storedId = 'race-1';
      repo.race = makeRace();

      // ACT
      activatePersistence();
      await pumpEventQueue();

      // ASSERT
      expect(container.read(raceStartSignalProvider), isNull);
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

      // ASSERT — a választott race marad, és nincs fül-váltás
      expect(container.read(activeRaceProvider), equals(other));
      expect(container.read(raceStartSignalProvider), isNull);
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
