/// Egy fájlméret olvasható alakban: `312 KB`, `4,8 MB`, `1,7 GB` (13f).
///
/// Kettes alapú egységek (1 KB = 1024 B), a fájlkezelők többségének
/// szokása szerint. KB alatt bájt, KB-ban tizedes nélkül, fölötte egy
/// tizedessel, magyar tizedesvesszővel.
String formatFileSize(int bytes) {
  final unit = _unitFor(bytes);
  return '${_amountIn(bytes, unit)} ${unit.label}';
}

/// A feltöltés haladása a teljes méret egységében: `3,2 / 4,8 MB` (13h).
///
/// Közös egység, hogy a két szám egymás mellett összevethető legyen.
String formatSentOfTotal(int sentBytes, int totalBytes) {
  final unit = _unitFor(totalBytes);
  return '${_amountIn(sentBytes, unit)} / '
      '${_amountIn(totalBytes, unit)} ${unit.label}';
}

/// A fájlméret egységei.
enum _SizeUnit {
  bytes('B', 1, 0),
  kilobytes('KB', 1024, 0),
  megabytes('MB', 1024 * 1024, 1),
  gigabytes('GB', 1024 * 1024 * 1024, 1)
  ;

  const _SizeUnit(this.label, this.bytesPerUnit, this.decimals);

  final String label;
  final int bytesPerUnit;
  final int decimals;
}

_SizeUnit _unitFor(int bytes) {
  for (final unit in _SizeUnit.values.reversed) {
    if (bytes >= unit.bytesPerUnit) return unit;
  }
  return _SizeUnit.bytes;
}

String _amountIn(int bytes, _SizeUnit unit) {
  final amount = bytes / unit.bytesPerUnit;
  return amount.toStringAsFixed(unit.decimals).replaceAll('.', ',');
}
