/// A track-statisztikák számításához szükséges minimális minta-szerződés.
///
/// A `SummarizeTrack` use case-nek mindössze három mennyiség kell egy
/// rögzített pillanatképből: a sebesség és a két koordináta. Korábban a
/// tizenhárom mezős `RoundingSample`-tól függött, ami fölösleges csatolás
/// (ISP): minden olvasó-implementációnak a teljes read-modellt elő kellett
/// állítania, holott a számítás ennek a negyedét sem használja.
///
/// Az ADR 0044 Addendum 4 ezért szűkítette a use case bemenetét erre az
/// interfészre. A `RoundingSample` megvalósítja, így a meglévő hívási
/// helyek — a Dart listáinak kovarianciája miatt — változatlanul fordulnak,
/// és egy olcsóbb, projekciós olvasó is kiszolgálhatja a számítást.
///
/// **A névről:** nem `TrackPoint`, mert azt a nevet az `apps/phone`
/// track-rajzoló rétege már használja, és a barrel-export ütközne vele.
///
/// **Miért `interface class`:** a típusnak nincs viselkedése, csak
/// szerződése. Megvalósítani szabad, örökölni belőle nem.
abstract interface class TrackSample {
  /// SOG m/s-ben, vagy `null`, ha a pillanatképnek nincs sebessége.
  double? get sogMps;

  /// A hajó szélességi foka fokban, vagy `null`, ha nincs pozíció.
  double? get latDeg;

  /// A hajó hosszúsági foka fokban, vagy `null`. Lásd `latDeg`.
  double? get lonDeg;
}
