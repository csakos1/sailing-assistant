import 'dart:async';

import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/race_import/import_uploader.dart';
import 'package:foretack_web/race_import/picked_file.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

// Kozos fake-ek a feltoltes tesztjeihez: a bongeszo valasztoja es XHR-je
// helyett.

/// Egy kivalasztott fajl a bongeszo nelkul.
final class FakePickedFile implements PickedFile {
  const FakePickedFile(this.name, this.sizeBytes);

  @override
  final String name;

  @override
  final int sizeBytes;
}

/// Egy feltoltes, amelynek a valaszat a teszt adja meg.
final class FakeImportUpload implements ImportUpload {
  FakeImportUpload({required this.database, required this.wal});

  final PickedFile database;
  final PickedFile? wal;
  final Completer<Result<ImportReport, ApiFailure>> _completer = Completer();
  bool isCancelled = false;

  @override
  Future<Result<ImportReport, ApiFailure>> get result => _completer.future;

  @override
  void cancel() {
    isCancelled = true;
    answer(const Err(NetworkFailure('megszakitva')));
  }

  /// A szerver valasza.
  void answer(Result<ImportReport, ApiFailure> outcome) {
    if (!_completer.isCompleted) _completer.complete(outcome);
  }
}

/// A feltolto fake-je: minden inditast feljegyez, a haladast a teszt
/// kuldi az [onProgress]-en at.
final class FakeImportUploader {
  final List<FakeImportUpload> uploads = [];
  UploadProgressListener? onProgress;

  ImportUpload call({
    required PickedFile database,
    required PickedFile? wal,
    required UploadProgressListener onProgress,
  }) {
    this.onProgress = onProgress;
    final upload = FakeImportUpload(database: database, wal: wal);
    uploads.add(upload);
    return upload;
  }
}
