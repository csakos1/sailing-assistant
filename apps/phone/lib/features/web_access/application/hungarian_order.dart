// Nevek sorrendje a magyar ábécé szerint (ADR 0051 Addendum 10 Z8).
//
// Kis, saját összehasonlító, mert az `intl` nincs függőségként (§7 11.):
// kis- és nagybetű nélkül, az ékezetes magánhangzók a párjuk után, a
// kettős betűk (cs, dzs, gy, …) külön kezelése nélkül. A szóköz, a
// számjegyek és az ASCII-jelek a betűk előtt, a többi jel utánuk jön.

const String _alphabet = 'aábcdeéfghiíjklmnoóöőpqrstuúüűvwxyz';

final Map<int, int> _rankOf = {
  for (var index = 0; index < _alphabet.length; index++)
    _alphabet.codeUnitAt(index): index,
};

/// Két név összevetése a magyar ábécé szerint; teljes egyezésnél a
/// kódpontok döntenek, hogy a sorrend stabil legyen.
int compareHungarian(String left, String right) {
  final a = left.toLowerCase();
  final b = right.toLowerCase();
  final length = a.length < b.length ? a.length : b.length;
  for (var index = 0; index < length; index++) {
    final order = _rank(a.codeUnitAt(index)).compareTo(
      _rank(b.codeUnitAt(index)),
    );
    if (order != 0) return order;
  }
  final byLength = a.length.compareTo(b.length);
  return byLength != 0 ? byLength : left.compareTo(right);
}

// A betűsoron kívüli jelek egymás közt a kódjuk szerint: az ASCII-ak
// (szóköz, számjegy, írásjel) a betűk elé, így „Kis Ádám" a „Kisó" elé.
int _rank(int codeUnit) =>
    _rankOf[codeUnit] ??
    (codeUnit < 128 ? codeUnit - 128 : _alphabet.length + codeUnit);
