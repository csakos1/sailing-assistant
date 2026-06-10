import 'package:domain/src/entities/wind_shift_confidence.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Wind-shift trend snapshot, melyet a `CalculateWindShiftTrend` use
/// case (ARCHITECTURE.md 7.4) számol egy adott [windowDuration]
/// ablakra sliding-window lineáris regresszióval. A regresszió slope-ja
/// adja a TWD változási rátáját, az r² értéke a kapuzás-konfidenciát,
/// a reziduál- és meredekség-szórás pedig az ADR 0023 előrejelzési
/// hibasáv (band) bemeneteit.
///
/// **Pozitív [shiftRateDegPerMinute] óramutató járásával egyező
/// (clockwise) forgást jelez** (pl. É → ÉK → K → DK), negatív érték
/// counterclockwise (right-hand-shift vs left-hand-shift szempontból
/// a hajó halzája dönti el a "lift/header" interpretációt — ezt a 7.5
/// `PredictTwaAtMark` és a UI réteg dolgozza fel).
///
/// A [currentTwd] az ablak utolsó TWD-mintájának normalizált
/// (`[0, 360)`) értéke. A UI ezt jeleníti meg jelenlegi szélirány-ként,
/// a 7.5 `PredictTwaAtMark` pedig ezt veszi az extrapoláció kiindulási
/// pontjának (`predictedTwd = currentTwd + shiftRate * timeToMark`).
///
/// **A [confidence] (r²) az ADR 0023 óta KIZÁRÓLAG az extrapolációs
/// kapu** (7.5: low → nincs extrapoláció). A *megjelenített* UI-bizalmat
/// az előrejelzési hibasáv adja (7.5b `EstimatePredictionConfidence`),
/// ami a [residualStdErrorDeg]-ból, a [slopeStdErrorDegPerMin]-ból és a
/// horizon-ból képződik.
///
/// A [sampleCount] és [windowDuration] elsősorban diagnosztika célt
/// szolgál: UI tooltip ("trend X perc / Y minta alapján"), telemetria-
/// log, és pl. a Warning rendszer küszöb-ellenőrzései.
///
/// **Regresszió-statisztikák (ADR 0023).**
/// - [residualStdErrorDeg]: a regresszió körüli reziduál-szórás fokban
///   (`s`). Stabil, jól illeszkedő szélnél kicsi.
/// - [slopeStdErrorDegPerMin]: a meredekség standard hibája fok/perc-ben
///   (`slopeSE`). A horizonttal szorozva adja a band slope-bizonytalansági
///   tagját.
/// - [meanSampleTime]: a regresszió idő-súlypontja (az x-átlag
///   visszafejtve DateTime-má, UTC instant). A band horizontja ehhez
///   méri a jövőbeli érkezést: `h = (now + effectiveEta) − meanSampleTime`.
///
/// **Invariánsok** (assert):
/// - [currentTwd] trueNorth-referenciájú — a TWD a definíció szerint
///   north-referenced abszolút irány.
/// - [sampleCount] >= 0 — a regresszióba bemenő minta-pontok száma.
/// - [windowDuration] > Duration.zero — pozitív ablak.
/// - [shiftRateDegPerMinute] véges (nem NaN, nem ±∞) — a 7.4 use case
///   szűri ki a konstans-y és degenerált eseteket, mielőtt ezt az
///   entitást konstruálná.
/// - [residualStdErrorDeg] és [slopeStdErrorDegPerMin] véges, nem-negatív
///   — a 7.4 a degenerált (NaN) regressziót már kiszűrte.
///
/// **Insufficient-sample szemantika:** ha az ablakban a 7.4 küszöbe
/// (default 10) alatti minta esik, a use case `null`-t ad vissza és
/// nem konstruálja ezt az entitást. Nem létezik "üres/invalid"
/// `WindShiftTrend` állapot. Konzisztens a 7.3 `CourseCorrection` és
/// a 7.6 ETA nullable-return mintájával.
@immutable
class WindShiftTrend extends Equatable {
  /// Új trend snapshot. Az invariánsokat assert-ek ellenőrzik.
  WindShiftTrend({
    required this.shiftRateDegPerMinute,
    required this.currentTwd,
    required this.confidence,
    required this.sampleCount,
    required this.windowDuration,
    required this.residualStdErrorDeg,
    required this.slopeStdErrorDegPerMin,
    required this.meanSampleTime,
  }) : assert(
         currentTwd.reference == BearingReference.trueNorth,
         'currentTwd trueNorth-referenciájú Bearing-et tárol (TWD).',
       ),
       assert(sampleCount >= 0, 'sampleCount nem lehet negatív.'),
       assert(
         windowDuration > Duration.zero,
         'windowDuration pozitív Duration-t tárol.',
       ),
       assert(
         shiftRateDegPerMinute.isFinite,
         'shiftRateDegPerMinute véges szám (nem NaN, nem ±∞).',
       ),
       assert(
         residualStdErrorDeg.isFinite && residualStdErrorDeg >= 0,
         'residualStdErrorDeg véges, nem-negatív fok.',
       ),
       assert(
         slopeStdErrorDegPerMin.isFinite && slopeStdErrorDegPerMin >= 0,
         'slopeStdErrorDegPerMin véges, nem-negatív fok/perc.',
       );

  /// Az ablakra illesztett lineáris regresszió slope-ja fok/perc
  /// egységben. Pozitív érték óramutató-irány szerinti (clockwise)
  /// forgás, negatív érték counterclockwise.
  final double shiftRateDegPerMinute;

  /// Az ablak utolsó TWD-mintája `[0, 360)`-ra normalizálva. A 7.4
  /// use case az unwrap-elt sorozat utolsó elemén végez `% 360`
  /// műveletet a konstrukció előtt.
  final Bearing currentTwd;

  /// r²-alapú besorolás. Az ADR 0023 óta CSAK az extrapolációs kapu
  /// (7.5): low (r² ≤ 0.4) → nincs extrapoláció. A UI-bizalom a band-ből
  /// jön, nem ebből.
  final WindShiftConfidence confidence;

  /// A regresszióba bemenő minta-pontok száma. A 7.4 `_minSampleCount`
  /// küszöb (default 10) alatt nincs trend (a use case null-t ad).
  final int sampleCount;

  /// Az ablak hossza, amit a hívó (8.3 `windShiftTrendProvider`) ad át a
  /// use case-nek. Általában 10 perc Lake Balaton-os tour-race
  /// kontextusban; egyelőre in-memory konstans (ADR 0010 D3 / 0011 D1).
  final Duration windowDuration;

  /// Reziduál-szórás fokban (`s`) — a band reziduum-tagja (ADR 0023).
  final double residualStdErrorDeg;

  /// A meredekség standard hibája fok/perc-ben (`slopeSE`) — a band
  /// slope-bizonytalansági tagja a horizonttal szorozva (ADR 0023).
  final double slopeStdErrorDegPerMin;

  /// A regresszió idő-súlypontja (x-átlag DateTime-má fejtve, UTC
  /// instant) — a band horizontjának referenciapontja (ADR 0023).
  final DateTime meanSampleTime;

  /// Immutable update. Simple-form: `null` paraméter "ne változtass"
  /// jelentéssel bír. Mivel a [WindShiftTrend] számolt érték, ezt
  /// elsősorban tesztekben használjuk (egy-mező variációk
  /// expressziójához); production kódban a use case mindig új instance-t
  /// konstruál.
  WindShiftTrend copyWith({
    double? shiftRateDegPerMinute,
    Bearing? currentTwd,
    WindShiftConfidence? confidence,
    int? sampleCount,
    Duration? windowDuration,
    double? residualStdErrorDeg,
    double? slopeStdErrorDegPerMin,
    DateTime? meanSampleTime,
  }) {
    return WindShiftTrend(
      shiftRateDegPerMinute:
          shiftRateDegPerMinute ?? this.shiftRateDegPerMinute,
      currentTwd: currentTwd ?? this.currentTwd,
      confidence: confidence ?? this.confidence,
      sampleCount: sampleCount ?? this.sampleCount,
      windowDuration: windowDuration ?? this.windowDuration,
      residualStdErrorDeg: residualStdErrorDeg ?? this.residualStdErrorDeg,
      slopeStdErrorDegPerMin:
          slopeStdErrorDegPerMin ?? this.slopeStdErrorDegPerMin,
      meanSampleTime: meanSampleTime ?? this.meanSampleTime,
    );
  }

  @override
  List<Object?> get props => [
    shiftRateDegPerMinute,
    currentTwd,
    confidence,
    sampleCount,
    windowDuration,
    residualStdErrorDeg,
    slopeStdErrorDegPerMin,
    meanSampleTime,
  ];

  @override
  bool? get stringify => true;
}
