import 'package:domain/src/value_objects/telemetry_record.dart';

/// A nyers NMEA-telemetria perzisztálásának kontraktusa (ADR 0008 D4).
///
/// A logger a [TelemetryRecord]-okat fogadja és — implementáció-szinten
/// bufferelve — tárolja. Csak aktív verseny alatt él: az életciklusát a
/// provider-réteg köti az aktív race-hez (Phase 4), és a [dispose]-zal
/// zárja le. A bufferelés stratégiája (batch-méret, flush-időzítés) az
/// implementáció dolga, nem része a kontraktusnak.
abstract class TelemetryLogger {
  /// Naplóz egy [record]-ot. Az implementáció bufferelhet — a tényleges
  /// írás batchelve, késleltetve történhet; a [dispose] garantálja a
  /// függőben lévő rekordok kiírását.
  Future<void> log(TelemetryRecord record);

  /// Lezárja a loggert: a függőben lévő buffer kiírása és az erőforrások
  /// (pl. flush-timer) felszabadítása. A race deaktiválásakor hívandó.
  Future<void> dispose();
}
