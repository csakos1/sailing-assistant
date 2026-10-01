import 'package:drift/drift.dart';
import 'package:web_server/src/web_db/manual_races_table.dart';
import 'package:web_server/src/web_db/race_results_table.dart';
import 'package:web_server/src/web_db/race_stats_table.dart';

part 'web_database.g.dart';

/// A webes adatok saját adatbázisa, a `web.sqlite` (ADR 0047 D5, ADR 0048
/// D9 + Addendum 3 I2).
///
/// Független az `AppDatabase`-től: saját fájl, saját migrációs lánc. Így az
/// app sémaváltása nem érinti a kézzel rögzített adatokat, és egy
/// archívum-újraépítés (újraimport) sem veszíti el őket.
@DriftDatabase(tables: [RaceResults, ManualRaces, RaceStatsTable])
class WebDatabase extends _$WebDatabase {
  /// Adatbázis a hívó által adott [executor]-ral (szerveren fájl, tesztben
  /// memória vagy ideiglenes fájl).
  WebDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await transaction(() => _upgradeFromV1(migrator));
    },
  );

  // A v1 egyetlen táblája, a `race_annotations`, a `race_results` elődje:
  // az azonos nevű oszlopok átmásolódnak, a többi (egytestű pár, idők,
  // díj) üresen indul (D9).
  Future<void> _upgradeFromV1(Migrator migrator) async {
    await migrator.createTable(raceResults);
    await customStatement('''
      INSERT INTO race_results (race_id, class_place, class_fleet_size,
        overall_place, overall_fleet_size, summary, updated_at)
      SELECT race_id, class_place, class_fleet_size,
        overall_place, overall_fleet_size, summary, updated_at
      FROM race_annotations
    ''');
    await migrator.deleteTable('race_annotations');
    await migrator.createTable(manualRaces);
    await migrator.createTable(raceStatsTable);
  }
}
