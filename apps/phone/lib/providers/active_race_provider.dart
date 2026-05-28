import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';

/// A folyamatban lévő race egyetlen írható, in-memory tartója (ADR 0009 D5).
///
/// A state-átmenetek a Race entitás factory-in mennek (start/finish), majd a
/// repón keresztül perzisztálnak — az üzleti logika az entitásban marad, a
/// notifier csak vezényel. Keep-alive: az aktív race a teljes session alatt
/// él, nem köthető egy képernyő életciklusához. A roundCurrentMark bekötése
/// Fázis 5 (auto-detekció). Restart-túlélő perzisztencia szintén Fázis 5
/// (SettingsRepository) — itt szándékosan in-memory, app-újraindításkor
/// nullázódik.
final activeRaceProvider = NotifierProvider<ActiveRaceNotifier, Race?>(
  ActiveRaceNotifier.new,
);

/// Az [activeRaceProvider] notifierje: kiválasztás (property) + state-átmenetek.
class ActiveRaceNotifier extends Notifier<Race?> {
  @override
  Race? build() => null;

  /// Az éppen aktív race, vagy `null`. A UI a providert olvassa; ez a getter a
  /// setter párja (avoid_setters_without_getters), notifier-szintű
  /// szimmetrikus hozzáférés a `state`-hez.
  Race? get activeRace => state;

  /// Az aktív race kiválasztása, illetve `null`-lal a deaktiválása. Setter-
  /// forma, mert egyetlen property-t állít (use_setters_to_change_properties);
  /// a telemetria-logger lifecycle erre a state-változásra tear-down-ol.
  set activeRace(Race? race) => state = race;

  /// notStarted → active, majd perzisztálás. No-op, ha nincs aktív race.
  Future<void> start() async {
    final race = state;
    if (race == null) return;
    final started = race.start(at: ref.read(clockProvider)());
    await ref.read(raceRepositoryProvider).save(started);
    state = started;
  }

  /// active → finished (DNF/abort), majd perzisztálás. No-op, ha nincs aktív
  /// race.
  Future<void> finish() async {
    final race = state;
    if (race == null) return;
    final finished = race.finish(at: ref.read(clockProvider)());
    await ref.read(raceRepositoryProvider).save(finished);
    state = finished;
  }
}
