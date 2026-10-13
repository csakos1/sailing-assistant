import 'package:domain/src/_internal/centered_rolling_median.dart';
import 'package:domain/src/value_objects/polar_performance_rules.dart';
import 'package:domain/src/value_objects/polar_sample.dart';
import 'package:meta/meta.dart';

/// A polár-minták szélsebesség-tüskéinek jelölése (ADR 0049 Addendum 3 T3).
///
/// Egy minta tüske, ha a TWS-e a köré igazított csúszó ablak alsó
/// mediánjától több mint [PolarPerformanceRules.spikeThresholdKnots]
/// csomóval eltér. Az ablak [PolarPerformanceRules.spikeWindowSize] elemű,
/// és csak az érvényes TWS-sel bíró mintákon csúszik. A TWS nélküli vagy
/// érvénytelen TWS-ű minta nem tüske: azt a hívó adat-feltétele zárja ki.
///
/// **Pure use case.** A mintáknak időrendben kell jönniük (a
/// `PolarSampleReader` szerződése), mert a szűrő a szomszédokat nézi. A
/// `SummarizePolarPerformance` és a polár-elemzés ugyanezt a szűrőt
/// használja, hogy ugyanazok a minták essenek ki.
@immutable
class FlagTwsSpikes {
  /// Const konstruktor — a use case stateless.
  const FlagTwsSpikes();

  /// Mintánként: tüske-e a TWS-e. Az eredmény ugyanolyan hosszú, mint a
  /// [samples], és ugyanabban a sorrendben jön.
  List<bool> call(List<PolarSample> samples) {
    final indices = <int>[];
    final speeds = <double>[];
    for (final (index, sample) in samples.indexed) {
      final tws = sample.twsMps;
      if (tws != null && tws.isFinite && tws >= 0) {
        indices.add(index);
        speeds.add(tws / _metersPerSecondPerKnot);
      }
    }
    final medians = centeredRollingMedians(
      speeds,
      windowSize: PolarPerformanceRules.spikeWindowSize,
    );
    final flags = List.filled(samples.length, false);
    for (final (position, index) in indices.indexed) {
      final deviation = (speeds[position] - medians[position]).abs();
      flags[index] = deviation > PolarPerformanceRules.spikeThresholdKnots;
    }
    return flags;
  }
}

/// 1 csomó = 1852 m / 3600 s.
const double _metersPerSecondPerKnot = 1852 / 3600;
