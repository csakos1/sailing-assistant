import 'dart:math' as math;

import 'package:domain/src/entities/wind_shift_confidence.dart';
import 'package:meta/meta.dart';

/// A next-TWA predikció előrejelzési hibasávját (band, fokban) és az
/// abból képzett UI-konfidenciát számolja (ADR 0023, ARCHITECTURE.md
/// 7.5b).
///
/// **Miért ez, és nem az r².** Az r² összemossa a stabil (megbízható,
/// alacsony r²) és a zajos (megbízhatatlan, alacsony r²) szelet, és vak
/// az ETA-horizontra. A fokban kifejezett band ezzel szemben azt mondja
/// meg, hogy a predikció *mennyit tévedhet* az érkezés pillanatában — ez
/// a "mikor bízhatok" kérdés egyenes válasza.
///
/// **Képlet.** `band = sqrt(s² + (slopeSE · hPerc)²)`, ahol
/// - `s` = `residualStdErrorDeg`, a regresszió reziduál-szórása fokban,
/// - `slopeSE` = `slopeStdErrorDegPerMin`, a meredekség standard hibája
///   fok/perc-ben,
/// - `hPerc` = a `horizon` percben — a regresszió idő-súlypontjától az
///   érkezésig: `(now + effectiveEta) − meanSampleTime`.
///
/// A hívó (7.5 `PredictTwaAtMark`) a kapuzott (low r²) ágon
/// `horizon`-ként `Duration.zero`-t ad → `band = s` (a slope-tag eltűnik,
/// hisz nem extrapolálunk). A friss/ugráló ablak így magától low-ra esik:
/// rövid ablakon a `slopeSE` nagy, és a band azonnal kinő — nincs külön
/// debounce.
///
/// **Pure use case**: nincs állapot, idempotens, side effect mentes.
@immutable
class EstimatePredictionConfidence {
  /// Const ctor — a use case stateless.
  const EstimatePredictionConfidence();

  /// E sáv (fok) alatt: high. A 2026-06-06 logon kalibrált default;
  /// jelenleg in-memory konstans (mint a trend-ablak, ADR 0011 D1).
  static const double _highBandMaxDeg = 6;

  /// E sáv (fok) alatt: medium; felette: low.
  static const double _mediumBandMaxDeg = 15;

  /// A [horizon] hosszra vetített előrejelzési hibasávot (fokban) és a
  /// belőle bucketelt [WindShiftConfidence]-t adja vissza.
  ///
  /// NaN bemenet (degenerált regresszió) → NaN band → minden relációs
  /// minta hamis → low (defenzív, soha nem hazudik high-ot).
  ({double bandDegrees, WindShiftConfidence confidence}) call({
    required double residualStdErrorDeg,
    required double slopeStdErrorDegPerMin,
    required Duration horizon,
  }) {
    final hPerc = horizon.inMicroseconds / Duration.microsecondsPerMinute;
    final slopeTerm = slopeStdErrorDegPerMin * hPerc;
    final bandDegrees = math.sqrt(
      residualStdErrorDeg * residualStdErrorDeg + slopeTerm * slopeTerm,
    );

    final confidence = switch (bandDegrees) {
      <= _highBandMaxDeg => WindShiftConfidence.high,
      <= _mediumBandMaxDeg => WindShiftConfidence.medium,
      _ => WindShiftConfidence.low,
    };

    return (bandDegrees: bandDegrees, confidence: confidence);
  }
}
