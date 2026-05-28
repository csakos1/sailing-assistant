import 'package:domain/src/entities/race.dart';

/// A versenyek perzisztencia-kontraktusa, forrás-agnosztikusan.
///
/// Clean Architecture: a domain csak az absztrakciót ismeri, a konkrét
/// implementáció (Drift/SQLite) a data rétegben él, a függőség befelé
/// mutat. A repository **kizárólag perzisztencia** — az állapotátmeneteket
/// a [Race] entitás factory-i (`start`, `roundCurrentMark`, `finish`)
/// végzik; a hívó a frissített [Race]-t [save]-eli. Így az üzleti logika
/// az entitásban marad, a repository buta read/write.
abstract class RaceRepository {
  /// Elment egy [Race]-t a bóyáival együtt. Upsert: ha az [Race.id] már
  /// létezik, felülírja, különben beszúr. A race és a bóyák egy
  /// tranzakcióban mennek, hogy ne maradjon részlegesen mentett állapot.
  Future<void> save(Race race);

  /// Betölt egy [Race]-t [id] alapján, vagy `null`-t ad, ha nincs ilyen.
  Future<Race?> getRace(String id);

  /// Az összes verseny reaktív streamje a lista-képernyőnek. A Drift
  /// `.watch()`-ára épül: mentés/törlés után automatikusan újra-emittál.
  Stream<List<Race>> watchRaces();

  /// Töröl egy [Race]-t [id] alapján. A bóyák és a telemetria FK-cascade-del
  /// törlődnek (persistence-séma, ARCHITECTURE.md 9.2).
  Future<void> delete(String id);
}
