import 'package:drift/drift.dart';
import 'package:web_server/src/web_db/legacy_track_samples_table.dart';
import 'package:web_server/src/web_db/manual_races_table.dart';
import 'package:web_server/src/web_db/race_polar_buckets_table.dart';
import 'package:web_server/src/web_db/race_polar_histogram_table.dart';
import 'package:web_server/src/web_db/race_polar_stats_table.dart';
import 'package:web_server/src/web_db/race_results_table.dart';
import 'package:web_server/src/web_db/race_stats_table.dart';

part 'web_database.g.dart';

/// A webes adatok saját adatbázisa, a `web.sqlite` (ADR 0047 D5, ADR 0048
/// D9 + Addendum 3 I2, ADR 0050 D3, ADR 0049 D10).
///
/// Független az `AppDatabase`-től: saját fájl, saját migrációs lánc. Így az
/// app sémaváltása nem érinti a kézzel rögzített adatokat, és egy
/// archívum-újraépítés (újraimport) sem veszíti el őket.
@DriftDatabase(
  tables: [
    RaceResults,
    ManualRaces,
    RaceStatsTable,
    LegacyTrackSamples,
    RacePolarStatsTable,
    RacePolarHistogramTable,
    RacePolarBucketsTable,
  ],
)
class WebDatabase extends _$WebDatabase {
  /// Adatbázis a hívó által adott [executor]-ral (szerveren fájl, tesztben
  /// memória vagy ideiglenes fájl).
  WebDatabase(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await transaction(() => _upgradeFromV1(migrator));
      // A v3 csak új táblát hoz, a meglévő adat érintetlen (ADR 0050 D3).
      if (from < 3) await migrator.createTable(legacyTrackSamples);
      // A v4 a polár-cache három tábláját hozza (ADR 0049 D10); a cache
      // üresen indul, a szerver induláskor tölti fel.
      if (from < 4) {
        await migrator.createTable(racePolarStatsTable);
        await migrator.createTable(racePolarHistogramTable);
        await migrator.createTable(racePolarBucketsTable);
      }
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
