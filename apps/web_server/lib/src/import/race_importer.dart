import 'dart:async';
import 'dart:io';

import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/import/archive_merger.dart';
import 'package:web_server/src/import/sqlite_headers.dart';
import 'package:web_server/src/import/uploaded_database_probe.dart';
import 'package:web_server/src/track_stats/missing_track_stats_backfill.dart';

/// Egy lehúzott telefon-DB importja az archívumba (ADR 0047 D6 +
/// Addendum 2).
///
/// Lépések:
///  1. a fő fájl megléte és SQLite-fejléce;
///  2. másolás egy saját ideiglenes könyvtárba, a `-wal` fájllal együtt,
///     ha a fejléce érvényes (különben `walIgnored` figyelmeztetés);
///  3. vizsgálat nyers `sqlite3`-mal: checkpoint, épség, `races` tábla,
///     `user_version`;
///  4. séma-őr: újabb séma → elutasítás, régebbi → a **másolat** migrálása;
///  5. beolvasztás az [ArchiveMerger]-rel;
///  6. a hiányzó track-statisztikák pótlása (Addendum 3 C7), még a
///     mutex-en belül, hogy egy közben érkező import ne lásson félkész
///     állapotot;
///  7. az ideiglenes könyvtár törlése, sikertől függetlenül.
///
/// Az eredeti feltöltött fájlokat soha nem módosítja. A hívásokat sorosítja
/// (D6 9. pont): két párhuzamos import nem fésülődhet össze.
class RaceImporter {
  /// Importer az [archive]-ba; az ideiglenes könyvtárak a [tempRoot] alá
  /// kerülnek (alapból a rendszer temp-je). A [backfill] alapból az
  /// [archive]-on dolgozik.
  RaceImporter({
    required AppDatabase archive,
    Directory? tempRoot,
    UploadedDatabaseProbe probe = const UploadedDatabaseProbe(),
    MissingTrackStatsBackfill? backfill,
  }) : _archive = archive,
       _tempRoot = tempRoot ?? Directory.systemTemp,
       _probe = probe,
       _backfill = backfill ?? MissingTrackStatsBackfill(archive: archive);

  final AppDatabase _archive;
  final Directory _tempRoot;
  final UploadedDatabaseProbe _probe;
  final MissingTrackStatsBackfill _backfill;
  final _Mutex _mutex = _Mutex();

  /// A [database] fő fájl és az opcionális [wal] importja.
  Future<Result<ImportReport, ImportRejection>> call({
    required File database,
    File? wal,
  }) => _mutex.run(() => _import(database, wal));

  Future<Result<ImportReport, ImportRejection>> _import(
    File database,
    File? wal,
  ) async {
    if (!database.existsSync()) return const Err(MainFileMissing());
    if (!hasSqliteHeader(await _readPrefix(database, sqliteHeaderLength))) {
      return const Err(NotSqliteDatabase());
    }

    final workDir = await _tempRoot.createTemp('foretack-import-');
    try {
      final staged = File('${workDir.path}/upload.sqlite');
      await database.copy(staged.path);
      final warnings = <ImportWarning>[];
      if (wal != null && wal.existsSync()) {
        final kind = classifyWalHeader(
          await _readPrefix(wal, walHeaderLength),
          fileLength: await wal.length(),
        );
        if (kind == WalHeaderKind.valid) await wal.copy('${staged.path}-wal');
        if (kind == WalHeaderKind.invalid) {
          warnings.add(ImportWarning.walIgnored);
        }
      }

      final int fileVersion;
      switch (_probe(staged.path)) {
        case Ok(:final value):
          fileVersion = value;
        case Err(:final error):
          return Err(error);
      }
      final serverVersion = _archive.schemaVersion;
      if (fileVersion > serverVersion) {
        return Err(
          SchemaTooNew(fileVersion: fileVersion, serverVersion: serverVersion),
        );
      }
      if (fileVersion < serverVersion) await _migrate(staged);

      final report = await ArchiveMerger(
        _archive,
      ).merge(uploadPath: staged.path, warnings: warnings);
      await _backfill();
      return Ok(report);
    } finally {
      await workDir.delete(recursive: true);
    }
  }

  // A régebbi sémájú másolat migrálása az AppDatabase saját migrációival,
  // hogy a beolvasztás oszloplistája a két oldalon azonos legyen.
  Future<void> _migrate(File staged) async {
    final upload = AppDatabase(NativeDatabase(staged));
    try {
      // Az első lekérdezés nyitja meg a kapcsolatot; ez futtatja az
      // onUpgrade-et.
      await upload.customSelect('SELECT 1').get();
    } finally {
      await upload.close();
    }
  }

  static Future<List<int>> _readPrefix(File file, int length) async {
    final handle = await file.open();
    try {
      return await handle.read(length);
    } finally {
      await handle.close();
    }
  }
}

// Egyszerű aszinkron mutex: a feladatok érkezési sorrendben, egymás után
// futnak. A lánc soha nem hibásodik meg, mert a `done` a `finally`-ban
// mindig teljesül.
final class _Mutex {
  Future<void> _last = Future<void>.value();

  Future<T> run<T>(Future<T> Function() task) async {
    final previous = _last;
    final done = Completer<void>();
    _last = done.future;
    try {
      await previous;
      return await task();
    } finally {
      done.complete();
    }
  }
}
