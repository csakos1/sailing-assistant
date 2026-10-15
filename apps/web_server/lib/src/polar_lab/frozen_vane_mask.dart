import 'package:domain/domain.dart';
import 'package:web_server/src/polar_lab/twa_window_extremes.dart';

/// A működő szélirány-mérő mintáinak maszkja (ADR 0058 D6): `false`, ha a
/// mérő beragadt, `true` különben.
///
/// Ha a szélirány-mérőt pókháló köti le, a műszer nem mér, és a `|TWA|`
/// többnyire 180°-on áll, ritkán 0°-ra ugrik. A minta beragadtnak számít,
/// ha a ±[halfWindowSeconds] másodperces környezetében ([twaWindowExtremes])
/// minden érvényes `|TWA|` a 0° vagy a 180° [maximumOffsetDegrees]-nál
/// kisebb közelében áll. A két vég közti ugrás így nem szakítja meg a
/// beragadt szakaszt. Valódi hátszélben a szélirány egy perc alatt ennél
/// többet mozog.
///
/// Az érvénytelen szögű minta `true`: azt a közös szűrő úgyis eldobja.
///
/// Pure függvény; a [samples] időrendben jön (egy verseny mintái), az
/// eredmény vele egyforma hosszú.
List<bool> frozenVaneMask(
  List<PolarSample> samples, {
  int halfWindowSeconds = frozenVaneHalfWindowSeconds,
  double maximumOffsetDegrees = frozenVaneMaximumOffsetDegrees,
}) {
  final extremes = twaWindowExtremes(
    samples,
    halfWindowSeconds: halfWindowSeconds,
    measure: _offsetFromEnd,
  );
  return [
    for (final window in extremes)
      window == null || window.maximum >= maximumOffsetDegrees,
  ];
}

/// A beragadt szélirány ablakának fele másodpercben (alapérték).
const int frozenVaneHalfWindowSeconds = 30;

/// A beragadt szélirány legnagyobb távolsága a 0°-tól vagy a 180°-tól
/// (kizárólagos, fok; alapérték).
const double frozenVaneMaximumOffsetDegrees = 2;

// A hajtott szög távolsága a közelebbi végtől (0° vagy 180°).
double _offsetFromEnd(double foldedDegrees) =>
    foldedDegrees < 90 ? foldedDegrees : 180 - foldedDegrees;
