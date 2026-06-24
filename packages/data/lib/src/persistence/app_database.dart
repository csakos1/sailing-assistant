import 'package:data/src/persistence/tables/marks_table.dart';
import 'package:data/src/persistence/tables/races_table.dart';
import 'package:data/src/persistence/tables/saved_marks_table.dart';
import 'package:data/src/persistence/tables/settings_table.dart';
import 'package:data/src/persistence/tables/snapshot_logs_table.dart';
import 'package:data/src/persistence/tables/telemetry_records_table.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// A Foretack helyi adatbázisa (Drift / SQLite).
///
/// Egyetlen DB az összes versennyel; FK köti össze a táblákat (a race-lista
/// egy query). Háttér-isolate-on fut (drift_flutter), hogy a hosszú write-ok
/// ne jankolják a UI-t. Teszthez az executor injektálható
/// (`NativeDatabase.memory()`), production-ben a `driftDatabase` adja.
@DriftDatabase(
  tables: [Races, Marks, TelemetryRecords, Settings, SnapshotLogs, SavedMarks],
)
class AppDatabase extends _$AppDatabase {
  /// A UI-izolátum elsődleges kapcsolata: production-ben drift_flutter named DB
  /// háttér-isolate-on, teszthez injektált executor. **Ez migrálja a sémát.**
  AppDatabase([QueryExecutor? executor])
    : _assumeMigrated = false,
      super(executor ?? driftDatabase(name: 'foretack'));

  /// A háttér-engine másodlagos kapcsolata ugyanarra a SQLite-fájlra
  /// (ADR 0017 D6), kizárólag a telemetria-írásokhoz, WAL-módban. **Kész sémát
  /// feltételez** — nem migrál; ha mégis migrációra lenne szükség (a UI-first
  /// invariáns sérült), az `onCreate`/`onUpgrade` dob, a néma konkurens
  /// migráció helyett.
  AppDatabase.secondary([QueryExecutor? executor])
    : _assumeMigrated = true,
      super(executor ?? driftDatabase(name: 'foretack'));

  // true → ez a kapcsolat nem migrálhat (másodlagos engine-kapcsolat).
  final bool _assumeMigrated;

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      if (_assumeMigrated) {
        throw StateError(
          'A másodlagos engine-kapcsolat kész sémát feltételez (ADR 0017 D6): '
          'a UI-izolátumnak előbb kell migrálnia.',
        );
      }
      await m.createAll();
    },
    onUpgrade: (m, from, _) async {
      if (_assumeMigrated) {
        throw StateError(
          'A másodlagos engine-kapcsolat nem migrálhat (ADR 0017 D6).',
        );
      }
      // v1 → v2 (Fázis 5f, ADR 0011): a Settings KV-tábla hozzáadása. CSAK az
      // új táblát hozzuk létre — createAll a meglévő táblákon hibázna.
      if (from < 2) {
        await m.createTable(settings);
      }
      // v2 → v3 (ADR 0022): a SnapshotLogs tábla a kiszámolt-érték
      // telemetriához. CSAK az új tábla.
      if (from < 3) {
        await m.createTable(snapshotLogs);
      }
      // v3 → v4 (ADR 0032): a bója-könyvtár-tábla. CSAK az új
      // tábla; a createTable a @TableIndex unique indexet is létrehozza.
      if (from < 4) {
        await m.createTable(savedMarks);
      }
    },
    beforeOpen: (_) async {
      // SQLite-ban a FK alapból OFF — e nélkül a cascade némán nem fut.
      await customStatement('PRAGMA foreign_keys = ON');
      // WAL: konkurens olvasók + egy rövid batch-író (engine-telemetria, ADR
      // 0017 D6). A journal_mode lekérdezés-alakja eredménysort ad vissza,
      // ezért customSelect (a customStatement eredménysoros PRAGMA-n elhasal).
      await customSelect('PRAGMA journal_mode = WAL').get();
    },
  );
}
