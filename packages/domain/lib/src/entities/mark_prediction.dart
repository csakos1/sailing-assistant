import 'package:domain/src/entities/eta_source.dart';
import 'package:domain/src/entities/mark.dart';
import 'package:domain/src/entities/wind_shift_confidence.dart';
import 'package:domain/src/value_objects/angle.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:domain/src/value_objects/distance.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Egy időpillanatban számolt prediction-snapshot egy aktív bóyára.
///
/// A `ComputeMarkPrediction` composite use case (ARCHITECTURE.md 7.8)
/// állítja elő 1 Hz-en a UI számára, a `BoatState`, a `Race.activeMark`
/// és a `WindShiftTrend` aktuális értékéből. Számolt érték: nincs
/// identity-mezője, equality minden mezőn (Equatable). Kódfájl-
/// szervezés szempontjából az entitások közé tartozik
/// (ARCHITECTURE.md 5.2).
///
/// **Mezőkötelezettség és null-szemantika.** A számolás bemenetei
/// részlegesen hiányozhatnak, ezért egyes mezők nullable:
///
/// - [eta] és [predictedTwaAtMark] null, ha a számolás nem futott le
///   (SOG hiányzik / drift-szint alatti; trend hiányzik / low conf).
/// - [courseCorrection] null, ha a hajó effektív iránya
///   (`BoatState.effectiveDirection`) ismeretlen. Tudatos eltérés az
///   ARCHITECTURE.md 7.8 `Angle.zero()` fallback-mintájától: a `0°`
///   szemantikailag "perfekt course" jelentésű, és nem keverhető össze
///   a "nem tudjuk a heading-et" esettel. A UI így explicit különbséget
///   tehet, és nem a Warning-rendszerre vár szelektív decoration-hoz.
///
/// **Invariánsok (assert-tel kódolva).**
///
/// - [bearingToMark] trueNorth-referenciájú — két abszolút koordináta
///   közti bearing mindig trueNorth, és a downstream számítások
///   (`CalculateCourseCorrection`) ezt feltételezik.
/// - `eta == null ↔ etaSource == unknown` — két redundáns állapotból
///   egyetlen invariáns: ha nincs ETA, a forrás `unknown`; ha van, a
///   forrás `sog` (v1) vagy `polar` (v2). Exhaustive switch kódolja,
///   új `EtaSource` érték a fordítóhibával jelez.
@immutable
class MarkPrediction extends Equatable {
  /// Új snapshot. Az invariánsokat assertek ellenőrzik.
  MarkPrediction({
    required this.mark,
    required this.bearingToMark,
    required this.distanceToMark,
    required this.etaSource,
    required this.shiftConfidence,
    required this.calculatedAt,
    this.courseCorrection,
    this.eta,
    this.predictedTwaAtMark,
  }) : assert(
         bearingToMark.reference == BearingReference.trueNorth,
         'bearingToMark mező trueNorth-referenciájú Bearing-et tárol.',
       ),
       assert(
         _etaInvariantHolds(eta, etaSource),
         'eta == null ↔ etaSource == unknown invariáns sérült.',
       );

  /// Melyik bóyára vonatkozik a prediction.
  final Mark mark;

  /// Abszolút true bearing a bója felé, a hajó pozíciójából számolva.
  final Bearing bearingToMark;

  /// A hajó távolsága a bójától.
  final Distance distanceToMark;

  /// Szükséges irányváltoztatás a bója eléréséhez, signed
  /// (+ jobbra, – balra). `null`, ha a hajó effektív iránya
  /// (`BoatState.effectiveDirection`) ismeretlen.
  final Angle? courseCorrection;

  /// SOG-alapú (vagy v2-ben polár-alapú) ETA. `null`, ha nem
  /// számítható — lásd osztály-szintű null-szemantika.
  final Duration? eta;

  /// Az ETA számítás forrása. Az [eta] mezővel invariáns-csatolt.
  final EtaSource etaSource;

  /// A bóyán érkezéskor várható TWA, signed. `null`, ha nincs elég
  /// trend-adat vagy az ETA hiányzik.
  final Angle? predictedTwaAtMark;

  /// A wind-shift trend konfidenciája a számítás pillanatában.
  /// Default-ja [WindShiftConfidence.low], ha trend nem érhető el.
  final WindShiftConfidence shiftConfidence;

  /// A snapshot előállításának időbélyege.
  final DateTime calculatedAt;

  /// Az [eta] és [etaSource] redundáns állapot konzisztenciáját
  /// ellenőrzi. Exhaustive switch a fordítóhibára építve: új
  /// [EtaSource] érték bevezetésekor a switch is kényszerítve van.
  static bool _etaInvariantHolds(Duration? eta, EtaSource etaSource) {
    return switch (etaSource) {
      EtaSource.unknown => eta == null,
      EtaSource.sog || EtaSource.polar => eta != null,
    };
  }

  /// Immutable update. Simple-form: `null` paraméter "ne változtass"
  /// jelentéssel bír. A nullable mezők ([courseCorrection], [eta],
  /// [predictedTwaAtMark]) null-ra állításához új [MarkPrediction]
  /// kell — copyWith-tel nem érhető el.
  ///
  /// Figyelem: az [eta] és [etaSource] invariáns-csatolt — ha az
  /// egyiket változtatod, gondoskodj a párjáról is, különben a
  /// konstruktor assertje dob.
  MarkPrediction copyWith({
    Mark? mark,
    Bearing? bearingToMark,
    Distance? distanceToMark,
    EtaSource? etaSource,
    WindShiftConfidence? shiftConfidence,
    DateTime? calculatedAt,
    Angle? courseCorrection,
    Duration? eta,
    Angle? predictedTwaAtMark,
  }) {
    return MarkPrediction(
      mark: mark ?? this.mark,
      bearingToMark: bearingToMark ?? this.bearingToMark,
      distanceToMark: distanceToMark ?? this.distanceToMark,
      etaSource: etaSource ?? this.etaSource,
      shiftConfidence: shiftConfidence ?? this.shiftConfidence,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      courseCorrection: courseCorrection ?? this.courseCorrection,
      eta: eta ?? this.eta,
      predictedTwaAtMark: predictedTwaAtMark ?? this.predictedTwaAtMark,
    );
  }

  @override
  List<Object?> get props => [
    mark,
    bearingToMark,
    distanceToMark,
    etaSource,
    shiftConfidence,
    calculatedAt,
    courseCorrection,
    eta,
    predictedTwaAtMark,
  ];

  @override
  bool? get stringify => true;
}
