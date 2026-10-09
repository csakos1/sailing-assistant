import 'package:foretack_web/race_import/import_file_picker.dart';
import 'package:foretack_web/race_import/import_uploader.dart';
import 'package:foretack_web/race_import/platform/browser_file_picker.dart';
import 'package:foretack_web/race_import/platform/browser_import_upload.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A böngésző fájlválasztója (K19).
ImportFilePicker createImportFilePicker() => pickBrowserFile;

/// A böngésző XHR-feltöltője a [baseUri]-hoz képest (K19).
ImportUploader createImportUploader({required Uri baseUri}) =>
    ({required database, required wal, required onProgress}) =>
        BrowserImportUpload.start(
          endpoint: baseUri.resolve(importsPath),
          database: database,
          wal: wal,
          onProgress: onProgress,
        );
