/// A versenyt jelentő `Race` entitás lehetséges állapotai.
///
/// Az átmenetek monotonok és egyirányúak: [notStarted] → [active] →
/// [finished]. Visszafelé út nincs. A `Race` state-transition factory-k
/// (`start`, `roundCurrentMark`, `finish`) garantálják, hogy csak érvényes
/// átmenet történjen.
enum RaceStatus {
  /// A verseny rögzítve van, de még nem indult el.
  notStarted,

  /// A verseny fut: a hajó valamelyik bóya felé tart.
  active,

  /// A verseny lezárult — vagy minden bóya körözve, vagy explicit lezárás
  /// (DNF, abort) történt.
  finished,
}
