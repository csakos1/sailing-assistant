/// Egy rögzített pillanatkép szél-projekciója (ADR 0048 D5).
///
/// A `TrackSample` mintájára keskeny szerződés: a `SummarizeWind`-nek két
/// mennyiség kell, így az olvasó a teljes `RaceSnapshot` visszaépítése
/// nélkül, projekcióval szolgálhatja ki.
///
/// Mindkét mező `null` lehet: a valós szél csak élő DST-szenzor mellett
/// számolható, a talaj-referenciás irányt pedig nem minden hardver-
/// konfiguráció adja (lásd `WindData`).
abstract interface class WindSample {
  /// A valós szélsebesség (TWS, víz-referenciás) m/s-ben, vagy `null`.
  double? get twsMps;

  /// A valós szélirány (TWD, talaj-referenciás, földrajzi északtól)
  /// fokban, `[0, 360)` tartományban, vagy `null`.
  double? get twdDeg;
}
