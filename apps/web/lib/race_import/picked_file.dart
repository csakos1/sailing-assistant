/// Egy feltöltésre kiválasztott fájl (ADR 0048 Addendum 4 K19).
///
/// Csak azt adja, amit a dialógus megmutat. A tartalmát a felület nem
/// látja: a böngészőben az a `File` objektumban marad, és a feltöltő
/// közvetlenül onnan küldi (K18).
abstract interface class PickedFile {
  /// A fájl neve, ahogy a választóból jött (útvonal nélkül).
  String get name;

  /// A fájl mérete bájtban.
  int get sizeBytes;
}
