import 'package:data/src/persistence/tables/marks_table.dart';
import 'package:data/src/persistence/tables/races_table.dart';
import 'package:data/src/persistence/tables/settings_table.dart';
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
@DriftDatabase(tables: [Races, Marks, TelemetryRecords, Settings])
class AppDatabase extends _$AppDatabase {
  /// Production: drift_flutter named DB háttér-isolate-on. Teszt: injektált
  /// executor (pl. in-memory).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'foretack'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, _) async {
      // v1 → v2 (Fázis 5f, ADR 0011): a Settings KV-tábla hozzáadása. CSAK az
      // új táblát hozzuk létre — createAll a meglévő táblákon hibázna.
      if (from < 2) {
        await m.createTable(settings);
      }
    },
    beforeOpen: (_) async {
      // SQLite-ban a FK alapból OFF — e nélkül a cascade némán nem fut.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
