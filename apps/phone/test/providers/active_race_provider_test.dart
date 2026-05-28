import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';

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

  test('start no-op, ha nincs aktív race', () async {
    await notifier().start();
    expect(container.read(activeRaceProvider), isNull);
    expect(repository.store, isEmpty);
  });
}
