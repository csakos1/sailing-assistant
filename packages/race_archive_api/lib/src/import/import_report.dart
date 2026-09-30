import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/json/decode_error.dart';
import 'package:race_archive_api/src/json/json_reader.dart';
import 'package:shared/shared.dart';

/// Egy import által felvett vagy frissített verseny.
final class ImportedRace extends Equatable {
  /// A [id] verseny, [name] névvel, [finishedAt]-kor befejezve.
  const ImportedRace({
    required this.id,
    required this.name,
    required this.finishedAt,
  });

  /// A verseny UUID-je.
  final String id;

  /// A verseny neve.
  final String name;

  /// A befejezés ideje (UTC).
  final DateTime finishedAt;

  @override
  List<Object?> get props => [id, name, finishedAt];
}

/// Egy import által kihagyott verseny: nem befejezett (ADR 0047 D6).
final class SkippedRace extends Equatable {
  /// A [id] verseny, [name] névvel, [status] állapotban.
  const SkippedRace({
    required this.id,
    required this.name,
    required this.status,
  });

  /// A verseny UUID-je.
  final String id;

  /// A verseny neve.
  final String name;

  /// Az állapota a feltöltött DB-ben (nem `finished`).
  final RaceStatus status;

  @override
  List<Object?> get props => [id, name, status];
}

/// Nem végzetes import-figyelmeztetés (ADR 0047 Addendum 1 A7).
enum ImportWarning {
  /// A feltöltött `-wal` fájl fejléce nem érvényes WAL-fejléc (pl. a
  /// lehúzáskor egy `cat` hibaüzenete került bele), ezért figyelmen kívül
  /// hagytuk, és csak a fő fájlt importáltuk.
  walIgnored,
}

/// A `POST /api/imports` válasza (ADR 0047 D6 8. pont).
final class ImportReport extends Equatable {
  /// Az import eredménye.
  const ImportReport({
    required this.added,
    required this.updated,
    required this.skipped,
    required this.warnings,
  });

  /// Az archívumban eddig nem szereplő, most felvett versenyek.
  final List<ImportedRace> added;

  /// A már archivált, most felülírt versenyek (az annotációjuk megmaradt).
  final List<ImportedRace> updated;

  /// A nem befejezett, ezért kihagyott versenyek.
  final List<SkippedRace> skipped;

  /// A nem végzetes figyelmeztetések.
  final List<ImportWarning> warnings;

  @override
  List<Object?> get props => [added, updated, skipped, warnings];
}

/// [ImportReport] → JSON.
Map<String, Object?> encodeImportReport(ImportReport report) =>
    <String, Object?>{
      'added': [for (final race in report.added) _encodeImportedRace(race)],
      'updated': [for (final race in report.updated) _encodeImportedRace(race)],
      'skipped': [for (final race in report.skipped) _encodeSkippedRace(race)],
      'warnings': [for (final warning in report.warnings) warning.name],
    };

/// JSON → [ImportReport].
Result<ImportReport, DecodeError> decodeImportReport(Object? json) =>
    runDecode(() {
      final reader = JsonReader.root(json);
      return ImportReport(
        added: reader.list('added', _readImportedRace),
        updated: reader.list('updated', _readImportedRace),
        skipped: reader.list('skipped', _readSkippedRace),
        warnings: reader.list('warnings', _readWarning),
      );
    });

Map<String, Object?> _encodeImportedRace(ImportedRace race) =>
    <String, Object?>{
      'id': race.id,
      'name': race.name,
      'finishedAt': race.finishedAt.millisecondsSinceEpoch,
    };

ImportedRace _readImportedRace(Object? item, String path) {
  final reader = JsonReader.at(item, path);
  return ImportedRace(
    id: reader.nonEmptyString('id'),
    name: reader.string('name'),
    finishedAt: reader.utcMillis('finishedAt'),
  );
}

Map<String, Object?> _encodeSkippedRace(SkippedRace race) => <String, Object?>{
  'id': race.id,
  'name': race.name,
  'status': race.status.name,
};

SkippedRace _readSkippedRace(Object? item, String path) {
  final reader = JsonReader.at(item, path);
  return SkippedRace(
    id: reader.nonEmptyString('id'),
    name: reader.string('name'),
    status: reader.enumByName('status', RaceStatus.values),
  );
}

ImportWarning _readWarning(Object? item, String path) {
  for (final warning in ImportWarning.values) {
    if (warning.name == item) return warning;
  }
  JsonReader.failAt(path, 'import warning');
}
