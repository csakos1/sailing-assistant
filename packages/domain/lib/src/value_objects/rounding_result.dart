import 'package:domain/src/_internal/wrap_angle.dart';

/// Egy boja-korozes predikalt-vs-tenyleges eredmenye (ADR 0025 D1). Az adott
/// leg-re (a korozott bojatol a kovetkezoig) szol, amire a predikcio
/// vonatkozott.
class RoundingResult {
  /// Egy korozes eredmenye.
  const RoundingResult({
    required this.fromMark,
    required this.toMark,
    required this.roundedAt,
    this.predictedTwaDeg,
    this.actualTwaDeg,
    this.forecastBandDeg,
    this.predictedConfidence,
    this.leadTime,
    this.lastReliableLeadTime,
    this.actualSampleCount = 0,
  });

  /// A korozott boja (a leg INNEN indul).
  final String fromMark;

  /// A kovetkezo boja (a leg IDE tart) — erre szolt a predikcio.
  final String toMark;

  /// A korozes ideje (a markName-valtas elso tickje).
  final DateTime roundedAt;

  /// A leg-re josolt TWA fokban (a korozes elotti nem-null), vagy `null`.
  final double? predictedTwaDeg;

  /// A ténylegesen befutott TWA fokban (a beallasi ablak korkozepe),
  /// vagy `null`.
  final double? actualTwaDeg;

  /// A predikciot ado snapshot hibasavja fokban, vagy `null`.
  final double? forecastBandDeg;

  /// A predikciot ado snapshot konfidencia-szintje, vagy `null`.
  final String? predictedConfidence;

  /// Mennyivel a korozes elott lett es maradt megbizhato a joslat, vagy `null`,
  /// ha a korozeskor mar nem volt megbizhato.
  final Duration? leadTime;

  /// Az utolso valodi (nem-null) megbizhato joslat lead-time-ja: a korozes es
  /// a freeze-onset (anchor) kozti ido, vagy `null` a [leadTime]-mal azonos
  /// feltetellel. A [leadTime]-mal egyutt a megbizhatosagi ablakot adja
  /// (mettol -> meddig a boja elott; ADR 0034 Addendum 1).
  final Duration? lastReliableLeadTime;

  /// Hany snapshotbol atlagoltuk a tenyleges TWA-t (0 = nem volt eleg adat).
  final int actualSampleCount;

  /// A delta: tenyleges − predikalt, [-180, 180)-ra normalizalva; `null`, ha
  /// barmelyik oldal hianyzik.
  double? get deltaDeg {
    final predicted = predictedTwaDeg;
    final actual = actualTwaDeg;
    if (predicted == null || actual == null) return null;
    return wrapTo180(actual - predicted);
  }

  /// A tenyleges a sávon belul van-e (`|delta| <= band`); `null`, ha valami
  /// hianyzik.
  bool? get isWithinBand {
    final delta = deltaDeg;
    final band = forecastBandDeg;
    if (delta == null || band == null) return null;
    return delta.abs() <= band;
  }
}
