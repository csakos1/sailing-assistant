/// A webes tartalék-jelszó legrövidebb hossza, Unicode kódpontban (ADR
/// 0051 D6).
const int minimumPasswordLength = 12;

/// A tartalék-jelszó leghosszabb alakja, Unicode kódpontban.
///
/// Felső korlát nélkül egy óriási jelszó a hash-elést is drágítaná; a
/// 128 kódpont bármilyen jelmondatnak elég.
const int maximumPasswordLength = 128;

/// Elfogadható-e a [password] tartalék-jelszónak.
///
/// Csak a hosszt nézi: a jelszó tartalmát (szóköz, ékezet) nem
/// korlátozzuk, és nem is alakítjuk át.
bool isAcceptablePassword(String password) {
  final length = password.runes.length;
  return length >= minimumPasswordLength && length <= maximumPasswordLength;
}
