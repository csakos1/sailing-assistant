import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// Teszt-seged: egy tar.gz kicsomagolasa a memoriaba, a ustar fejlec nev-
// es meret-mezoje alapjan. A checksumot is ellenorzi, hogy egy hibas
// fejlec ne maradjon eszrevetlen.

/// A [gzipped] tar.gz bejegyzesei nev szerint, sorrendben.
Map<String, Uint8List> readTarGz(List<int> gzipped) {
  final archive = Uint8List.fromList(gzip.decode(gzipped));
  final entries = <String, Uint8List>{};
  var offset = 0;
  while (offset + 512 <= archive.length) {
    final header = archive.sublist(offset, offset + 512);
    if (header.every((byte) => byte == 0)) break;
    final name = ascii.decode(header.sublist(0, 100)).split('\x00').first;
    final sizeField = ascii.decode(header.sublist(124, 135));
    final size = int.parse(sizeField, radix: 8);
    final storedSum = int.parse(
      ascii.decode(header.sublist(148, 154)),
      radix: 8,
    );
    final sum = [
      ...header.sublist(0, 148),
      ...List<int>.filled(8, 0x20),
      ...header.sublist(156),
    ].fold<int>(0, (total, byte) => total + byte);
    if (sum != storedSum) throw StateError('bad checksum: $name');
    entries[name] = archive.sublist(offset + 512, offset + 512 + size);
    offset += 512 + (size + 511) ~/ 512 * 512;
  }
  return entries;
}
