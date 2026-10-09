import 'dart:convert';
import 'dart:typed_data';

/// A tar blokkmérete: a fejléc és a tartalom kiegészítése is erre igazodik.
const int tarBlockSize = 512;

/// A legnagyobb leírható fájlméret: a méret-mező 11 oktális jegy.
const int ustarMaxFileSize = 8 * 1024 * 1024 * 1024 - 1;

/// A név-mező hossza; hosszabb névhez a USTAR `prefix` mezője kellene, de
/// az export nevei rövidek (ADR 0050 Addendum 3 G5).
const int ustarMaxNameLength = 100;

/// Egy sima fájl 512 bájtos USTAR fejléce (ADR 0050 Addendum 3 G5).
///
/// A [name] ASCII és legfeljebb 100 bájt, a [size] 0 és [ustarMaxFileSize]
/// közé esik; különben `ArgumentError`, mert a fejléc hibás archívumot
/// adna. A mód `0644`, a tulajdonos 0/0, a módosítás ideje a [modified]
/// másodpercre lefelé kerekítve.
Uint8List ustarHeader({
  required String name,
  required int size,
  required DateTime modified,
}) {
  final nameBytes = _asciiName(name);
  if (size < 0 || size > ustarMaxFileSize) {
    throw ArgumentError.value(size, 'size', 'outside the USTAR range');
  }
  final seconds = modified.millisecondsSinceEpoch ~/ 1000;
  if (seconds < 0) {
    throw ArgumentError.value(modified, 'modified', 'before 1970');
  }

  final header = Uint8List(tarBlockSize)
    ..setAll(0, nameBytes)
    ..setAll(100, _octalField(_regularFileMode, 8))
    ..setAll(108, _octalField(0, 8))
    ..setAll(116, _octalField(0, 8))
    ..setAll(124, _octalField(size, 12))
    ..setAll(136, _octalField(seconds, 12))
    // A checksum számításakor a saját mezője nyolc szóköz.
    ..setAll(148, List<int>.filled(8, 0x20))
    ..[156] = 0x30
    ..setAll(257, const [0x75, 0x73, 0x74, 0x61, 0x72, 0x00])
    ..setAll(263, const [0x30, 0x30]);

  final checksum = header.fold<int>(0, (sum, byte) => sum + byte);
  // Hat oktális jegy, NUL és szóköz: a GNU és a BSD tar is így írja.
  header.setAll(148, [...ascii.encode(_octal(checksum, 6)), 0x00, 0x20]);
  return header;
}

// rw-r--r--: a 0644 oktális mód.
const int _regularFileMode = 420;

Uint8List _asciiName(String name) {
  if (name.isEmpty || name.length > ustarMaxNameLength) {
    throw ArgumentError.value(name, 'name', 'must be 1-100 bytes');
  }
  if (name.codeUnits.any((unit) => unit < 0x20 || unit > 0x7E)) {
    throw ArgumentError.value(name, 'name', 'must be printable ASCII');
  }
  return ascii.encode(name);
}

// A mező a jegyekből és egy záró NUL-ból áll: egy 8 bájtos mezőben 7 jegy.
List<int> _octalField(int value, int width) => [
  ...ascii.encode(_octal(value, width - 1)),
  0x00,
];

String _octal(int value, int digits) =>
    value.toRadixString(8).padLeft(digits, '0');
