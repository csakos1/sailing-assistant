import 'package:data/src/engine/race_snapshot.dart';

/// A kiszámolt-érték telemetria (`RaceSnapshot`) perzisztálásának kontraktusa
/// (ADR 0022). A `TelemetryLogger` mintáját követi, de az interfész a `data`
/// rétegben él, mert a payload (`RaceSnapshot`) data-layer DTO — a domain nem
/// hivatkozhat rá (a függési irány befelé mutat).
///
/// A `RaceEngine` ezt az absztrakciót injektálja (DIP), nem az `AppDatabase`-t;
/// a replay/teszt út a no-op alapértelmezéssel DB-írás nélkül fut.
abstract class SnapshotLogger {
  /// Naplóz egy [snapshot]-ot a [raceId] versenyhez. A raceId külön paraméter,
  /// mert a RaceSnapshot cross-isolate DTO nem hordoz persistence-oszlopot.
  Future<void> log(String raceId, RaceSnapshot snapshot);

  /// Lezárja a loggert. Buffer nélkül no-op; a kapcsolat tulajdonosa a
  /// composition root, nem a logger.
  Future<void> dispose();
}
