/// A navigációs héj három füle, a sáv sorrendjében (ADR 0056 D2).
enum ShellTab {
  /// Versenyek: a lista és az új verseny.
  races,

  /// Műszerek: az élő adatok (a felületen „Műszerek", a kódban `live_race`).
  instruments,

  /// Versenynapló: a befejezett versenyek.
  log,
}
