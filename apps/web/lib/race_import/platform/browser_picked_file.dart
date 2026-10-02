import 'package:foretack_web/race_import/picked_file.dart';
import 'package:web/web.dart' as web;

/// A böngésző választójából jött fájl (ADR 0048 Addendum 4 K18).
///
/// A tartalom a böngésző `File` objektumában marad; a feltöltő innen
/// küldi, a Dart-memóriába nem olvassa be.
final class BrowserPickedFile implements PickedFile {
  /// A böngésző [file] objektuma.
  const BrowserPickedFile(this.file);

  /// A böngésző fájl-objektuma (Blob).
  final web.File file;

  @override
  String get name => file.name;

  @override
  int get sizeBytes => file.size;
}
