import 'dart:io';

/// A tar egy bejegyzése: név, előre ismert méret és a tartalom forrása
/// (ADR 0050 Addendum 3 G5).
///
/// A forrás függvény, hogy a tartalom csak a sorára kerülve nyíljon meg,
/// és a fájlok egyszerre ne legyenek nyitva.
final class TarEntry {
  /// Bejegyzés a [name] néven, [size] bájttal, az [open] forrásból.
  const TarEntry({required this.name, required this.size, required this.open});

  /// Bejegyzés a [bytes] tartalommal.
  TarEntry.bytes({required String name, required List<int> bytes})
    : this(name: name, size: bytes.length, open: () => Stream.value(bytes));

  /// Bejegyzés a [file] tartalmával; a méret most rögzül, a tar-stream a
  /// tényleges bájtszámot ehhez veti.
  static Future<TarEntry> file({
    required String name,
    required File file,
  }) async =>
      TarEntry(name: name, size: await file.length(), open: file.openRead);

  /// Az archívumbeli útvonal.
  final String name;

  /// A tartalom hossza bájtban.
  final int size;

  /// A tartalom streamje; bejegyzésenként egyszer hívódik.
  final Stream<List<int>> Function() open;
}
