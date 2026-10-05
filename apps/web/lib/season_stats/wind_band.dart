import 'package:foretack_web/race_edit/form/speed_units.dart';

/// Az átlagos szél sávjai a szezon-statisztikában (ADR 0049 D3, Addendum
/// 1 P3), csomóban: alsó határ zárt, felső nyitott.
enum WindBand {
  /// 4 kn alatt.
  below4(lowerKnots: null, upperKnots: 4),

  /// 4–8 kn.
  from4To8(lowerKnots: 4, upperKnots: 8),

  /// 8–12 kn.
  from8To12(lowerKnots: 8, upperKnots: 12),

  /// 12–16 kn.
  from12To16(lowerKnots: 12, upperKnots: 16),

  /// 16 kn és fölötte.
  from16(lowerKnots: 16, upperKnots: null)
  ;

  const WindBand({required this.lowerKnots, required this.upperKnots});

  /// Az alsó határ (zárt); `null` a legalsó sávnál.
  final int? lowerKnots;

  /// A felső határ (nyitott); `null` a legfelső sávnál.
  final int? upperKnots;

  /// Az [avgWindMps] átlagszél sávja.
  ///
  /// A besorolás a megjelenített, tizedre kerekített csomóérték szerint
  /// történik (P3): a táblázatban `4,0`-ként látszó verseny a 4–8 sávba
  /// kerül, akkor is, ha a m/s → kn váltás 3,99999-et adna.
  static WindBand ofMetersPerSecond(double avgWindMps) {
    final knots = (metersPerSecondToKnots(avgWindMps) * 10).round() / 10;
    return values.firstWhere((band) {
      final upper = band.upperKnots;
      return upper == null || knots < upper;
    });
  }
}
