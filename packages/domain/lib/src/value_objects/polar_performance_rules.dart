/// A polár-teljesítmény küszöbei egy helyen (ADR 0049 D7–D10, Addendum 3
/// T5).
///
/// A szerver cache-ujjlenyomata (D10) ezekből is számol, ezért egy
/// küszöb változása minden cache-sort elavulttá tesz.
abstract final class PolarPerformanceRules {
  /// Ennyi mért másodperc alatt a versenynek nincs statisztikája és
  /// rangja (D8).
  static const int minimumSeconds = 60;

  /// Ennyi másodperc kell egy szélvödörben, hogy a rangba számítson (D9).
  static const int minimumBucketSeconds = 60;

  /// A szélvödrök szélessége csomóban (D9).
  static const double windBucketKnots = 2;

  /// Hány hisztogram-rés jut egy százalékpontra: 2, azaz 0,5%-os rések
  /// (D10).
  static const int binsPerPercent = 2;

  /// E százalék fölött minden másodperc egy közös résbe kerül (D10).
  static const int overflowPercent = 300;

  /// A közös túlcsorduló rés indexe.
  static const int overflowBin = overflowPercent * binsPerPercent;

  /// A tüske-szűrő csúszó mediánjának ablaka mintában (D7).
  static const int spikeWindowSize = 5;

  /// A TWS legnagyobb eltérése a mediánjától csomóban; afölött tüske (D7).
  static const double spikeThresholdKnots = 5;

  /// A „Legjobb 5 mp" futamának hossza másodpercben (D8).
  static const int bestRunSeconds = 5;
}
