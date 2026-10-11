import 'package:domain/src/value_objects/instruments_race_choice.dart';

/// A beállítások és perzisztens app-állapot kontraktusa, forrás-agnosztikusan.
///
/// Clean Architecture: a domain csak az absztrakciót ismeri, a konkrét
/// implementáció (Drift KV-tábla) a data rétegben él (ARCHITECTURE.md 9.2,
/// ADR 0011). Két állapotot tart: az aktív race azonosítóját, hogy az túlélje
/// az app-restartot (maga a Race a RaceRepository-n perzisztált, csak a
/// „melyik aktív" hiányzott), és a Műszerek fül mai kézi versenyválasztását
/// (ADR 0055 D5). A tárolás (KV) implementáció-részlet; a domain csak ezeket
/// a tipizált metódusokat látja, bővítéskor új jön.
abstract interface class SettingsRepository {
  /// Az utoljára aktívként megjelölt race azonosítója, vagy `null`, ha nincs
  /// eltárolva (még nem volt aktív race, vagy törölve lett).
  Future<String?> readActiveRaceId();

  /// Eltárolja az aktív race [id]-jét a restart-túléléshez. `null` esetén
  /// **törli** a tárolt értéket (pl. a verseny befejeztével), így restartkor
  /// nem támaszt fel befejezett race-t.
  Future<void> writeActiveRaceId(String? id);

  /// A Műszerek fül mai kézi versenyválasztása (ADR 0055 D5), vagy `null`,
  /// ha nincs eltárolva, vagy a tárolt érték olvashatatlan. A napot a
  /// kiválasztás (`SelectInstrumentsRace`) veti össze a mai nappal.
  Future<InstrumentsRaceChoice?> readInstrumentsRaceChoice();

  /// Eltárolja a kézi versenyválasztást; `null` esetén **törli** a tárolt
  /// értéket.
  Future<void> writeInstrumentsRaceChoice(InstrumentsRaceChoice? choice);
}
