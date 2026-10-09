/// A polár-táblázat oszlopszélességei (16a; keskenyen 16d-4).
///
/// A két nézet (egy év, összes év) ugyanazt a rácsot kapja, hogy a hét
/// számoszlop pixelre egy vonalban legyen.
enum PolarTableMetrics {
  /// A széles rács: rang 34, dátum 48, szél 50, százalékok 54, legjobb
  /// 5 mp 58, két arány 66–66.
  wide(
    isNarrow: false,
    rankWidth: 34,
    dateWidth: 48,
    windWidth: 50,
    pctWidth: 54,
    bestWidth: 58,
    shareWidth: 66,
  ),

  /// A keskeny rács: a dátum a név alá kerül, a számoszlopok szűkülnek.
  narrow(
    isNarrow: true,
    rankWidth: 34,
    dateWidth: 0,
    windWidth: 46,
    pctWidth: 50,
    bestWidth: 54,
    shareWidth: 48,
  )
  ;

  const PolarTableMetrics({
    required this.isNarrow,
    required this.rankWidth,
    required this.dateWidth,
    required this.windWidth,
    required this.pctWidth,
    required this.bestWidth,
    required this.shareWidth,
  });

  /// E tartalom-szélesség alatt a keskeny rács érvényes (Addendum 5 W3).
  static const double narrowBelowWidth = 820;

  /// A [contentWidth]-hez illő rács.
  static PolarTableMetrics forWidth(double contentWidth) =>
      contentWidth < narrowBelowWidth ? narrow : wide;

  /// Igaz a keskeny rácson.
  final bool isNarrow;

  /// A rang oszlopa.
  final double rankWidth;

  /// A dátum oszlopa; keskenyen 0.
  final double dateWidth;

  /// A szél oszlopa.
  final double windWidth;

  /// Az átlag, a medián, a P90 és a P99 oszlopa.
  final double pctWidth;

  /// A legjobb 5 mp oszlopa.
  final double bestWidth;

  /// Egy arány-oszlop; a mini sáv a kettő együtt.
  final double shareWidth;

  /// A bal oldali vezető terület egy verseny sorában: rang és dátum.
  double get leadWidth => rankWidth + dateWidth;

  /// Az évszám oszlopa az évsorban; keskenyen sem szűkebb, mint amennyi
  /// a négy számjegynek kell a 16 px-es Martianban.
  double get yearWidth => leadWidth < _minYearWidth ? _minYearWidth : leadWidth;

  static const double _minYearWidth = 64;

  /// A szél és az öt százalék-oszlop együtt.
  double get numbersWidth => windWidth + pctWidth * 4 + bestWidth;

  /// A mini sáv szélessége.
  double get barWidth => shareWidth * 2;
}
