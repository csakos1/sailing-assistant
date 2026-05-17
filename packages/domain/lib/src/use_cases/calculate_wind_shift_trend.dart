import 'package:domain/src/_internal/angle_unwrap.dart';
import 'package:domain/src/_internal/linear_regression.dart';
import 'package:domain/src/entities/wind_observation.dart';
import 'package:domain/src/entities/wind_shift_confidence.dart';
import 'package:domain/src/entities/wind_shift_trend.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:meta/meta.dart';

/// Sliding-window lineáris regresszióval becsüli a wind-shift trend
/// rátáját és megbízhatóságát egy [WindObservation]-history-ból.
///
/// **Domain háttér.** Tour-race kontextusban a TWD (True Wind
/// Direction) folyamatosan változik — emelkedő (clockwise) vagy
/// süllyedő (counterclockwise) trend-tel. A vitorlázó a 7.5
/// `PredictTwaAtMark`-on keresztül ezt az becslést a következő bóya
/// felé tartó kurzus szempontjából értelmezi (lift vs header), és
/// kormányzási döntéseket hoz alapján.
///
/// **Pure-function design — Opció β (injektált `now`).** A [call]
/// minden iterációban kötelező [DateTime] paramétert vár, NEM belső
/// `DateTime.now()`. Ezáltal: (1) a 7.8 `ComputeMarkPrediction` egy
/// tick timestamp-jét csorgatja le minden függő use case-be, így egy
/// iteráción belül konzisztens időképpel dolgozunk; (2) a tesztek
/// determinisztikusak — a `now` fix value-val állítható, nincs
/// szükség Clock interface mock-ra; (3) a számítás idempotens.
///
/// **Null return — kétféle eset, ugyanaz a szemantika.** A use case
/// `null`-t ad vissza, ha (a) a `history` `now - window`
/// időintervallumában kevesebb mint `_minSampleCount` (=10) minta
/// van — "insufficient signal"; vagy (b) a regresszió degenerált
/// (slope vagy r² NaN: konstans-y vagy konstans-x input) —
/// "degenerate fit". Mindkettő ugyanazt jelenti a hívónak: nincs
/// használható trend most. A low confidence külön érték az enumban,
/// és nem keverhető a "nincs adat" esettel.
///
/// **Numerikus heavy-lift a `_internal/`-ben.** Az angle-unwrap és a
/// regresszió library-internal top-level függvények
/// (`_internal/angle_unwrap.dart`, `_internal/linear_regression.dart`),
/// külön unit-tesztelve. Ez a use case egy vékony orchestrator:
/// szűri az ablakot, hívja a két helpert, ellenőrzi az eredményt,
/// sávolja a konfidenciát, és összeállítja a `WindShiftTrend`-et.
@immutable
class CalculateWindShiftTrend {
  /// Const ctor — a use case stateless, példány-egyenlőség nem
  /// releváns; const-elve egyetlen instance is elég.
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
  /// shift-rátát, az r² értékéből a `WindShiftConfidence`-
  /// besorolást adja vissza.
  ///
  /// Pure-function — a [now] kötelező paraméter, NEM belső
  /// `DateTime.now()` hívás. A 7.8 `ComputeMarkPrediction` egy
  /// futási iteráció timestamp-jét csorgatja le minden függő use
  /// case-be, hogy a tick belsejében konzisztens időképpel
  /// dolgozzunk.
  ///
  /// @return WindShiftTrend ha legalább [_minSampleCount] (=10)
  /// minta esik az ablakba ÉS a regresszió jól értelmezett (sem
  /// slope, sem r² nem NaN); egyébként null. A null itt
  /// "insufficient/degenerate signal" jelentésű — a low confidence
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
    final (slope, rSquared) = linearRegression(
      recent.map((o) => o.timestamp.millisecondsSinceEpoch / 60000).toList(),
      unwrapped,
    );

    // Degenerált illesztés (konstans y → r² NaN; konstans x → slope
    // NaN) → null. Konzisztens a "nincs üres/invalid WindShiftTrend"
    // invariánssal.
    if (!slope.isFinite || !rSquared.isFinite) {
      return null;
    }

    // r² küszöbök → konfidencia-szintek.
    final confidence = switch (rSquared) {
      > 0.7 => WindShiftConfidence.high,
      > 0.4 => WindShiftConfidence.medium,
      _ => WindShiftConfidence.low,
    };

    return WindShiftTrend(
      shiftRateDegPerMinute: slope,
      currentTwd: Bearing.true_(unwrapped.last % 360),
      confidence: confidence,
      sampleCount: recent.length,
      windowDuration: window,
    );
  }
}
