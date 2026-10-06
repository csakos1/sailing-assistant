import 'package:domain/src/_internal/centered_rolling_median.dart';
import 'package:domain/src/entities/polar.dart';
import 'package:domain/src/use_cases/lookup_target_speed.dart';
import 'package:domain/src/value_objects/polar_bucket.dart';
import 'package:domain/src/value_objects/polar_performance.dart';
import 'package:domain/src/value_objects/polar_performance_rules.dart';
import 'package:domain/src/value_objects/polar_sample.dart';
import 'package:domain/src/value_objects/stw_correction.dart';
import 'package:meta/meta.dart';

/// Egy futam polár-teljesítménye a mintáiból (ADR 0049 D7, D8, D10,
/// Addendum 3 T2–T5).
///
/// Egy minta akkor számít, ha a TWA, a TWS és az STW megvan, véges és a
/// sebességek nem negatívak; a TWS nem tüske (T3); és a polárnak van
/// pozitív cél-STW-je ehhez a szélhez (a no-go zónát a
/// [LookupTargetSpeed] `null`-ja zárja ki). A teljesítmény
/// `100 × korrigált STW / cél-STW`.
///
/// **Pure use case**: nincs állapot. A mintáknak időrendben kell jönniük
/// (a `PolarSampleReader` szerződése), mert a tüske-szűrő és a legjobb
/// 5 mp szomszédos mintákat néz. A tüske-szűrő minden TWS-sel bíró mintán
/// fut, a többi feltételtől függetlenül.
@immutable
class SummarizePolarPerformance {
  /// Use case a [lookupTargetSpeed] polár-lookuppal; a phone ugyanezt
  /// használja, hogy a web és az app %-a ugyanazt jelentse (D5).
  const SummarizePolarPerformance({
    LookupTargetSpeed lookupTargetSpeed = const LookupTargetSpeed(),
  }) : _lookupTargetSpeed = lookupTargetSpeed;

  final LookupTargetSpeed _lookupTargetSpeed;

  /// A [samples] teljesítménye a [polar]-hoz mérve, a [stwCorrections]
  /// szorzóival korrigált STW-vel.
  PolarPerformance call({
    required List<PolarSample> samples,
    required Polar polar,
    required List<StwCorrection> stwCorrections,
  }) {
    final spikes = _spikeFlags(samples);
    final accumulator = _Accumulator();
    for (final (index, sample) in samples.indexed) {
      final pct = spikes[index]
          ? null
          : _performancePct(sample, polar, stwCorrections);
      if (pct == null) {
        accumulator.reject();
      } else {
        accumulator.accept(sample, pct);
      }
    }
    return accumulator.build();
  }

  // A minta teljesítmény-%-a, vagy `null`, ha nem polár-minta (D7).
  double? _performancePct(
    PolarSample sample,
    Polar polar,
    List<StwCorrection> corrections,
  ) {
    final twa = sample.twaDeg;
    final tws = sample.twsMps;
    final stw = sample.stwMps;
    if (twa == null || tws == null || stw == null) return null;
    if (!twa.isFinite || !_isValidSpeed(tws) || !_isValidSpeed(stw)) {
      return null;
    }
    final target = _lookupTargetSpeed(
      polar: polar,
      twaDegrees: twa,
      twsKnots: _knotsOf(tws),
    );
    if (target == null || target <= 0) return null;
    final correctedStw = correctStw(stw, sample.timestamp, corrections);
    return 100 * _knotsOf(correctedStw) / target;
  }

  // Mintánként: tüske-e a TWS-e (T3). A TWS nélküli minta nem tüske; azt
  // a D7 hiányzó-adat feltétele zárja ki.
  List<bool> _spikeFlags(List<PolarSample> samples) {
    final indices = <int>[];
    final speeds = <double>[];
    for (final (index, sample) in samples.indexed) {
      final tws = sample.twsMps;
      if (tws != null && _isValidSpeed(tws)) {
        indices.add(index);
        speeds.add(_knotsOf(tws));
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

  static bool _isValidSpeed(double metersPerSecond) =>
      metersPerSecond.isFinite && metersPerSecond >= 0;
}

/// 1 csomó = 1852 m / 3600 s.
const double _metersPerSecondPerKnot = 1852 / 3600;

double _knotsOf(double metersPerSecond) =>
    metersPerSecond / _metersPerSecondPerKnot;

// A futam összegeinek gyűjtője. Az időrendi bejárás közben a legjobb 5 mp
// futamát is követi (T4).
class _Accumulator {
  int _measuredSeconds = 0;
  double _pctSecondsSum = 0;
  double _twsMpsSecondsSum = 0;
  final Map<int, int> _histogram = {};
  final Map<int, PolarBucket> _buckets = {};
  double? _bestRunPct;

  // Az aktuális hézagmentes futam utolsó legfeljebb öt %-a és az utolsó
  // minta egész másodperce.
  final List<double> _run = [];
  int? _lastSecond;

  void accept(PolarSample sample, double pct) {
    final seconds = sample.durationSeconds;
    // A `!` biztonságos: elfogadott mintának van TWS-e (D7).
    final twsMps = sample.twsMps!;
    _measuredSeconds += seconds;
    _pctSecondsSum += pct * seconds;
    _twsMpsSecondsSum += twsMps * seconds;
    _histogram.update(
      _binOf(pct),
      (value) => value + seconds,
      ifAbsent: () => seconds,
    );
    final bucketSample = PolarBucket(
      seconds: seconds,
      pctSecondsSum: pct * seconds,
    );
    _buckets.update(
      _bucketOf(twsMps),
      (bucket) => bucket + bucketSample,
      ifAbsent: () => bucketSample,
    );
    _extendRun(sample, pct);
  }

  void reject() {
    _run.clear();
    _lastSecond = null;
  }

  PolarPerformance build() => PolarPerformance(
    measuredSeconds: _measuredSeconds,
    pctSecondsSum: _pctSecondsSum,
    twsMpsSecondsSum: _twsMpsSecondsSum,
    histogram: _histogram,
    buckets: _buckets,
    bestFiveSecondsPct: _bestRunPct,
  );

  // A legjobb 5 mp csak 1 másodperces mintákból áll (T4).
  void _extendRun(PolarSample sample, double pct) {
    if (sample.durationSeconds != 1) {
      reject();
      return;
    }
    final second = sample.timestamp.millisecondsSinceEpoch ~/ 1000;
    final lastSecond = _lastSecond;
    if (lastSecond == null || second != lastSecond + 1) _run.clear();
    _lastSecond = second;
    _run.add(pct);
    if (_run.length > PolarPerformanceRules.bestRunSeconds) _run.removeAt(0);
    if (_run.length == PolarPerformanceRules.bestRunSeconds) {
      final average = _run.reduce((sum, value) => sum + value) / _run.length;
      final best = _bestRunPct;
      if (best == null || average > best) _bestRunPct = average;
    }
  }

  static int _binOf(double pct) {
    final bin = (pct * PolarPerformanceRules.binsPerPercent).floor();
    return bin > PolarPerformanceRules.overflowBin
        ? PolarPerformanceRules.overflowBin
        : bin;
  }

  static int _bucketOf(double twsMps) =>
      (_knotsOf(twsMps) / PolarPerformanceRules.windBucketKnots).floor();
}
