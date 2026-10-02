import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/race_import/picked_file.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A feltöltés haladása: az eddig elküldött és az összes bájt (a
/// multipart-keret is beleszámít).
typedef UploadProgressListener = void Function(int sentBytes, int totalBytes);

/// Elindítja a [database] és az opcionális [wal] fájl feltöltését a
/// `POST /api/imports` végpontra (ADR 0048 Addendum 4 K19).
///
/// Függvénytípus, nem egytagú absztrakt osztály (`one_member_abstracts`).
typedef ImportUploader =
    ImportUpload Function({
      required PickedFile database,
      required PickedFile? wal,
      required UploadProgressListener onProgress,
    });

/// Egy futó feltöltés.
abstract interface class ImportUpload {
  /// A szerver válasza: az import eredménye vagy a kudarc.
  ///
  /// A [cancel] után hálózati hibával zárul; a hívó ekkor már nem figyel
  /// rá.
  Future<Result<ImportReport, ApiFailure>> get result;

  /// Megszakítja a feltöltést. A szerver a félkész fájlokat törli (ADR
  /// 0047 C2).
  void cancel();
}
