import 'dart:async';
import 'dart:js_interop';

import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/api/decode_api_response.dart';
import 'package:foretack_web/race_import/import_uploader.dart';
import 'package:foretack_web/race_import/picked_file.dart';
import 'package:foretack_web/race_import/platform/browser_picked_file.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:web/web.dart' as web;

/// Egy feltöltés `XMLHttpRequest`-tel (ADR 0048 Addendum 4 K18–K19).
///
/// A fájlok `FormData`-ban, Blobként mennek: a böngésző a lemezről
/// streameli őket, a Dart-memóriába nem kerülnek. Az `upload` `progress`
/// eseménye adja a haladást. Az XHR-t választottuk a `fetch` helyett,
/// mert a `fetch` feltöltési haladást nem jelez.
final class BrowserImportUpload implements ImportUpload {
  BrowserImportUpload._(this._request);

  /// Elindítja a [database] és a [wal] feltöltését az [endpoint]-ra.
  ///
  /// Csak a böngésző választójának fájljait fogadja; más fájl
  /// programozói hiba (`ArgumentError`).
  factory BrowserImportUpload.start({
    required Uri endpoint,
    required PickedFile database,
    required PickedFile? wal,
    required UploadProgressListener onProgress,
  }) {
    final form = web.FormData()
      ..append(importDatabaseField, _blobOf(database), database.name);
    if (wal != null) form.append(importWalField, _blobOf(wal), wal.name);

    final request = web.XMLHttpRequest();
    final upload = BrowserImportUpload._(request);
    request
      ..upload.addEventListener(
        'progress',
        ((web.ProgressEvent event) {
          if (event.lengthComputable) onProgress(event.loaded, event.total);
        }).toJS,
      )
      ..addEventListener('load', ((web.Event _) => upload._onLoad()).toJS)
      ..addEventListener(
        'error',
        ((web.Event _) => upload._complete(
          const Err(NetworkFailure('Upload connection failed.')),
        )).toJS,
      )
      ..addEventListener(
        'abort',
        ((web.Event _) => upload._complete(
          const Err(NetworkFailure('Upload aborted.')),
        )).toJS,
      )
      ..open('POST', endpoint.toString())
      // A CSRF-fejléc minden módosító kérésen (ADR 0047 D9).
      ..setRequestHeader(clientHeaderName, clientHeaderWebValue)
      ..send(form);
    return upload;
  }

  final web.XMLHttpRequest _request;
  final Completer<Result<ImportReport, ApiFailure>> _completer = Completer();

  @override
  Future<Result<ImportReport, ApiFailure>> get result => _completer.future;

  @override
  void cancel() => _request.abort();

  void _onLoad() => _complete(
    decodeApiResponse(
      _request.status,
      _request.responseText,
      decodeImportReport,
    ),
  );

  void _complete(Result<ImportReport, ApiFailure> outcome) {
    if (!_completer.isCompleted) _completer.complete(outcome);
  }

  static web.File _blobOf(PickedFile picked) => switch (picked) {
    BrowserPickedFile(:final file) => file,
    _ => throw ArgumentError.value(
      picked,
      'picked',
      'Only files from the browser picker can be uploaded.',
    ),
  };
}
