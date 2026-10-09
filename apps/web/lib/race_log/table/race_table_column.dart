/// A táblázat oszlopai, balról jobbra (ADR 0048 Addendum 1 G2).
///
/// Az első kettő a rögzített blokk. Az [isQuantity] dönti el az első
/// kattintás irányát: a dátum és a mennyiség csökkenő, a helyezés és a
/// szöveg növekvő (az 1. elöl).
enum RaceTableColumn {
  /// A verseny napja.
  date(isQuantity: true),

  /// A verseny neve.
  name(isQuantity: false),

  /// Osztályhelyezés a mezőnnyel.
  classPlace(isQuantity: false),

  /// Abszolút helyezés a mezőnnyel.
  overallPlace(isQuantity: false),

  /// Egytestű helyezés a mezőnnyel.
  monohullPlace(isQuantity: false),

  /// A YS-szám.
  ysNumber(isQuantity: true),

  /// A rajt ideje.
  start(isQuantity: true),

  /// A befutás ideje.
  finish(isQuantity: true),

  /// A menetidő.
  elapsed(isQuantity: true),

  /// A megtett táv.
  distance(isQuantity: true),

  /// Az átlagsebesség.
  avgSpeed(isQuantity: true),

  /// A legnagyobb sebesség.
  maxSpeed(isQuantity: true),

  /// Az átlagos szél.
  avgWind(isQuantity: true),

  /// A legnagyobb szél.
  maxWind(isQuantity: true),

  /// Az uralkodó szélirány égtájként.
  windDirection(isQuantity: false),

  /// A díj szövege.
  prize(isQuantity: false)
  ;

  const RaceTableColumn({required this.isQuantity});

  /// Igaz, ha az oszlop mennyiséget vagy dátumot mutat: az első kattintás
  /// csökkenő sorrendet ad.
  final bool isQuantity;

  /// A rögzített (balra ragadó) oszlopok száma: Dátum és Verseny.
  static const int pinnedCount = 2;
}
