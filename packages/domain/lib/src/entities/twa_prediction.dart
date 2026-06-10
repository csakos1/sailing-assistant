import 'package:domain/src/entities/wind_shift_confidence.dart';
import 'package:domain/src/value_objects/angle.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// A 7.5 `PredictTwaAtMark` számolt eredménye: a következő bóya
/// elérésekor várható TWA, a hozzá tartozó előrejelzési hibasáv (band)
/// és a belőle képzett UI-konfidencia (ADR 0023).
///
/// Külön value object (nem csupasz record), mert domain-eredmény-határ:
/// a 7.8 `ComputeMarkPrediction` bontja szét a `MarkPrediction` mezőire.
/// A nevezett típus dokumentálja a szemantikát, assert-tel védi a band
/// invariánsát, és Equatable-egyenlőséget ad a tesztekhez — a kódbázis
/// `WindShiftTrend` / `MarkPrediction` mintájával összhangban. A band-
/// matek belső lépése (7.5b `EstimatePredictionConfidence`) ezzel
/// szemben record-kimenetű marad (library-internal).
///
/// **Invariáns** (assert): [bandDegrees] véges, nem-negatív fok.
@immutable
class TwaPrediction extends Equatable {
  /// Új predikció-eredmény. A band-invariánst assert ellenőrzi.
  TwaPrediction({
    required this.twa,
    required this.bandDegrees,
    required this.confidence,
  }) : assert(
         bandDegrees.isFinite && bandDegrees >= 0,
         'bandDegrees véges, nem-negatív fok.',
       );

  /// A következő szárhoz mért, előjeles TWA (`[-180, +180)`).
  final Angle twa;

  /// Az előrejelzési hibasáv fokban (`±bandDegrees`). 0, ha a regresszió
  /// reziduum-szórása és slope-bizonytalansága is 0 (perfekt illesztés).
  final double bandDegrees;

  /// A [bandDegrees]-ból bucketelt megjelenítési konfidencia (ADR 0023).
  final WindShiftConfidence confidence;

  @override
  List<Object?> get props => [twa, bandDegrees, confidence];

  @override
  bool? get stringify => true;
}
