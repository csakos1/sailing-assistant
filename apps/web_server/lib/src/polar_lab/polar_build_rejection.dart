import 'dart:math';

import 'package:web_server/src/polar_lab/apparent_wind_angle.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/polar_build_axes.dart';

/// Miért nem kerül egy minta az épülő polárba (ADR 0058 D6).
///
/// Ezek csak a polár építésekor szűrnek, a webes szűrők (érvényes érték,
/// TWS-tüske) után. A beragadt szélirány és az állandósult szél szűrője a
/// mintasoron fut (`frozenVaneMask`, `steadyWindMask`), mert a szomszédos
/// mintákat nézi.
enum PolarBuildRejection {
  /// A vízsebesség a ([minimumStwKnots], [maximumStwKnots]) tartományon
  /// kívül van (ADR 0028 Addendum 1 A4).
  waterSpeed,

  /// Szélcsend: a műszer szél nélkül 180°-ot adhat, ez nem hátszél-minta.
  calm,

  /// A szél a `PolarBuildAxes.minimumTwsKnots` alatt van.
  lightAir,

  /// A `|TWA|` a no-go zóna soraiba esik.
  noGo,

  /// A számolt látszólagos szélszög ([apparentWindAngleDegrees]) olyan
  /// kicsi, hogy vitorlával nem lehet haladni: kreuzban a
  /// [minimumUpwindAwaDegrees], hátszélben a [minimumDownwindAwaDegrees]
  /// alatt. Gyenge szeles hátszélben ez a szélmérés hibája (a TWS
  /// alulmért, vagy a műszer szél nélkül 180°-ot ad).
  apparentWind,

  /// Mély hátszélben (`|TWA|` ≥ [deepDownwindTwaDegrees]) a hajó
  /// szélirányú sebessége (VMG = STW × |cos TWA|) a TWS adott szorzójánál
  /// (az [of] paramétere, alapértelmezés szerint
  /// [defaultMaximumDownwindVmgRatio]) nagyobb. Egy nem sikló hajó
  /// hátszélben nem megy le gyorsabban a szélnél: ez a szélmérés hibája
  /// (a műszer a valódi szél töredékét méri).
  downwindVmg
  ;

  /// A legkisebb elfogadott vízsebesség (kizárólagos), csomóban.
  static const double minimumStwKnots = 0.3;

  /// A legnagyobb elfogadott vízsebesség (kizárólagos), csomóban.
  static const double maximumStwKnots = 12;

  /// A szélcsend `|TWA|`-küszöbe fokban (ettől felfelé).
  static const double calmTwaDegrees = 177.5;

  /// A szélcsend TWS-küszöbe csomóban (ez alatt).
  static const double calmTwsKnots = 2;

  /// A kreuz (`|TWA|` < 90°) legkisebb számolt AWA-ja fokban. Kreuzban a
  /// 10–20° normális: a műszer TWA-ja élesebbet mér, és a számolás nem
  /// ismeri a sodródást.
  static const double minimumUpwindAwaDegrees = 10;

  /// A mély hátszél `|TWA|`-küszöbe fokban (ettől felfelé).
  static const double deepDownwindTwaDegrees = 135;

  /// A mély hátszeles VMG és a TWS legnagyobb aránya (alapérték). A
  /// ráhagyás a gyenge szeles szélmérés pontatlansága miatt kell.
  static const double defaultMaximumDownwindVmgRatio = 1.3;

  /// A hátszél (`|TWA|` ≥ 90°) legkisebb számolt AWA-ja fokban.
  static const double minimumDownwindAwaDegrees = 20;

  /// A [sample] kiesésének oka, vagy `null`, ha a minta a polárba kerül.
  /// Több ok esetén a felsorolás sorrendjében az első. A
  /// [maximumDownwindVmgRatio] a [downwindVmg] küszöbe; a végtelen
  /// kikapcsolja (a diagnosztikához).
  static PolarBuildRejection? of(
    LabSample sample, {
    double maximumDownwindVmgRatio = defaultMaximumDownwindVmgRatio,
  }) {
    if (sample.stwKnots <= minimumStwKnots ||
        sample.stwKnots >= maximumStwKnots) {
      return waterSpeed;
    }
    if (sample.absTwaDeg >= calmTwaDegrees && sample.twsKnots < calmTwsKnots) {
      return calm;
    }
    if (sample.twsKnots < PolarBuildAxes.minimumTwsKnots) return lightAir;
    if (PolarBuildAxes.twaRowOf(sample.absTwaDeg) <
        PolarBuildAxes.firstSailingTwaRow) {
      return noGo;
    }
    if (_isApparentWindTooFine(sample)) return apparentWind;
    if (downwindVmgRatioOf(sample) > maximumDownwindVmgRatio) {
      return downwindVmg;
    }
    return null;
  }

  /// Mély hátszélben a VMG és a TWS aránya, különben 0.
  static double downwindVmgRatioOf(LabSample sample) {
    if (sample.absTwaDeg < deepDownwindTwaDegrees) return 0;
    final vmg = sample.stwKnots * -cos(sample.absTwaDeg * pi / 180);
    return vmg / sample.twsKnots;
  }

  static bool _isApparentWindTooFine(LabSample sample) {
    final awa = apparentWindAngleDegrees(
      absTwaDeg: sample.absTwaDeg,
      twsKnots: sample.twsKnots,
      stwKnots: sample.stwKnots,
    );
    return sample.absTwaDeg < 90
        ? awa < minimumUpwindAwaDegrees
        : awa < minimumDownwindAwaDegrees;
  }
}
