/// A [bytes] FNV-1a 64 bites hash-e 16 hexa jeggyel (ADR 0049 Addendum 4
/// U2).
///
/// Változás-észlelésre való, nem biztonsági célra. A natív Dart `int`
/// 64 bites, a szorzás modulo 2^64 csordul túl, ahogy az FNV kéri; a
/// szerver natívan fut, ezért ez itt helyes.
String fnv1a64Hex(List<int> bytes) {
  // A 64 bites eltolási alap (0xcbf29ce484222325) a 2^63 fölé esik. Két
  // 32 bites félből áll össze, mert egy ekkora literált az
  // avoid_js_rounded_ints tilt; a natív eltolás kettes komplemensben
  // ugyanazt a bitmintát adja.
  var hash = (0xcbf29ce4 << 32) | 0x84222325;
  const prime = 0x100000001b3;
  for (final byte in bytes) {
    hash = (hash ^ (byte & 0xff)) * prime;
  }
  // A felső és az alsó 32 bit külön, hogy az előjel ne kerüljön a
  // kimenetbe.
  final high = (hash >> 32) & 0xffffffff;
  final low = hash & 0xffffffff;
  return '${_hex8(high)}${_hex8(low)}';
}

String _hex8(int value) => value.toRadixString(16).padLeft(8, '0');
