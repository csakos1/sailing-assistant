import 'package:flutter/foundation.dart';
import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/race_import/picked_file.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A feltöltés-dialógus állapota (ADR 0047 E8, ADR 0048 Addendum 4 K20).
///
/// Sealed: a dialógus kimerítő `switch`-csel rajzolja. Az átmenetek pure
/// metódusok; a választó, a feltöltő és a navigáció a widget dolga.
@immutable
sealed class ImportDialogState {
  const ImportDialogState();
}

/// Fájlválasztás (13f, 13g); egy korábbi kísérlet kudarcával is.
final class ChoosingFiles extends ImportDialogState {
  /// Választás a [database] és a [wal] fájllal; a [failure] az előző
  /// feltöltés kudarca, ha volt.
  const ChoosingFiles({this.database, this.wal, this.failure});

  /// A fő adatbázis-fájl (kötelező a feltöltéshez).
  final PickedFile? database;

  /// A `-wal` fájl (opcionális).
  final PickedFile? wal;

  /// Az előző feltöltés kudarca; a fájlok közben megmaradtak (K20).
  final ApiFailure? failure;

  /// Indítható-e a feltöltés: csak fő fájllal (13g).
  bool get canUpload => database != null;

  /// A fő fájl cseréje; a régi kudarc-mondat eltűnik, mert az a régi
  /// fájlra szólt.
  ChoosingFiles withDatabase(PickedFile file) =>
      ChoosingFiles(database: file, wal: wal);

  /// A `-wal` fájl cseréje; a régi kudarc-mondat eltűnik.
  ChoosingFiles withWal(PickedFile file) =>
      ChoosingFiles(database: database, wal: file);

  /// A feltöltés indítása; fő fájl nélkül `null`.
  Uploading? startUpload() {
    final database = this.database;
    if (database == null) return null;
    return Uploading(
      database: database,
      wal: wal,
      sentBytes: 0,
      // Becslés az első haladás-eseményig; a multipart-keret még nincs
      // benne, a feltöltő valódi összege váltja.
      totalBytes: database.sizeBytes + (wal?.sizeBytes ?? 0),
    );
  }
}

/// A feltöltés fut (13h).
final class Uploading extends ImportDialogState {
  /// Feltöltés a [database] és a [wal] fájllal; [sentBytes] bájt ment el
  /// a [totalBytes]-ból.
  const Uploading({
    required this.database,
    required this.wal,
    required this.sentBytes,
    required this.totalBytes,
  });

  /// A fő adatbázis-fájl.
  final PickedFile database;

  /// A `-wal` fájl, ha van.
  final PickedFile? wal;

  /// Az eddig elküldött bájtok.
  final int sentBytes;

  /// Az összes elküldendő bájt.
  final int totalBytes;

  /// A haladás 0 és 1 között (a 2 px-es sáv).
  double get fraction =>
      totalBytes <= 0 ? 1 : (sentBytes / totalBytes).clamp(0, 1).toDouble();

  /// Kiment-e minden bájt: a szerver már dolgozik (K20, FELDOLGOZÁS).
  bool get isProcessing => sentBytes >= totalBytes;

  /// A fő fájlból eddig elküldött rész. A multipart-törzsben a fő fájl áll
  /// elöl, ezért az első bájtok az övéi.
  int get databaseSentBytes => sentBytes.clamp(0, database.sizeBytes);

  /// Új haladás-esemény. A számok nem csökkennek és nem lépik túl a
  /// teljes méretet, így egy zajos esemény sem ugrik vissza.
  Uploading withProgress(int sentBytes, int totalBytes) {
    final total = totalBytes > 0 ? totalBytes : this.totalBytes;
    // Az alsó korlát sem lehet a felső fölött, különben a `clamp` dob.
    final floor = this.sentBytes < total ? this.sentBytes : total;
    final sent = sentBytes.clamp(floor, total);
    return Uploading(
      database: database,
      wal: wal,
      sentBytes: sent,
      totalBytes: total,
    );
  }

  /// A szerver válasza után: eredmény, séma-hiba, vagy vissza a
  /// választáshoz a kudarccal (K20).
  ImportDialogState finish(Result<ImportReport, ApiFailure> outcome) =>
      switch (outcome) {
        Ok(:final value) => ImportFinished(value),
        Err(
          error: ServerFailure(
            error: ImportRejected(
              rejection: SchemaTooNew(:final fileVersion, :final serverVersion),
            ),
          ),
        ) =>
          SchemaRejected(
            fileName: database.name,
            fileVersion: fileVersion,
            serverVersion: serverVersion,
          ),
        Err(:final error) => ChoosingFiles(
          database: database,
          wal: wal,
          failure: error,
        ),
      };
}

/// A feltöltés sikerült (13i).
final class ImportFinished extends ImportDialogState {
  /// Kész import a [report] eredménnyel.
  const ImportFinished(this.report);

  /// A szerver jelentése: új, frissült és kimaradt versenyek.
  final ImportReport report;
}

/// A fájl sémája újabb a szerverénél (13j).
final class SchemaRejected extends ImportDialogState {
  /// Elutasítás: a [fileName] fájl [fileVersion] sémája újabb a szerver
  /// [serverVersion]-jénél.
  const SchemaRejected({
    required this.fileName,
    required this.fileVersion,
    required this.serverVersion,
  });

  /// A feltöltött fő fájl neve.
  final String fileName;

  /// A fájl sémaverziója.
  final int fileVersion;

  /// A szerver sémaverziója.
  final int serverVersion;
}
