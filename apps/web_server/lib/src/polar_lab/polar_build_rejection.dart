import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/polar_build_axes.dart';

/// Miért nem kerül egy minta az épülő polárba (ADR 0058 D6).
///
/// Ezek csak a polár építésekor szűrnek, a webes szűrők (érvényes érték,
/// TWS-tüske) után. Az állandósult szél szűrője a mintasoron fut
/// (`steadyWindMask`), mert a szomszédos mintákat nézi.
enum PolarBuildRejection {
  /// A vízsebesség a ([minimumStwKnots], [maximumStwKnots]) tartományon
  /// kívül van (ADR 0028 Addendum 1 A4).
  waterSpeed,

  /// Szélcsend: a műszer szél nélkül 180°-ot adhat, ez nem hátszél-minta.
  calm,

  /// A szél a `PolarBuildAxes.minimumTwsKnots` alatt van.
  lightAir,

  /// A `|TWA|` a no-go zóna soraiba esik.
  noGo
  ;

  /// A legkisebb elfogadott vízsebesség (kizárólagos), csomóban.
  static const double minimumStwKnots = 0.3;

  /// A legnagyobb elfogadott vízsebesség (kizárólagos), csomóban.
  static const double maximumStwKnots = 12;

  /// A szélcsend `|TWA|`-küszöbe fokban (ettől felfelé).
  static const double calmTwaDegrees = 177.5;

  /// A szélcsend TWS-küszöbe csomóban (ez alatt).
  static const double calmTwsKnots = 2;

  /// A [sample] kiesésének oka, vagy `null`, ha a minta a polárba kerül.
  /// Több ok esetén a felsorolás sorrendjében az első.
  static PolarBuildRejection? of(LabSample sample) {
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
    return null;
  }
}
