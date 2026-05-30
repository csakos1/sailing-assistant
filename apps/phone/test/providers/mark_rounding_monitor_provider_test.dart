import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/boat_state_provider.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/mark_rounding_monitor_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';

/// Fix időpont a seedhez és az órához — determinisztikus időbélyegek.
final _fixedNow = DateTime(2025, 6, 1, 12);

/// Hajtható BoatState fake: a build() seedet ad (nincs valós stream-
/// feliratkozás), a moveTo() egy adott pozícióra állítja a hajót — erre tüzel a
/// monitor ref.listen-je.
class _DrivableBoatState extends BoatStateNotifier {
  @override
  BoatState build() => BoatState(lastUpdate: _fixedNow);

  void moveTo(Coordinate? position) {
    state = BoatState(lastUpdate: _fixedNow, position: position);
  }
}

/// Minimál in-memory repo — a perzisztálás itt no-op, csak az activeRace
/// state-átmenetét vizsgáljuk.
class _FakeRaceRepository implements RaceRepository {
  @override
  Future<void> save(Race race) async {}

  @override
  Future<Race?> getRace(String id) async => null;

  @override
  Stream<List<Race>> watchRaces() => const Stream<List<Race>>.empty();

  @override
  Future<void> delete(String id) async {}
}

void main() {
  late ProviderContainer container;
  late _DrivableBoatState boat;

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

  // dLat fokkal észak felé eltolt pozíció. 0.001° szélesség ~111 m: a 0 a
  // bóyánál, a 0.001/0.002 a 50 m-es küszöbön kívül.
  Coordinate offset(Coordinate c, double dLat) =>
      Coordinate(latitude: c.latitude + dLat, longitude: c.longitude);

  Race makeRace() =>
      Race.create(id: 'race-1', name: 'Teszt', marks: const [markA, markB]);

  ActiveRaceNotifier raceNotifier() =>
      container.read(activeRaceProvider.notifier);

  setUp(() {
    boat = _DrivableBoatState();
    container = ProviderContainer(
      overrides: [
        boatStateProvider.overrideWith(() => boat),
        clockProvider.overrideWithValue(() => _fixedNow),
        raceRepositoryProvider.overrideWithValue(_FakeRaceRepository()),
      ],
    );
    addTearDown(container.dispose);
    // A monitor (autoDispose) életben tartása + a boatState ref.listen indítása.
    final sub = container.listen(markRoundingMonitorProvider, (_, _) {});
    addTearDown(sub.close);
  });

  test('közbenső bója megkerülése a következő bójára lép', () async {
    raceNotifier().activeRace = makeRace();
    await raceNotifier().start();

    boat.moveTo(markA.position); // a bóyánál → min = 0
    await pumpEventQueue();
    boat.moveTo(offset(markA.position, 0.001)); // ~111 m → megkerülés
    await pumpEventQueue();

    final state = container.read(activeRaceProvider)!;
    expect(state.status, equals(RaceStatus.active));
    expect(state.activeMarkOrNull, equals(markB));
  });

  test('az utolsó bója megkerülése befejezi a versenyt', () async {
    raceNotifier().activeRace = makeRace();
    await raceNotifier().start();

    boat.moveTo(markA.position);
    await pumpEventQueue();
    boat.moveTo(offset(markA.position, 0.001));
    await pumpEventQueue();

    boat.moveTo(markB.position);
    await pumpEventQueue();
    boat.moveTo(offset(markB.position, 0.001));
    await pumpEventQueue();

    final state = container.read(activeRaceProvider)!;
    expect(state.status, equals(RaceStatus.finished));
    expect(state.activeMarkOrNull, isNull);
  });

  test('notStarted alatt nem lép', () async {
    raceNotifier().activeRace = makeRace(); // notStarted, nincs start()

    boat.moveTo(markA.position);
    await pumpEventQueue();
    boat.moveTo(offset(markA.position, 0.001));
    await pumpEventQueue();

    final state = container.read(activeRaceProvider)!;
    expect(state.status, equals(RaceStatus.notStarted));
    expect(state.activeMarkOrNull, equals(markA));
  });

  test('a küszöbön kívül elhaladva nem számít megkerülésnek', () async {
    raceNotifier().activeRace = makeRace();
    await raceNotifier().start();

    boat.moveTo(offset(markA.position, 0.001)); // ~111 m, sosem 50 m-en belül
    await pumpEventQueue();
    boat.moveTo(offset(markA.position, 0.002)); // ~222 m
    await pumpEventQueue();

    expect(container.read(activeRaceProvider)!.activeMarkOrNull, equals(markA));
  });

  test('null pozíció esetén nem lép és nem dob', () async {
    raceNotifier().activeRace = makeRace();
    await raceNotifier().start();

    boat.moveTo(null);
    await pumpEventQueue();

    expect(container.read(activeRaceProvider)!.activeMarkOrNull, equals(markA));
  });
}
