import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/race_list_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';

/// In-memory RaceRepository fake — a watchRaces() a Drift .watch()
/// szemantikáját utánozza: aktuális pillanatkép azonnal, majd minden
/// mutáció után újra. A thin db/repo-providereket nem ezen át teszteljük
/// (azokat a data-réteg fedi), hanem az application-viselkedést.
class _FakeRaceRepository implements RaceRepository {
  final Map<String, Race> _store = {};
  final StreamController<List<Race>> _changes =
      StreamController<List<Race>>.broadcast();

  List<Race> get _snapshot => List.unmodifiable(_store.values);

  @override
  Future<void> save(Race race) async {
    _store[race.id] = race;
    _changes.add(_snapshot);
  }

  @override
  Future<Race?> getRace(String id) async => _store[id];

  @override
  Stream<List<Race>> watchRaces() async* {
    yield _snapshot;
    yield* _changes.stream;
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
    _changes.add(_snapshot);
  }

  Future<void> dispose() => _changes.close();
}

void main() {
  late _FakeRaceRepository repository;
  late ProviderContainer container;

  const markA = Mark(
    sequence: 1,
    name: '1. bója',
    position: Coordinate(latitude: 46.9, longitude: 17.9),
  );
  final raceA = Race.create(
    id: 'race-1',
    name: 'Teszt A',
    marks: const [markA],
  );
  final raceB = Race.create(
    id: 'race-2',
    name: 'Teszt B',
    marks: const [markA],
  );

  setUp(() {
    repository = _FakeRaceRepository();
    container = ProviderContainer(
      overrides: [raceRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(repository.dispose);
    addTearDown(container.dispose);
  });

  group('raceListProvider', () {
    test('a repository pillanatképét tükrözi', () async {
      // ARRANGE
      await repository.save(raceA);

      // ACT
      final races = await container.read(raceListProvider.future);

      // ASSERT
      expect(races, equals([raceA]));
    });

    test('mentés után újra-emittál', () async {
      // ARRANGE — feliratkozunk, és gyűjtjük a sikeres AsyncValue-adatokat.
      final emitted = <List<Race>>[];
      final sub = container.listen<AsyncValue<List<Race>>>(
        raceListProvider,
        (_, next) {
          final value = next.valueOrNull;
          if (value != null) emitted.add(value);
        },
        fireImmediately: true,
      );
      addTearDown(sub.close);
      // A generátor feliratkozása a _changes streamre flush-olódjon, mielőtt
      // mentünk — különben a broadcast-controller eldobná az első eventet.
      await pumpEventQueue();

      // ACT
      await repository.save(raceA);
      await pumpEventQueue();
      await repository.save(raceB);
      await pumpEventQueue();

      // ASSERT — az utolsó kibocsátás mindkét race-t tartalmazza.
      expect(emitted.last, containsAll(<Race>[raceA, raceB]));
    });
  });

  group('clockProvider', () {
    test('override-ja érvényesül', () {
      final fixedNow = DateTime(2025, 6, 1, 10);
      final overridden = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(() => fixedNow)],
      );
      addTearDown(overridden.dispose);

      expect(overridden.read(clockProvider)(), equals(fixedNow));
    });
  });
}
