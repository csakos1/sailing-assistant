/// A beállítások és perzisztens app-állapot kontraktusa, forrás-agnosztikusan.
///
/// Clean Architecture: a domain csak az absztrakciót ismeri, a konkrét
/// implementáció (Drift KV-tábla) a data rétegben él (ARCHITECTURE.md 9.2,
/// ADR 0011). v1-ben egyetlen állapotot tart: az aktív race azonosítóját, hogy
/// az túlélje az app-restartot — maga a Race a RaceRepository-n perzisztált,
/// csak a „melyik aktív" hiányzott. A tárolás (KV) implementáció-részlet; a
/// domain csak ezeket a tipizált metódusokat látja, bővítéskor új jön.
abstract interface class SettingsRepository {
  /// Az utoljára aktívként megjelölt race azonosítója, vagy `null`, ha nincs
  /// eltárolva (még nem volt aktív race, vagy törölve lett).
  Future<String?> readActiveRaceId();

  /// Eltárolja az aktív race [id]-jét a restart-túléléshez. `null` esetén
  /// **törli** a tárolt értéket (pl. a verseny befejeztével), így restartkor
  /// nem támaszt fel befejezett race-t.
  Future<void> writeActiveRaceId(String? id);
}
