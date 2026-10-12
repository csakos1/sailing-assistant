import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';
import 'package:phone/providers/race_start_signal_provider.dart';

/// Minimál in-memory repo — a state-átmenetek perzisztálását igazoljuk a
/// `store`-on át (watchRaces itt nem releváns).
class _FakeRaceRepository implements RaceRepository {
  final Map<String, Race> store = {};

  @override
  Future<void> save(Race race) async => store[race.id] = race;

  @override
  Future<Race?> getRace(String id) async => store[id];

  @override
  Stream<List<Race>> watchRaces() => const Stream<List<Race>>.empty();

  @override
  Future<void> delete(String id) async => store.remove(id);
}

void main() {
  late _FakeRaceRepository repository;
  late ProviderContainer container;
  final fixedNow = DateTime(2025, 6, 1, 12);

  const markA = Mark(
    sequence: 1,
    name: '1. bója',
    position: Coordinate(latitude: 46.9, longitude: 17.9),
  );
  const markB = Mark(
    sequence: 2,
    name: '2. bója',
    position: Coordinate(latitude: 46.8, longitude: 17.8),
  );
  final race = Race.create(
    id: 'race-1',
    name: 'Teszt',
    marks: const [markA, markB],
  );

  setUp(() {
    repository = _FakeRaceRepository();
    container = ProviderContainer(
      overrides: [
        raceRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => fixedNow),
      ],
    );
    addTearDown(container.dispose);
  });

  ActiveRaceNotifier notifier() => container.read(activeRaceProvider.notifier);

  RaceStartSignal? startSignal() => container.read(raceStartSignalProvider);

  test('kezdő állapot null', () {
    expect(container.read(activeRaceProvider), isNull);
  });

  test('az activeRace setter beállít és nulláz', () {
    notifier().activeRace = race;
    expect(container.read(activeRaceProvider), equals(race));

    notifier().activeRace = null;
    expect(container.read(activeRaceProvider), isNull);
  });

  test('start active-ra vált és perzisztál az injektált órával', () async {
    notifier().activeRace = race;
    await notifier().start();

    final state = container.read(activeRaceProvider);
    expect(state!.status, equals(RaceStatus.active));
    expect(state.startedAt, equals(fixedNow));
    expect(repository.store['race-1'], equals(state));
  });

  test('finish finished-re vált és perzisztál', () async {
    notifier().activeRace = race;
    await notifier().start();
    await notifier().finish();

    final state = container.read(activeRaceProvider);
    expect(state!.status, equals(RaceStatus.finished));
    expect(state.finishedAt, equals(fixedNow));
    expect(repository.store['race-1'], equals(state));
  });

  group('start signal', () {
    test('a manual start signals the started race', () async {
      // Arrange
      notifier().activeRace = race;

      // Act
      await notifier().start();

      // Assert
      expect(startSignal()?.raceId, 'race-1');
    });

    test('selecting or finishing a race does not signal', () async {
      // Arrange
      notifier().activeRace = race.start(at: fixedNow);

      // Act
      await notifier().finish();

      // Assert
      expect(startSignal(), isNull);
    });

    test('an adopted engine start signals once it is selected', () async {
      // Arrange: késő átvétel, órákkal a tervezett rajt után.
      repository.store['race-1'] = race;
      final scheduledLongAgo = fixedNow.subtract(const Duration(hours: 3));

      // Act
      await notifier().adoptEngineStart('race-1', at: scheduledLongAgo);

      // Assert
      expect(startSignal()?.raceId, 'race-1');
    });

    test('an adoption behind another active race does not signal', () async {
      // Arrange
      repository.store['race-1'] = race;
      notifier().activeRace = Race.create(
        id: 'race-2',
        name: 'Masik',
        marks: const [markA],
      ).start(at: fixedNow);

      // Act
      await notifier().adoptEngineStart('race-1', at: fixedNow);

      // Assert
      expect(startSignal(), isNull);
    });

    test('an adoption of an already saved start does not signal', () async {
      // Arrange: a kézi „Rajt" jelzett előbb.
      notifier().activeRace = race;
      await notifier().start();
      final first = startSignal();

      // Act
      await notifier().adoptEngineStart('race-1', at: fixedNow);

      // Assert
      expect(startSignal(), first);
    });

    test('each start gets a new serial', () {
      // Act
      container.read(raceStartSignalProvider.notifier)
        ..signal('race-1')
        ..signal('race-1');

      // Assert
      expect(startSignal(), (raceId: 'race-1', serial: 2));
    });
  });

  test('start no-op, ha nincs aktív race', () async {
    await notifier().start();
    expect(container.read(activeRaceProvider), isNull);
    expect(repository.store, isEmpty);
  });

  test('roundCurrentMark a következő bójára lép és perzisztál', () async {
    notifier().activeRace = race;
    await notifier().start();
    await notifier().roundCurrentMark();

    final state = container.read(activeRaceProvider)!;
    expect(state.status, equals(RaceStatus.active));
    expect(state.activeMarkOrNull, equals(markB));
    expect(repository.store['race-1'], equals(state));
  });

  test('roundCurrentMark az utolsó bóyán befejezi a versenyt', () async {
    notifier().activeRace = race;
    await notifier().start();
    await notifier().roundCurrentMark(); // 1. bója → 2. bója
    await notifier().roundCurrentMark(); // 2. bója → finished

    final state = container.read(activeRaceProvider)!;
    expect(state.status, equals(RaceStatus.finished));
    expect(state.activeMarkOrNull, isNull);
    expect(state.finishedAt, equals(fixedNow));
  });

  test('roundCurrentMark no-op, ha nincs aktív race', () async {
    await notifier().roundCurrentMark();
    expect(container.read(activeRaceProvider), isNull);
    expect(repository.store, isEmpty);
  });

  group('finishFromEngine', () {
    final engineFinish = fixedNow.add(const Duration(hours: 2));

    test('the selected race finishes at the engine time', () async {
      // Arrange
      notifier().activeRace = race;
      await notifier().start();

      // Act
      await notifier().finishFromEngine('race-1', at: engineFinish);

      // Assert
      final state = container.read(activeRaceProvider)!;
      expect(state.status, RaceStatus.finished);
      expect(state.finishedAt, engineFinish);
      expect(repository.store['race-1'], state);
    });

    test('a race not selected is finished from the database', () async {
      // Arrange
      repository.store['race-1'] = race.start(at: fixedNow);
      final other = Race.create(
        id: 'race-2',
        name: 'Masik',
        marks: const [markA],
      );
      notifier().activeRace = other;

      // Act
      await notifier().finishFromEngine('race-1', at: engineFinish);

      // Assert
      expect(repository.store['race-1']?.finishedAt, engineFinish);
      expect(container.read(activeRaceProvider), other);
    });

    test('an unknown race is ignored', () async {
      // Act
      await notifier().finishFromEngine('race-9', at: engineFinish);

      // Assert
      expect(repository.store, isEmpty);
    });

    test('a finish time before the start is clamped to the start', () async {
      // Arrange
      notifier().activeRace = race;
      await notifier().start();

      // Act
      await notifier().finishFromEngine(
        'race-1',
        at: fixedNow.subtract(const Duration(seconds: 2)),
      );

      // Assert
      expect(container.read(activeRaceProvider)?.finishedAt, fixedNow);
    });

    test('a race already finished in the app is left alone', () async {
      // Arrange
      notifier().activeRace = race;
      await notifier().start();
      await notifier().finish();
      final finished = container.read(activeRaceProvider)!;

      // Act
      await notifier().finishFromEngine('race-1', at: engineFinish);

      // Assert
      expect(container.read(activeRaceProvider), finished);
      expect(repository.store['race-1'], finished);
    });
  });

  group('adoptEngineStart', () {
    final scheduled = fixedNow.add(const Duration(minutes: 30));
    final other = Race.create(
      id: 'race-2',
      name: 'Masik',
      marks: const [markA],
    );

    test('a race started by the engine is saved and selected', () async {
      // Arrange: the rule picked race-1, the UI has race-2 selected.
      repository.store['race-1'] = race;
      notifier().activeRace = other;

      // Act
      await notifier().adoptEngineStart('race-1', at: scheduled);

      // Assert
      final state = container.read(activeRaceProvider)!;
      expect(state.id, 'race-1');
      expect(state.status, RaceStatus.active);
      expect(state.startedAt, scheduled);
      expect(repository.store['race-1'], state);
    });

    test('the selected race is started from its live state', () async {
      // Arrange
      notifier().activeRace = race;

      // Act
      await notifier().adoptEngineStart('race-1', at: scheduled);

      // Assert
      expect(container.read(activeRaceProvider)?.startedAt, scheduled);
      expect(repository.store['race-1']?.startedAt, scheduled);
    });

    test('the first saved start is kept', () async {
      // Arrange: a manual Rajt was saved before the engine snapshot.
      notifier().activeRace = race;
      await notifier().start();
      final started = container.read(activeRaceProvider)!;

      // Act
      await notifier().adoptEngineStart('race-1', at: scheduled);

      // Assert
      expect(container.read(activeRaceProvider), started);
      expect(repository.store['race-1']?.startedAt, fixedNow);
    });

    test('another active race keeps the selection', () async {
      // Arrange
      repository.store['race-1'] = race;
      final otherActive = other.start(at: fixedNow);
      notifier().activeRace = otherActive;

      // Act
      await notifier().adoptEngineStart('race-1', at: scheduled);

      // Assert
      expect(container.read(activeRaceProvider), otherActive);
      expect(repository.store['race-1']?.status, RaceStatus.active);
    });

    test('an unknown race is ignored', () async {
      // Act
      await notifier().adoptEngineStart('race-9', at: scheduled);

      // Assert
      expect(repository.store, isEmpty);
      expect(container.read(activeRaceProvider), isNull);
    });
  });
}
