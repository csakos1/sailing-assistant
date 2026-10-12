import 'dart:async';

import 'package:domain/domain.dart';

/// An in-memory race store: `watchRaces` emits the current list, then
/// every change, like the Drift query.
class InMemoryRaceRepository implements RaceRepository {
  final Map<String, Race> races = {};
  final List<Race> saved = [];

  /// When set, every new `watchRaces` subscription fails.
  bool isReadFailing = false;
  final StreamController<List<Race>> _changes =
      StreamController<List<Race>>.broadcast();

  /// Stores [race] without recording a save (test setup).
  void put(Race race) {
    races[race.id] = race;
    _changes.add(races.values.toList());
  }

  @override
  Future<void> save(Race race) async {
    saved.add(race);
    put(race);
  }

  @override
  Future<Race?> getRace(String id) async => races[id];

  @override
  Stream<List<Race>> watchRaces() async* {
    if (isReadFailing) throw StateError('database unavailable');
    yield races.values.toList();
    yield* _changes.stream;
  }

  @override
  Future<void> delete(String id) async {
    races.remove(id);
    _changes.add(races.values.toList());
  }

  Future<void> close() => _changes.close();
}

/// An in-memory settings store.
class InMemorySettingsRepository implements SettingsRepository {
  String? activeRaceId;
  InstrumentsRaceChoice? choice;

  @override
  Future<String?> readActiveRaceId() async => activeRaceId;

  @override
  Future<void> writeActiveRaceId(String? id) async {
    activeRaceId = id;
  }

  @override
  Future<InstrumentsRaceChoice?> readInstrumentsRaceChoice() async => choice;

  @override
  Future<void> writeInstrumentsRaceChoice(
    InstrumentsRaceChoice? choice,
  ) async {
    this.choice = choice;
  }
}
