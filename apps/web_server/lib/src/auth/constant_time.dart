/// Az [a] és a [b] bájtsor egyezik-e, a tartalomtól független idő alatt
/// (ADR 0051 Addendum 2 J5).
///
/// Token-, kód- és hash-egyezésnél ezt kell használni a `==` helyett: a
/// korán kilépő összevetés ideje elárulná, hány bájt egyezik. A hossz nem
/// titok (rögzített hosszú hash-ek), ezért eltérő hossznál azonnal kilép.
bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var difference = 0;
  for (var i = 0; i < a.length; i++) {
    difference |= a[i] ^ b[i];
  }
  return difference == 0;
}
