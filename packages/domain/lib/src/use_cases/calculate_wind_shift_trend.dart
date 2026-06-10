import 'package:domain/src/_internal/angle_unwrap.dart';
import 'package:domain/src/_internal/linear_regression.dart';
import 'package:domain/src/entities/wind_observation.dart';
import 'package:domain/src/entities/wind_shift_confidence.dart';
import 'package:domain/src/entities/wind_shift_trend.dart';
import 'package:domain/src/value_objects/bearing.dart';

/// Sliding-window lineáris regresszió a TWD-történetre: a slope adja a
/// szélfordulás rátáját, az r² a kapuzás-konfidenciát (ADR 0023 óta CSAK
/// az extrapolációs kapu), a reziduál-/meredekség-szórás pedig az ADR 0023
/// előrejelzési hibasáv (band) bemeneteit.
class CalculateWindShiftTrend {
  /// Const ctor — a use case stateless.
  const CalculateWindShiftTrend();

  /// Az ablakba eső minimum minta-szám, ami alatt nincs trend
  /// (insufficient signal → null return). A `windHistoryProvider`
  /// (ARCHITECTURE.md 8.3) downsample-eli a stream-et ~1/min ütemre,
  /// így 10 minta nagyjából 10 perces lefedettséget jelez egy
  /// 10 perces ablakon.
  static const int _minSampleCount = 10;

  /// Sliding-window lineáris regressziót illeszt a [history]-ben
  /// szereplő TWD-mintákra, amelyek a [now]-tól [window]-időre
  /// visszamenőleg esnek. A regresszió slope-jából a fok/perc
  /// shift-rátát, az r² értékéből a `WindShiftConfidence`-besorolást,
  /// a reziduál-/meredekség-szórásból pedig az ADR 0023 band-bemeneteit
  /// adja vissza.
  ///
  /// Pure-function — a [now] kötelező paraméter, NEM belső
  /// `DateTime.now()` hívás. A 7.8 `ComputeMarkPrediction` egy
  /// futási iteráció timestamp-jét csorgatja le minden függő use
  /// case-be, hogy a tick belsejében konzisztens időképpel
  /// dolgozzunk.
  ///
  /// @return WindShiftTrend ha legalább [_minSampleCount] (=10)
  /// minta esik az ablakba ÉS a regresszió jól értelmezett (sem
  /// slope, sem r², sem a std-hibák nem NaN); egyébként null. A null
  /// itt "insufficient/degenerate signal" jelentésű — a low confidence
  /// külön érték az enumban.
  WindShiftTrend? call({
    required List<WindObservation> history,
    required Duration window,
    required DateTime now,
  }) {
    final cutoff = now.subtract(window);
    final recent = history.where((o) => o.timestamp.isAfter(cutoff)).toList();

    if (recent.length < _minSampleCount) {
      return null;
    }

    // 359° → 1° unwrap a nyers TWD-sorozaton (lásd
    // _internal/angle_unwrap.dart).
    final unwrapped = unwrapAngles(recent.map((o) => o.twd.degrees).toList());

    // Lineáris regresszió: x = perc óta epoch, y = unwrap-elt TWD
    // (lásd _internal/linear_regression.dart).
    final reg = linearRegression(
      recent.map((o) => o.timestamp.millisecondsSinceEpoch / 60000).toList(),
      unwrapped,
    );

    // Degenerált illesztés (konstans y → r² NaN; konstans x → slope
    // NaN; n < 3 → std-hibák NaN) → null. Konzisztens a "nincs üres/
    // invalid WindShiftTrend" invariánssal.
    if (!reg.slope.isFinite ||
        !reg.rSquared.isFinite ||
        !reg.residualStdError.isFinite ||
        !reg.slopeStdError.isFinite) {
      return null;
    }

    // r² küszöbök → konfidencia-szintek (ADR 0023 óta: a kapu).
    final confidence = switch (reg.rSquared) {
      > 0.7 => WindShiftConfidence.high,
      > 0.4 => WindShiftConfidence.medium,
      _ => WindShiftConfidence.low,
    };

    // A regresszió idő-súlypontja: meanX perc-óta-epoch → UTC instant.
    // A band-horizont (7.5b) ehhez méri a jövőbeli érkezést.
    final meanSampleTime = DateTime.fromMillisecondsSinceEpoch(
      (reg.meanX * 60000).round(),
      isUtc: true,
    );

    return WindShiftTrend(
      shiftRateDegPerMinute: reg.slope,
      currentTwd: Bearing.true_(unwrapped.last % 360),
      confidence: confidence,
      sampleCount: recent.length,
      windowDuration: window,
      residualStdErrorDeg: reg.residualStdError,
      slopeStdErrorDegPerMin: reg.slopeStdError,
      meanSampleTime: meanSampleTime,
    );
  }
}
