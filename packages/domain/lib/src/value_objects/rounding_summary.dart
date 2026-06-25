/// A megkerülés-elemzés összegző mutatói (ADR 0034 D6 fej). Az egyes
/// `RoundingResult`-okból aggregálva; a UI a három cellát ebből formázza.
class RoundingSummary {
  /// Összegző a megadott aggregátumokkal.
  const RoundingSummary({
    this.avgAbsDeltaDeg,
    this.bandHits = 0,
    this.bandTotal = 0,
    this.avgLeadTime,
  });

  /// A |delta|-k átlaga fokban a deltával rendelkező megkerüléseken, vagy
  /// `null`, ha egyikhez sincs delta (hiányzó predikció vagy tényleges).
  final double? avgAbsDeltaDeg;

  /// A hibasávba esett megkerülések száma (a [bandTotal]-ból).
  final int bandHits;

  /// Azon megkerülések száma, amelyekre a sáv-ítélet kiszámolható volt (van
  /// delta ÉS sáv); a találati arány nevezője.
  final int bandTotal;

  /// A lead-time-ok átlaga (másodpercre kerekítve) a megbízható
  /// megkerüléseken, vagy `null`, ha egyikhez sincs lead-time.
  final Duration? avgLeadTime;
}
