import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';

/// Az épülő polár tengelyei (ADR 0058 D4) és a minták hozzárendelése.
///
/// **TWS:** az alap-oszlopok [baseTwsColumnsKnots], és a
/// [strongWindColumnKnots] oszlop, ha annak legalább
/// [strongWindColumnMinimumSeconds] mért ideje van. Egy minta a
/// legközelebbi oszlopba kerül (a határ a két oszlop felezőpontja, a
/// felezőpont már a felsőé); a legfelső oszlop fölötti szél a legfelsőbe.
/// A [minimumTwsKnots] alatti szél egyik oszlopba sem kerül: ott a szél-
/// műszer sem megbízható, és a célt a lookup 0 csomós horgonya adja (D5).
///
/// **TWA:** 0–180° [twaStepDegrees]-onként, a `|TWA|` a legközelebbi sorba
/// kerekítve, ahogy a riport rácsában (`PolarGrid`). A
/// [firstSailingTwaRow] alatti sorok a no-go zóna: üresek maradnak.
@immutable
final class PolarBuildAxes extends Equatable {
  /// Tengelyek a megadott TWS-oszlopokkal (szigorúan növekvő, nem üres).
  PolarBuildAxes({required List<double> twsColumnsKnots})
    : assert(twsColumnsKnots.isNotEmpty, 'A TWS-tengely nem lehet üres.'),
      twsColumnsKnots = List.unmodifiable(twsColumnsKnots);

  /// A tengelyek a [samples] alapján: az erős szeles oszlop csak akkor
  /// kerül be, ha a vitorlázható sorokban elég ideje van.
  factory PolarBuildAxes.forSamples(Iterable<LabSample> samples) {
    final strongWindSeconds = strongWindSecondsOf(samples);
    return PolarBuildAxes(
      twsColumnsKnots: [
        ...baseTwsColumnsKnots,
        if (strongWindSeconds >= strongWindColumnMinimumSeconds)
          strongWindColumnKnots,
      ],
    );
  }

  /// Az alap TWS-oszlopok csomóban.
  static const List<double> baseTwsColumnsKnots = [
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    10,
    12,
    14,
    16,
    20,
  ];

  /// Az erős szeles oszlop csomóban.
  static const double strongWindColumnKnots = 25;

  /// Az erős szeles oszlop felvételéhez kellő mért idő (30 perc).
  static const int strongWindColumnMinimumSeconds = 30 * 60;

  /// E szél alatt a minta egyik oszlopba sem kerül.
  static const double minimumTwsKnots = 1;

  /// A TWA-sorok lépése fokban.
  static const int twaStepDegrees = 5;

  /// A TWA-sorok száma (0, 5, … 180).
  static const int twaRowCount = 180 ~/ twaStepDegrees + 1;

  /// Az első vitorlázható sor indexe (25°, `Polar.noGoThresholdDegrees`).
  static const int firstSailingTwaRow = 25 ~/ twaStepDegrees;

  /// A TWS-oszlopok csomóban, szigorúan növekvő sorrendben.
  final List<double> twsColumnsKnots;

  /// Van-e erős szeles oszlop.
  bool get hasStrongWindColumn => twsColumnsKnots.last == strongWindColumnKnots;

  /// A [row] indexű TWA-sor foka.
  static int twaDegreesOfRow(int row) => row * twaStepDegrees;

  /// A `|TWA|` ([absTwaDeg], 0–180) sora.
  static int twaRowOf(double absTwaDeg) => (absTwaDeg / twaStepDegrees).round();

  /// A [twsKnots] szél oszlopának indexe, vagy `null`, ha a szél nem véges
  /// vagy a [minimumTwsKnots] alatt van.
  int? twsColumnOf(double twsKnots) {
    if (!twsKnots.isFinite || twsKnots < minimumTwsKnots) return null;
    final last = twsColumnsKnots.length - 1;
    for (var column = 0; column < last; column++) {
      final boundary =
          (twsColumnsKnots[column] + twsColumnsKnots[column + 1]) / 2;
      if (twsKnots < boundary) return column;
    }
    return last;
  }

  /// A vitorlázható sorok mért ideje az erős szeles oszlop tartományában
  /// (az alap-tengely legfelső oszlopa és az erős szeles oszlop
  /// felezőpontja fölött), másodpercben.
  static int strongWindSecondsOf(Iterable<LabSample> samples) {
    final boundary = (baseTwsColumnsKnots.last + strongWindColumnKnots) / 2;
    var seconds = 0;
    for (final sample in samples) {
      if (twaRowOf(sample.absTwaDeg) < firstSailingTwaRow) continue;
      if (sample.twsKnots >= boundary) seconds += sample.seconds;
    }
    return seconds;
  }

  @override
  List<Object?> get props => [twsColumnsKnots];
}
