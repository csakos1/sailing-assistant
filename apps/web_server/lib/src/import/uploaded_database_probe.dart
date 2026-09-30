import 'package:meta/meta.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:sqlite3/sqlite3.dart';

/// A feltöltött DB-másolat vizsgálata, a migráció **előtt** (ADR 0047
/// Addendum 2 B2).
///
/// Nyers `sqlite3`-mal nyit, nem az `AppDatabase`-szel: egy újabb sémájú
/// fájlon a Drift lefuttatná az `onUpgrade`-et, majd csendben visszaírná a
/// `user_version`-t, és a séma-őr soha nem látná az újabb verziót.
///
/// Sorrend: WAL-checkpoint (a feltöltött WAL bekerül a fő fájlba),
/// `quick_check`, a `races` tábla megléte, végül a `user_version`. A
/// másolatot módosítja (checkpoint), az eredetit soha nem látja.
@immutable
class UploadedDatabaseProbe {
  /// Állapotmentes vizsgáló.
  const UploadedDatabaseProbe();

  /// A [path] másolat sémaverziója, vagy az elutasítás oka.
  Result<int, ImportRejection> call(String path) {
    final Database database;
    try {
      database = sqlite3.open(path);
    } on SqliteException {
      return const Err(NotSqliteDatabase());
    }
    try {
      return _inspect(database);
    } on SqliteException {
      // A fejléc stimmelt, de a fájl olvasás közben hibát ad: sérült.
      return const Err(NotSqliteDatabase());
    } finally {
      database.close();
    }
  }

  Result<int, ImportRejection> _inspect(Database database) {
    database.execute('PRAGMA wal_checkpoint(TRUNCATE)');

    final check = database.select('PRAGMA quick_check');
    // A columnAt dynamic-ot ad; Object?-ként hasonlítjuk (avoid_dynamic_calls).
    final Object? status = check.isEmpty ? null : check.first.columnAt(0);
    if (check.length != 1 || status != 'ok') {
      return const Err(NotSqliteDatabase());
    }

    final racesTable = database.select(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'races'",
    );
    if (racesTable.isEmpty) return const Err(NotForetackDatabase());

    // Egy valódi Foretack-DB legalább v1; a 0 egy kézzel létrehozott,
    // soha nem migrált fájl, amelyen a Drift az onCreate-et futtatná.
    final version = database.userVersion;
    if (version < 1) return const Err(NotForetackDatabase());
    return Ok(version);
  }
}
