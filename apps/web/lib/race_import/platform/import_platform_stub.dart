import 'package:foretack_web/race_import/import_file_picker.dart';
import 'package:foretack_web/race_import/import_uploader.dart';

/// A VM-en nincs böngésző: a tesztek az `importFilePickerProvider`-t
/// írják felül, ezért ide csak programozói hibával lehet eljutni.
ImportFilePicker createImportFilePicker() =>
    throw UnsupportedError('The file picker runs only in a browser.');

/// A VM-en nincs böngésző: a tesztek az `importUploaderProvider`-t írják
/// felül, ezért ide csak programozói hibával lehet eljutni.
ImportUploader createImportUploader({required Uri baseUri}) =>
    throw UnsupportedError('The uploader runs only in a browser.');
