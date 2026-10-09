import 'dart:typed_data';

import 'package:web_server/src/export/tar_entry.dart';
import 'package:web_server/src/export/ustar_header.dart';

/// Az [entries] tar-archívuma streamként (ADR 0050 Addendum 3 G5): minden
/// bejegyzés egy USTAR fejléc, a tartalom 512 bájtra nullákkal kiegészítve,
/// a végén két nulla blokk.
///
/// `async*` generátor: a fogyasztó visszanyomása megállítja, így egy nagy
/// fájl sem kerül a memóriába. Ha egy forrás más bájtszámot ad, mint a
/// bejegyzés mérete, `StateError` szakítja meg: egy közben változó fájl ne
/// adjon csendben hibás archívumot.
Stream<List<int>> tarStream(
  List<TarEntry> entries, {
  required DateTime modified,
}) async* {
  for (final entry in entries) {
    yield ustarHeader(name: entry.name, size: entry.size, modified: modified);
    var written = 0;
    await for (final chunk in entry.open()) {
      written += chunk.length;
      if (written > entry.size) break;
      yield chunk;
    }
    if (written != entry.size) {
      throw StateError(
        '${entry.name}: expected ${entry.size} bytes, read $written',
      );
    }
    final padding = _paddingAfter(entry.size);
    if (padding > 0) yield Uint8List(padding);
  }
  yield Uint8List(2 * tarBlockSize);
}

int _paddingAfter(int size) =>
    (tarBlockSize - size % tarBlockSize) % tarBlockSize;
