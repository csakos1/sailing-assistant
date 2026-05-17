import 'package:domain/src/entities/wind_shift_confidence.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Wind-shift trend snapshot, melyet a `CalculateWindShiftTrend` use
/// case (ARCHITECTURE.md 7.4) számol egy adott [windowDuration]
/// ablakra sliding-window lineáris regresszióval. A regresszió slope-ja
/// adja a TWD változási rátáját, az r² értéke pedig a konfidencia-
/// besorolást.
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
/// A [sampleCount] és [windowDuration] elsősorban diagnosztika célt
/// szolgál: UI tooltip ("trend X perc / Y minta alapján"), telemetria-
/// log, és pl. a Warning rendszer küszöb-ellenőrzései.
///
/// **Invariánsok** (assert):
/// - [currentTwd] trueNorth-referenciájú — a TWD a definíció szerint
///   north-referenced abszolút irány.
/// - [sampleCount] >= 0 — a regresszióba bemenő minta-pontok száma.
/// - [windowDuration] > Duration.zero — pozitív ablak.
/// - [shiftRateDegPerMinute] véges (nem NaN, nem ±∞) — a 7.4 use case
///   szűri ki a konstans-y és degenerált eseteket, mielőtt ezt az
///   entitást konstruálná.
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
       );

  /// Az ablakra illesztett lineáris regresszió slope-ja fok/perc
  /// egységben. Pozitív érték óramutató-irány szerinti (clockwise)
  /// forgás, negatív érték counterclockwise.
  final double shiftRateDegPerMinute;

  /// Az ablak utolsó TWD-mintája `[0, 360)`-ra normalizálva. A 7.4
  /// use case az unwrap-elt sorozat utolsó elemén végez `% 360`
  /// műveletet a konstrukció előtt.
  final Bearing currentTwd;

  /// r²-alapú konfidencia-besorolás. A 7.4 küszöbök: r² > 0.7 → high,
  /// r² > 0.4 → medium, egyébként → low.
  final WindShiftConfidence confidence;

  /// A regresszióba bemenő minta-pontok száma. A 7.4 `_minSampleCount`
  /// küszöb (default 10) alatt nincs trend (a use case null-t ad).
  final int sampleCount;

  /// Az ablak hossza, amit a hívó (8.3 `windShiftWindowSettingProvider`)
  /// ad át a use case-nek. Általában 10 perc Lake Balaton-os tour-race
  /// kontextusban; settings-vezérelt, hogy a felhasználó hangolhassa
  /// a verseny során.
  final Duration windowDuration;

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
  }) {
    return WindShiftTrend(
      shiftRateDegPerMinute:
          shiftRateDegPerMinute ?? this.shiftRateDegPerMinute,
      currentTwd: currentTwd ?? this.currentTwd,
      confidence: confidence ?? this.confidence,
      sampleCount: sampleCount ?? this.sampleCount,
      windowDuration: windowDuration ?? this.windowDuration,
    );
  }

  @override
  List<Object?> get props => [
    shiftRateDegPerMinute,
    currentTwd,
    confidence,
    sampleCount,
    windowDuration,
  ];

  @override
  bool? get stringify => true;
}
