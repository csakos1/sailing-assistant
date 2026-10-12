import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/pending_race_deletions_provider.dart';
import 'package:phone/providers/race_list_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';
import 'package:phone/providers/timer_factory_provider.dart';

import '../engine/fake_timers.dart';
import 'in_memory_repositories.dart';

void main() {
  late InMemoryRaceRepository repository;
  late FakeTimers timers;
  late ProviderContainer container;

  Race race(String id) => Race.create(id: id, name: id, marks: const []);

  setUp(() {
    repository = InMemoryRaceRepository()
      ..put(race('r1'))
      ..put(race('r2'));
    timers = FakeTimers();
    container = ProviderContainer(
      overrides: [
        raceRepositoryProvider.overrideWithValue(repository),
        timerFactoryProvider.overrideWithValue(timers.create),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(repository.close);
  });

  PendingRaceDeletions deletions() =>
      container.read(pendingRaceDeletionsProvider.notifier);

  // Az utolso kibocsatott lista azonositoi.
  Future<List<String>> listedIds() async {
    await pumpEventQueue();
    final races = container.read(raceListProvider).valueOrNull ?? const [];
    return [for (final race in races) race.id];
  }

  group('PendingRaceDeletions', () {
    test('hides at once and deletes when the window ends', () async {
      // ARRANGE
      container.listen(raceListProvider, (_, _) {});
      expect(await listedIds(), ['r1', 'r2']);

      // ACT
      deletions().schedule('r1');

      // ASSERT - eltunik, de a DB-ben meg megvan.
      expect(container.read(pendingRaceDeletionsProvider), {'r1'});
      expect(await listedIds(), ['r2']);
      expect(repository.races.keys, contains('r1'));
      expect(
        timers.created.single.duration,
        greaterThan(raceDeletionUndoWindow),
      );

      // ACT - lejar az ablak.
      timers.created.single.fire();
      await pumpEventQueue();

      // ASSERT - a torolt azonosito rejtve marad: a lista streamje a
      // torlest kesobb hozza, addig se villanjon vissza a sor.
      expect(repository.races.keys, ['r2']);
      expect(container.read(pendingRaceDeletionsProvider), {'r1'});
      expect(await listedIds(), ['r2']);
      expect(deletions().cancelAll(), isFalse);
    });

    test('keeps a deleted race hidden until the list catches up', () async {
      // ARRANGE - egy lista, ami a torlest (meg) nem hozza meg.
      final silent = _SilentDeleteRepository(repository, [
        race('r1'),
        race('r2'),
      ]);
      final scoped = ProviderContainer(
        overrides: [
          raceRepositoryProvider.overrideWithValue(silent),
          timerFactoryProvider.overrideWithValue(timers.create),
        ],
      );
      addTearDown(scoped.dispose);
      scoped
        ..listen(raceListProvider, (_, _) {})
        ..read(pendingRaceDeletionsProvider.notifier).schedule('r1');

      // ACT
      timers.created.single.fire();
      await pumpEventQueue();

      // ASSERT - a DB-bol torolve, a sor megsem villan vissza.
      expect(repository.races.keys, ['r2']);
      final races = scoped.read(raceListProvider).valueOrNull ?? const [];
      expect([for (final race in races) race.id], ['r2']);
    });

    test('undo brings the race back and never deletes it', () async {
      // ARRANGE
      container.listen(raceListProvider, (_, _) {});
      deletions().schedule('r1');
      expect(await listedIds(), ['r2']);

      // ACT
      final isRestored = deletions().undo('r1');

      // ASSERT
      expect(isRestored, isTrue);
      expect(deletions().undo('r1'), isFalse);
      expect(await listedIds(), ['r1', 'r2']);
      expect(timers.active, isEmpty);
      expect(repository.races.keys, contains('r1'));
    });

    test('cancelAll drops every pending deletion and reports it', () async {
      // ARRANGE
      deletions()
        ..schedule('r1')
        ..schedule('r2');

      // ACT
      final hadPending = deletions().cancelAll();

      // ASSERT
      expect(hadPending, isTrue);
      expect(container.read(pendingRaceDeletionsProvider), isEmpty);
      expect(timers.active, isEmpty);
      expect(deletions().cancelAll(), isFalse);
      expect(repository.races.keys, ['r1', 'r2']);
    });

    test('skips the delete when the race has started meanwhile', () async {
      // ARRANGE - az ablak alatt az engine elinditotta a versenyt.
      deletions().schedule('r1');
      repository.put(race('r1').start(at: DateTime.utc(2026, 7, 30, 9)));

      // ACT
      timers.created.single.fire();
      await pumpEventQueue();

      // ASSERT - a futo versenyt nem toroljuk, es visszakerul a listaba.
      expect(repository.races.keys, contains('r1'));
      expect(container.read(pendingRaceDeletionsProvider), isEmpty);
    });

    test('a failed delete brings the race back', () async {
      // ARRANGE
      final failing = _FailingDeleteRepository();
      final scoped = ProviderContainer(
        overrides: [
          raceRepositoryProvider.overrideWithValue(failing),
          timerFactoryProvider.overrideWithValue(timers.create),
        ],
      );
      addTearDown(scoped.dispose);
      scoped.read(pendingRaceDeletionsProvider.notifier).schedule('r1');

      // ACT
      timers.created.single.fire();
      await pumpEventQueue();

      // ASSERT
      expect(scoped.read(pendingRaceDeletionsProvider), isEmpty);
    });

    test('a second schedule restarts the window', () {
      // ACT
      deletions()
        ..schedule('r1')
        ..schedule('r1');

      // ASSERT
      expect(timers.created, hasLength(2));
      expect(timers.created.first.isActive, isFalse);
      expect(timers.active, hasLength(1));
    });
  });
}

class _FailingDeleteRepository implements RaceRepository {
  @override
  Future<void> delete(String id) async => throw StateError('disk full');

  @override
  Future<Race?> getRace(String id) async => null;

  @override
  Future<void> save(Race race) async {}

  @override
  Stream<List<Race>> watchRaces() => const Stream<List<Race>>.empty();
}

// A torlest vegrehajtja, de a lista streamje nem kovetkezik: a valos Drift
// watch-lekerdezes kesleltetett ujrafutasat modellezi.
class _SilentDeleteRepository implements RaceRepository {
  _SilentDeleteRepository(this._inner, this._snapshot);

  final RaceRepository _inner;
  final List<Race> _snapshot;

  @override
  Future<void> delete(String id) => _inner.delete(id);

  @override
  Future<Race?> getRace(String id) => _inner.getRace(id);

  @override
  Future<void> save(Race race) => _inner.save(race);

  @override
  Stream<List<Race>> watchRaces() => Stream.value(_snapshot);
}
