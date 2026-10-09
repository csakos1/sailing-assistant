import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Egy vizsgált, az archívum sémájára migrált feltöltés beolvasztása az
/// archívumba (ADR 0047 D6 5–8. pont + Addendum 2 B1).
///
/// A feltöltést `ATTACH`-csal csatolja, és egyetlen tranzakcióban,
/// halmaz-alapon másol:
///  1. a feltöltés befejezett versenyeit törli az archívumból (a CASCADE a
///     gyerek-sorokat is viszi — egy frissített verseny így nem duplázódik);
///  2. `INSERT … SELECT` a `races`, `marks`, `telemetry_records`,
///     `snapshot_logs` és `race_track_stats` táblákra, explicit
///     oszloplistával, az autoincrement oszlop nélkül.
///
/// A `settings` és a `saved_marks` kimarad: phone-oldali konfiguráció. A
/// webes adatokhoz (eredmények, kézi versenyek) nem nyúl — azok külön
/// DB-ben élnek (D5).
class ArchiveMerger {
  /// Beolvasztó az `archive` adatbázisba.
  ArchiveMerger(this._archive);

  final AppDatabase _archive;

  // A csatolt feltöltés sémaneve az ATTACH után.
  static const String _upload = 'upload';

  /// A [uploadPath] fájl beolvasztása; a [warnings] változatlanul kerül a
  /// riportba.
  Future<ImportReport> merge({
    required String uploadPath,
    required List<ImportWarning> warnings,
  }) async {
    await _archive.customStatement('ATTACH DATABASE ? AS $_upload', [
      uploadPath,
    ]);
    try {
      return await _mergeAttached(warnings);
    } finally {
      await _archive.customStatement('DETACH DATABASE $_upload');
    }
  }

  Future<ImportReport> _mergeAttached(List<ImportWarning> warnings) async {
    final races = _archive.races;
    final idColumn = races.id.name;
    final statusColumn = races.statusIndex.name;
    final finished = RaceStatus.finished.index;
    final finishedUploadIds =
        'SELECT "$idColumn" FROM $_upload."${races.actualTableName}" '
        'WHERE "$statusColumn" = $finished';

    final existingIds = {
      for (final row
          in await _archive
              .customSelect(
                'SELECT "$idColumn" AS id FROM main."${races.actualTableName}"',
              )
              .get())
        row.read<String>('id'),
    };
    final uploaded = await _archive
        .customSelect(
          'SELECT "$idColumn" AS id, "${races.name.name}" AS name, '
          '"$statusColumn" AS status FROM $_upload."${races.actualTableName}"',
        )
        .get();

    final finishedIds = <String>{};
    final skipped = <SkippedRace>[];
    for (final row in uploaded) {
      final id = row.read<String>('id');
      final statusIndex = row.read<int>('status');
      if (statusIndex == finished) {
        finishedIds.add(id);
      } else {
        skipped.add(
          SkippedRace(
            id: id,
            name: row.read<String>('name'),
            // Ismeretlen index egy jövőbeli státusz lenne; a kihagyás oka
            // akkor is az, hogy nem befejezett.
            status: statusIndex >= 0 && statusIndex < RaceStatus.values.length
                ? RaceStatus.values[statusIndex]
                : RaceStatus.notStarted,
          ),
        );
      }
    }

    await _archive.transaction(() async {
      await _archive.customStatement(
        'DELETE FROM main."${races.actualTableName}" '
        'WHERE "$idColumn" IN ($finishedUploadIds)',
      );
      await _copy(races, where: '"$statusColumn" = $finished');
      final children = <(TableInfo<Table, Object?>, GeneratedColumn<String>)>[
        (_archive.marks, _archive.marks.raceId),
        (_archive.telemetryRecords, _archive.telemetryRecords.raceId),
        (_archive.snapshotLogs, _archive.snapshotLogs.raceId),
        (_archive.raceTrackStats, _archive.raceTrackStats.raceId),
      ];
      for (final (table, raceId) in children) {
        await _copy(table, where: '"${raceId.name}" IN ($finishedUploadIds)');
      }
    });

    return _report(
      finishedIds: finishedIds,
      existingIds: existingIds,
      skipped: skipped,
      warnings: warnings,
    );
  }

  // Halmaz-alapú másolás a feltöltésből az archívumba. Az autoincrement
  // oszlop kimarad (Addendum 2 B1): az archívum ad új azonosítót, a régi
  // sorrendet az ORDER BY őrzi.
  Future<void> _copy(TableInfo<Table, Object?> table, {required String where}) {
    final copied = [
      for (final column in table.$columns)
        if (!column.hasAutoIncrement) '"${column.name}"',
    ].join(', ');
    final autoIncrement = [
      for (final column in table.$columns)
        if (column.hasAutoIncrement) '"${column.name}"',
    ];
    final orderBy = autoIncrement.isEmpty
        ? ''
        : ' ORDER BY ${autoIncrement.join(', ')}';
    final name = table.actualTableName;
    return _archive.customStatement(
      'INSERT INTO main."$name" ($copied) '
      'SELECT $copied FROM $_upload."$name" WHERE $where$orderBy',
    );
  }

  Future<ImportReport> _report({
    required Set<String> finishedIds,
    required Set<String> existingIds,
    required List<SkippedRace> skipped,
    required List<ImportWarning> warnings,
  }) async {
    final rows = await (_archive.select(
      _archive.races,
    )..where((race) => race.id.isIn(finishedIds))).get();
    rows.sort(
      (a, b) =>
          (a.finishedAt ?? a.createdAt).compareTo(b.finishedAt ?? b.createdAt),
    );

    final added = <ImportedRace>[];
    final updated = <ImportedRace>[];
    for (final row in rows) {
      // A befejezett verseny finishedAt-je a Race-invariáns szerint nem
      // null; a createdAt csak a típus kedvéért szerepel tartalékként.
      final imported = ImportedRace(
        id: row.id,
        name: row.name,
        finishedAt: (row.finishedAt ?? row.createdAt).toUtc(),
      );
      (existingIds.contains(row.id) ? updated : added).add(imported);
    }
    return ImportReport(
      added: added,
      updated: updated,
      skipped: skipped,
      warnings: warnings,
    );
  }
}
