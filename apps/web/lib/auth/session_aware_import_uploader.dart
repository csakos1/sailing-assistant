import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/race_import/import_uploader.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A feltöltő burka, amely a lejárt munkamenetet jelzi (ADR 0051
/// Addendum 7 P3).
///
/// A feltöltés a böngésző `XMLHttpRequest`-jén megy, nem a
/// `SessionAwareClient`-en; ezért a `401`-jét itt kell elkapni. Az
/// eredményt változatlanul továbbadja.
ImportUploader sessionAwareImportUploader(
  ImportUploader upload, {
  required void Function() onUnauthorized,
}) =>
    ({required database, required wal, required onProgress}) =>
        _SessionAwareImportUpload(
          upload(database: database, wal: wal, onProgress: onProgress),
          onUnauthorized,
        );

final class _SessionAwareImportUpload implements ImportUpload {
  // Az eredményt azonnal figyeli, hogy a jelzés akkor is lefusson, ha a
  // hívó már nem várja a választ.
  _SessionAwareImportUpload(ImportUpload inner, void Function() onUnauthorized)
    : _inner = inner,
      result = inner.result.then((outcome) {
        if (outcome case Err(error: ServerFailure(error: NotAuthenticated()))) {
          onUnauthorized();
        }
        return outcome;
      });

  final ImportUpload _inner;

  @override
  final Future<Result<ImportReport, ApiFailure>> result;

  @override
  void cancel() => _inner.cancel();
}
