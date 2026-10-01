import 'dart:async';

/// Egyszerű aszinkron zár: a feladatok érkezési sorrendben, egymás után
/// futnak (ADR 0047 D6 9. pont, ADR 0048 Addendum 3 I5).
///
/// Az import és az eredmény-mentés utáni statisztika-frissítés ugyanazt a
/// példányt használja, hogy egy import közben mentett eredmény ne írhassa
/// felül a friss mintákból számolt statisztikát. A lánc soha nem
/// hibásodik meg, mert a `done` a `finally`-ban mindig teljesül.
final class SerialLock {
  Future<void> _last = Future<void>.value();

  /// A [task] futtatása, miután minden korábban beküldött feladat végzett.
  Future<T> run<T>(Future<T> Function() task) async {
    final previous = _last;
    final done = Completer<void>();
    _last = done.future;
    try {
      await previous;
      return await task();
    } finally {
      done.complete();
    }
  }
}
