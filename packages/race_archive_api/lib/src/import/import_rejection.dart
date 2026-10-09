import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/json/json_reader.dart';

/// Miért utasította el a szerver az importot (ADR 0047 D6 + Addendum 1
/// A7). Sealed: a feltöltés-dialógus kimerítő `switch`-csel fordítja
/// üzenetté.
sealed class ImportRejection extends Equatable {
  const ImportRejection();

  @override
  List<Object?> get props => const [];
}

/// A kérésből hiányzik a fő adatbázis-fájl.
final class MainFileMissing extends ImportRejection {
  /// Hiányzó fő fájl.
  const MainFileMissing();
}

/// A fő fájl nem SQLite-adatbázis (rossz fejléc vagy sérült fájl).
final class NotSqliteDatabase extends ImportRejection {
  /// Nem SQLite-fájl.
  const NotSqliteDatabase();
}

/// SQLite-fájl, de nem a Foretack adatbázisa (nincs `races` tábla).
final class NotForetackDatabase extends ImportRejection {
  /// Idegen adatbázis.
  const NotForetackDatabase();
}

/// A fájl sémája újabb, mint amit a szerver ismer: a szervert frissíteni és
/// újra deployolni kell (D6 3. pont).
final class SchemaTooNew extends ImportRejection {
  /// A fájl [fileVersion] sémája újabb a szerver [serverVersion]-jénél.
  const SchemaTooNew({required this.fileVersion, required this.serverVersion});

  /// A feltöltött fájl `user_version`-je.
  final int fileVersion;

  /// A szerver `AppDatabase.schemaVersion`-je.
  final int serverVersion;

  @override
  List<Object?> get props => [fileVersion, serverVersion];
}

/// [ImportRejection] → JSON.
Map<String, Object?> encodeImportRejection(ImportRejection rejection) =>
    switch (rejection) {
      MainFileMissing() => <String, Object?>{'code': _mainFileMissing},
      NotSqliteDatabase() => <String, Object?>{'code': _notSqliteDatabase},
      NotForetackDatabase() => <String, Object?>{'code': _notForetackDatabase},
      SchemaTooNew(:final fileVersion, :final serverVersion) =>
        <String, Object?>{
          'code': _schemaTooNew,
          'fileVersion': fileVersion,
          'serverVersion': serverVersion,
        },
    };

/// Belső olvasó a hiba-boríték kodekjének.
ImportRejection readImportRejection(JsonReader reader) {
  return switch (reader.string('code')) {
    _mainFileMissing => const MainFileMissing(),
    _notSqliteDatabase => const NotSqliteDatabase(),
    _notForetackDatabase => const NotForetackDatabase(),
    _schemaTooNew => SchemaTooNew(
      fileVersion: reader.integer('fileVersion'),
      serverVersion: reader.integer('serverVersion'),
    ),
    _ => JsonReader.failAt(reader.childPath('code'), 'import rejection code'),
  };
}

const String _mainFileMissing = 'mainFileMissing';
const String _notSqliteDatabase = 'notSqliteDatabase';
const String _notForetackDatabase = 'notForetackDatabase';
const String _schemaTooNew = 'schemaTooNew';
