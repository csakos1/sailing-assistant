import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Egy hajó polárdiagramja: a cél-vízsebesség (target STW, csomóban) a
/// valódi szélszög (TWA, fok) és a valódi szélsebesség (TWS, csomó)
/// függvényében, egy diszkrét TWA×TWS rácson.
///
/// Immutable, value-equality ([Equatable] alapon). A rács offline épül a
/// YDVR-archívumból (ADR 0028 Addendum 1, `polar_builder`); az 1. szelet
/// csak a már validált rácsot tárolja — a `.pol`-fájl parse-olását és a
/// perzisztenciát a 2. szelet végzi (`Result`-alapú factory-val).
///
/// **Tengelyek.** A [twaAxis] a `|TWA|`-szimmetria miatt 0–180° (fél-rács:
/// a bal és jobb halz egyenlő), szigorúan növekvő. A [twsAxis] szigorúan
/// növekvő szélsebesség-vödrök (pl. 2–18 csomó). A [grid] sorai a
/// [twaAxis]-, oszlopai a [twsAxis]-indexhez tartoznak:
/// `grid[twaIndex][twsIndex]`.
///
/// **Üres vödör.** A rács cellája `null`, ha a vödörhöz nem volt elég
/// minta (`polar_builder` `MIN_SAMPLES`). A lookup ilyenkor a szomszéd
/// vödrökből interpolál, ezért a hiányt itt `null` jelzi, NEM 0.0 (a 0.0
/// a `.pol`-dialektus üres-sentinelje, de a domain-rácsban már `null`).
///
/// **No-go.** A [noGoThresholdDegrees] (= 25°) alatti `|TWA|`-n nincs
/// vitorlázási target (a hajó nem megy szembe a széllel). A küszöb
/// jelentésben közös a `polar_builder` `NOGO_CUT`-jával (ADR 0028
/// Addendum 1 A4/A7). A no-go *döntést* a `LookupTargetSpeed` hozza meg.
@immutable
class Polar extends Equatable {
  /// Új polár a megadott tengelyekből és rácsból. Az invariánsokat
  /// assert őrzi: a tengelyek nem üresek és szigorúan növekvők, a
  /// [twaAxis] a 0–180° tartományban van, és a [grid] alakja a
  /// tengelyekhez illeszkedik (sor-szám = TWA, oszlop-szám = TWS).
  ///
  /// A bemenetet már validáltnak feltételezzük (a 2. szelet parsere
  /// `Result`-tal szűri az untrusted fájlt), ezért nincs `Result`-alapú
  /// factory, csak assert-védőháló a programozói hibákra.
  Polar({
    required List<double> twaAxis,
    required List<double> twsAxis,
    required List<List<double?>> grid,
  }) : assert(twaAxis.isNotEmpty, 'A TWA-tengely nem lehet üres.'),
       assert(twsAxis.isNotEmpty, 'A TWS-tengely nem lehet üres.'),
       assert(
         _isStrictlyAscending(twaAxis),
         'A TWA-tengelynek szigorúan növekvőnek kell lennie.',
       ),
       assert(
         _isStrictlyAscending(twsAxis),
         'A TWS-tengelynek szigorúan növekvőnek kell lennie.',
       ),
       assert(
         _isWithinTwaRange(twaAxis),
         'A TWA-tengely értékei a [0, 180] tartományba esnek.',
       ),
       assert(
         grid.length == twaAxis.length,
         'A rács sor-száma a TWA-tengely hosszával egyezik.',
       ),
       assert(
         _allRowsMatch(grid, twsAxis.length),
         'A rács minden sora a TWS-tengely hosszával egyezik.',
       ),
       twaAxis = List.unmodifiable(twaAxis),
       twsAxis = List.unmodifiable(twsAxis),
       grid = List<List<double?>>.unmodifiable(
         grid.map(List<double?>.unmodifiable),
       );

  /// A no-go küszöb fokban: e szög alatti `|TWA|`-n nincs vitorlázási
  /// target. Jelentésben közös a `polar_builder` `NOGO_CUT`-jával (ADR
  /// 0028 Addendum 1).
  static const double noGoThresholdDegrees = 25;

  /// A valódi szélszög (TWA) tengelye fokban, 0–180°, szigorúan növekvő.
  final List<double> twaAxis;

  /// A valódi szélsebesség (TWS) tengelye csomóban, szigorúan növekvő.
  final List<double> twsAxis;

  /// A target-vízsebesség rács csomóban: `grid[twaIndex][twsIndex]`. A
  /// cella `null`, ha a vödör üres (kevés minta volt) — a lookup ilyenkor
  /// a szomszédokból interpolál.
  final List<List<double?>> grid;

  /// Igaz, ha a tengely szigorúan növekvő (nincs ismétlődés, nincs esés).
  static bool _isStrictlyAscending(List<double> axis) {
    for (var i = 1; i < axis.length; i++) {
      if (axis[i] <= axis[i - 1]) return false;
    }
    return true;
  }

  /// Igaz, ha a TWA-tengely minden értéke a 0–180° tartományba esik.
  static bool _isWithinTwaRange(List<double> axis) {
    for (final twa in axis) {
      if (twa < 0 || twa > 180) return false;
    }
    return true;
  }

  /// Igaz, ha a rács minden sora pontosan [columnCount] hosszú.
  static bool _allRowsMatch(List<List<double?>> grid, int columnCount) {
    for (final row in grid) {
      if (row.length != columnCount) return false;
    }
    return true;
  }

  @override
  List<Object?> get props => [twaAxis, twsAxis, grid];

  /// A teljes rács kiírása olvashatatlan lenne (tucatnyi sor × oszlop),
  /// ezért a debug-string csak a dimenziókat adja.
  @override
  String toString() => 'Polar(twa: ${twaAxis.length}, tws: ${twsAxis.length})';
}
