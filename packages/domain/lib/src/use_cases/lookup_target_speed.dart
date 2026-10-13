import 'package:domain/src/_internal/bilinear_interpolation.dart';
import 'package:domain/src/entities/polar.dart';
import 'package:meta/meta.dart';

/// A pillanatnyi cél-vízsebességet (target STW, csomóban) adja vissza egy
/// [Polar] rácsból a megadott TWA és TWS mellett, bilineáris
/// interpolációval.
///
/// **Pure use case.** Nincs állapota, nincs mellékhatása; a `call`
/// kizárólag a bemenetekből számol. Const-konstruálható, így a
/// composite use case-ek és a tesztek olcsón példányosítják.
///
/// A visszaadott érték a TWS×TWA-hoz tartozó elérhető (p90) hajósebesség;
/// a hívó ebből és az élő STW-ből számolja a target-százalékot
/// (`% = élő STW / target`). `null` jön vissza, ha nincs értelmes target:
/// a no-go zónában, üres rács-környezetben, egy teljesen üres szélső
/// TWA-sor felé, nem pozitív TWS-re, vagy nem-véges bemenetre.
///
/// **Horgony 0 csomónál (ADR 0058 D5).** A TWS-tengely legalsó oszlopa
/// alatt a cél arányosan a 0 felé tart: `cél(első) × tws / első`. A
/// tengely fölött a clamp marad.
@immutable
class LookupTargetSpeed {
  /// Const konstruktor — a use case stateless és pure.
  const LookupTargetSpeed();

  /// A [polar] rácsból a [twaDegrees] (előjeles, port −/starboard +) és a
  /// [twsKnots] melletti cél-vízsebesség, vagy `null`, ha nincs target.
  ///
  /// Lépések: `|TWA|`-hajtás (a fél-rács 0–180° kihasználása) → no-go
  /// kapu ([Polar.noGoThresholdDegrees] alatt `null`) → a kitöltött
  /// TWA-sorok kapuja ([Polar.populatedTwaRange]) → a rács-tartomány
  /// szélén clamp → bilineáris interpoláció → a 0 csomós horgony a
  /// legalsó TWS-oszlop alatt. Üres szomszéd-vödröknél a
  /// [bilinearInterpolate] a meglévő sarkokból interpolál; ha egy sem
  /// adott, `null`.
  double? call({
    required Polar polar,
    required double twaDegrees,
    required double twsKnots,
  }) {
    // Védőháló: nem-véges bemenetre (NaN/±∞) nincs értelmes lookup.
    if (!twaDegrees.isFinite || !twsKnots.isFinite) return null;

    // Szélcsendben (vagy hibás negatív TWS-re) nincs target: a horgony
    // 0-t adna, amivel a hívó élő %-a 0-val osztana.
    if (twsKnots <= 0) return null;

    // |TWA|-hajtás: a polár fél-rács (0–180°), a bal/jobb halz egyenlő.
    final absTwa = twaDegrees.abs();

    // No-go: a küszöb alatt nincs vitorlázási target — „—", NEM 0%.
    if (absTwa < Polar.noGoThresholdDegrees) return null;

    if (!_isWithinPopulatedRows(polar, absTwa)) return null;

    final twa = _bracket(polar.twaAxis, absTwa);
    final tws = _bracket(polar.twsAxis, twsKnots);

    final targetAtBracket = bilinearInterpolate(
      lowTwaLowTws: polar.grid[twa.lowIndex][tws.lowIndex],
      lowTwaHighTws: polar.grid[twa.lowIndex][tws.highIndex],
      highTwaLowTws: polar.grid[twa.highIndex][tws.lowIndex],
      highTwaHighTws: polar.grid[twa.highIndex][tws.highIndex],
      twaFraction: twa.fraction,
      twsFraction: tws.fraction,
    );
    if (targetAtBracket == null) return null;

    // D5 horgony: a legalsó oszlop alatt a _bracket az első oszlopra
    // clampel, ezt skálázzuk arányosan a 0 felé. A `twsKnots > 0` fent
    // biztosított, így ebben az ágban a tengely első eleme is pozitív.
    final lowestTwsKnots = polar.twsAxis.first;
    if (twsKnots < lowestTwsKnots) {
      return targetAtBracket * twsKnots / lowestTwsKnots;
    }
    return targetAtBracket;
  }

  /// Igaz, ha az [absTwa] nem lóg ki egy teljesen üres szélső TWA-sor
  /// felé (ADR 0058, P.4).
  ///
  /// Ha a rács végén (vagy elején) üres sorok állnak, a cél az utolsó
  /// (első) kitöltött sornál véget ér: különben a bilineáris újranormálás
  /// a kitöltött sor értékét vinné tovább az üres sorig (a 180°-os sor
  /// nélkül 175° és 180° között), és a VMG-keresés oda tenné az optimumot.
  /// Ha a kitöltött sor maga a tengely széle, a szokásos clamp érvényes.
  /// Teljesen üres rácsra hamis.
  bool _isWithinPopulatedRows(Polar polar, double absTwa) {
    final populated = polar.populatedTwaRange;
    if (populated == null) return false;

    final lastAxisIndex = polar.twaAxis.length - 1;
    final hasEmptyTrailingRows = populated.last < lastAxisIndex;
    if (hasEmptyTrailingRows && absTwa > polar.twaAxis[populated.last]) {
      return false;
    }
    final hasEmptyLeadingRows = populated.first > 0;
    if (hasEmptyLeadingRows && absTwa < polar.twaAxis[populated.first]) {
      return false;
    }
    return true;
  }

  /// A [value]-t bracketelő alsó/felső tengely-index és a köztük lévő
  /// frakció (0–1). A tartományon kívüli értéket a perem-cellához
  /// clamp-eljük (frakció 0 vagy 1).
  ({int lowIndex, int highIndex, double fraction}) _bracket(
    List<double> axis,
    double value,
  ) {
    // Egy-elemű tengely: nincs mibe interpolálni, a frakció 0.
    if (axis.length == 1) {
      return (lowIndex: 0, highIndex: 0, fraction: 0);
    }
    // Tartomány alatt → az első cella alsó pereme.
    if (value <= axis.first) {
      return (lowIndex: 0, highIndex: 1, fraction: 0);
    }
    // Tartomány felett → az utolsó cella felső pereme.
    if (value >= axis.last) {
      final last = axis.length - 1;
      return (lowIndex: last - 1, highIndex: last, fraction: 1);
    }
    // Belső érték: az axis[i] <= value < axis[i+1] cella.
    for (var i = 0; i < axis.length - 1; i++) {
      if (value < axis[i + 1]) {
        final fraction = (value - axis[i]) / (axis[i + 1] - axis[i]);
        return (lowIndex: i, highIndex: i + 1, fraction: fraction);
      }
    }
    // Elvileg elérhetetlen (a peremek lefedik); statikus védőháló.
    final last = axis.length - 1;
    return (lowIndex: last - 1, highIndex: last, fraction: 1);
  }
}
