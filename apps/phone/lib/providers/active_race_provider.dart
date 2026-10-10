import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';

/// A folyamatban lévő race egyetlen írható, in-memory tartója (ADR 0009 D5).
///
/// A state-átmenetek a Race entitás factory-in mennek
/// (start/roundCurrentMark/finish), majd a repón keresztül perzisztálnak — az
/// üzleti logika az entitásban marad, a notifier csak vezényel. Keep-alive: az
/// aktív race a teljes session alatt él, nem köthető egy képernyő
/// életciklusához. A roundCurrentMark-ot a mark-rounding monitor (§8.4) hívja
/// auto-detekcióból. Restart-túlélő perzisztencia Fázis 5f (SettingsRepository)
/// — itt szándékosan in-memory, app-újraindításkor nullázódik.
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

  /// Az aktív bója megkerülése: a következő bójára lép (az utolsón a domain
  /// auto-finish-el), majd perzisztálás. No-op, ha nincs aktív race. A
  /// `status == active` előfeltételt a hívó (mark-rounding monitor, §8.4)
  /// biztosítja; a `Race.roundCurrentMark` assert is védi.
  Future<void> roundCurrentMark() async {
    final race = state;
    if (race == null) return;
    final rounded = race.roundCurrentMark(at: ref.read(clockProvider)());
    await ref.read(raceRepositoryProvider).save(rounded);
    state = rounded;
  }

  /// Az engine által magától lezárt verseny ([raceId]) perzisztálása (az
  /// utolsó bója auto-finish-e, ADR 0054 E3): az engine nem ír vissza a
  /// DB-be (ADR 0016 D6), ezért a UI zárja le az [at] időponttal (a lezárás
  /// pillanatképének ideje, nem a mostani óra: a UI késve is kaphatja). A
  /// kiválasztott versenyt az élő állapotából, mást a DB friss példányából
  /// zárja. No-op, ha a verseny ismeretlen vagy már nem `active`.
  Future<void> finishFromEngine(String raceId, {required DateTime at}) async {
    final repository = ref.read(raceRepositoryProvider);
    final selected = state;
    final isSelected = selected?.id == raceId;
    final race = selected != null && isSelected
        ? selected
        : await repository.getRace(raceId);
    if (race == null || race.status != RaceStatus.active) return;
    final startedAt = race.startedAt;
    // Óraeltérés ellen: a cél nem lehet a rajt előtt.
    final finishAt = startedAt != null && at.isBefore(startedAt)
        ? startedAt
        : at;
    final finished = race.finish(at: finishAt);
    // A kiválasztást a mentés előtt frissítjük, hogy egy közben jövő kézi
    // „Cél" már lezárt versenyt lásson.
    if (isSelected) state = finished;
    await repository.save(finished);
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
