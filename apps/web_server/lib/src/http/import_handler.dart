import 'dart:io';

import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/http/import_upload_receiver.dart';
import 'package:web_server/src/http/json_response.dart';
import 'package:web_server/src/import/race_importer.dart';

/// `POST /api/imports` (ADR 0047 Addendum 1 A5 + Addendum 3 C2).
///
/// A feltöltést egy saját ideiglenes könyvtárba fogadja, átadja a
/// [RaceImporter]-nek, majd a könyvtárat minden esetben törli: sikeres
/// importnál, elutasításnál, hibánál és a kliens megszakításánál is.
class ImportHandler {
  /// Handler a [importer]-rel; a feltöltések a [tempRoot] alá kerülnek.
  ImportHandler({
    required RaceImporter importer,
    required ImportUploadReceiver receiver,
    required Directory tempRoot,
  }) : _importer = importer,
       _receiver = receiver,
       _tempRoot = tempRoot;

  final RaceImporter _importer;
  final ImportUploadReceiver _receiver;
  final Directory _tempRoot;

  /// A feltöltött DB importja; a válasz az `ImportReport`.
  Future<Response> call(Request request) async {
    final uploadDirectory = await _tempRoot.createTemp('foretack-upload-');
    try {
      final ReceivedImportUpload upload;
      switch (await _receiver(request, uploadDirectory)) {
        case Err(:final error):
          return apiErrorResponse(error);
        case Ok(:final value):
          upload = value;
      }

      final database = upload.database;
      if (database == null) {
        return apiErrorResponse(const ImportRejected(MainFileMissing()));
      }
      return switch (await _importer(database: database, wal: upload.wal)) {
        Ok(:final value) => jsonResponse(encodeImportReport(value)),
        Err(:final error) => apiErrorResponse(ImportRejected(error)),
      };
    } finally {
      await uploadDirectory.delete(recursive: true);
    }
  }
}
