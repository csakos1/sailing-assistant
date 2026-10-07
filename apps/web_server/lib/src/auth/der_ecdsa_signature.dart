/// Egy ECDSA-aláírás két egésze.
typedef EcdsaSignatureValues = ({BigInt r, BigInt s});

// Egy P-256 egész legfeljebb 32 bájt, plusz egy vezető nulla, ha a felső
// bitje 1 (különben negatívnak látszana).
const int _maxIntegerLength = 33;

// A leghosszabb P-256 aláírás: 2 + 2 × (2 + 33) bájt. Ennél rövidebb
// sorozathossz rövid alakban (egy bájton) áll.
const int _maxSignatureLength = 72;

/// A [der] ECDSA-aláírás (`SEQUENCE { INTEGER r, INTEGER s }`) két egésze,
/// vagy `null`, ha nem szabályos DER (ADR 0051 Addendum 2 J9).
///
/// Szigorú DER: rövid hosszmezők, a sorozat pontosan kitölti a bemenetet,
/// az egészek pozitívak és minimális hosszúak (nincs fölösleges vezető
/// nulla). Így egy (r, s) párnak egyetlen kódolása van. A tartományt
/// (`1 ≤ r, s < n`) az ellenőrzés nézi; az `s` és az `n − s` is érvényes,
/// ez nem gond, mert minden aláírt kihívás egyszer használatos.
EcdsaSignatureValues? parseDerEcdsaSignature(List<int> der) {
  if (der.length < 8 ||
      der.length > _maxSignatureLength ||
      der[0] != 0x30 ||
      der[1] != der.length - 2) {
    return null;
  }
  final r = _readInteger(der, 2);
  if (r == null) return null;
  final s = _readInteger(der, r.end);
  if (s == null || s.end != der.length) return null;
  return (r: r.value, s: s.value);
}

({BigInt value, int end})? _readInteger(List<int> der, int offset) {
  if (offset + 2 > der.length || der[offset] != 0x02) return null;
  final length = der[offset + 1];
  final start = offset + 2;
  final end = start + length;
  if (length == 0 || length > _maxIntegerLength || end > der.length) {
    return null;
  }
  // A felső bit 1 negatív számot jelentene.
  if (der[start] & 0x80 != 0) return null;
  // Vezető nulla csak akkor kell, ha a következő bájt felső bitje 1.
  if (der[start] == 0 && (length == 1 || der[start + 1] & 0x80 == 0)) {
    return null;
  }
  var value = BigInt.zero;
  for (var i = start; i < end; i++) {
    value = (value << 8) | BigInt.from(der[i]);
  }
  return (value: value, end: end);
}
