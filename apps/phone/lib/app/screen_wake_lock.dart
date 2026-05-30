/// A kijelző ébren tartásának absztrakciója (DIP a tesztelhetőségért).
///
/// A valós implementáció (`WakelockPlusScreenWakeLock`) a `wakelock_plus`
/// plugint hívja; a widget-teszt no-op fake-kel override-ol, mert a plugin
/// `flutter_test` alatt `MissingPluginException`-t dobna.
abstract interface class ScreenWakeLock {
  /// Bekapcsolja a wakelockot — verseny közben a kijelző nem alszik el.
  Future<void> enable();

  /// Kikapcsolja a wakelockot — visszaáll a rendszer alvás-viselkedése.
  Future<void> disable();
}
