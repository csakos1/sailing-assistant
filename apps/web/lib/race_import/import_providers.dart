import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_web/race_import/import_file_picker.dart';
import 'package:foretack_web/race_import/import_uploader.dart';
import 'package:foretack_web/race_import/platform/import_platform.dart';

/// A fájlválasztó (ADR 0048 Addendum 4 K19). A böngészőben a rejtett
/// `<input type="file">`; a tesztek egy előre megadott fájllal írják
/// felül.
final Provider<ImportFilePicker> importFilePickerProvider =
    Provider<ImportFilePicker>((ref) => createImportFilePicker());

/// A feltöltő (K19), az oldal saját címéhez képest, mint az API-kliens
/// (K1, K5). A tesztek egy fake-kel írják felül.
final Provider<ImportUploader> importUploaderProvider =
    Provider<ImportUploader>(
      (ref) => createImportUploader(baseUri: Uri.base),
    );
