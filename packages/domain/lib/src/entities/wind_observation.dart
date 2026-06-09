import 'package:domain/src/entities/twd_quality.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Egy időpillanatban érzékelt true wind direction (TWD) snapshot a
/// wind-shift trend történethez.
///
/// A `CalculateWindShiftTrend` use case (ARCHITECTURE.md 7.4) az
/// observation-sorozatból sliding-window lineáris regressziót számol,
/// amely a wind-shift fokokban/perc rátáját és r² alapú konfidenciát
/// ad. A `windHistoryProvider` (ARCHITECTURE.md 8.3) gyűjti a
/// `WindData`-stream-ből, ablakozva 30 perces puffert tart.
///
/// **Minimalista mező-tartalom.** Csak [twd] és [timestamp]; a
/// sebesség és AWA/AWS adatok nem tartoznak ide — azokat a Telemetry-
/// réteg (Phase 3+) tartja nyilván logging-célra. A wind-shift trendhez
/// csak a TWD-történet kell.
///
/// **Invariáns:** [twd] trueNorth-referenciájú — a "True Wind
/// Direction" definíció szerint abszolút (north-referenced) érték.
///
/// A `WindObservation.fromWindData(WindData, BoatState)` named factory
/// Phase 4-re halasztva — a `windHistoryProvider` (ARCHITECTURE.md
/// 8.3) implementációjával együtt. A "nullable vs Result" return-
/// döntés akkor születik; részletes kontextus: `docs/deferred.md`.
// TODO(phase-4): WindObservation.fromWindData(WindData, BoatState) named
// factory hozzáadása a windHistoryProvider mellé; lásd docs/deferred.md
@immutable
class WindObservation extends Equatable {
  /// Új TWD observation. Az invariánst assert ellenőrzi.
  WindObservation({
    required this.twd,
    required this.timestamp,
    this.twdQuality = TwdQuality.live,
  }) : assert(
         twd.reference == BearingReference.trueNorth,
         'twd mező trueNorth-referenciájú Bearing-et tárol.',
       );

  /// True Wind Direction abszolút bearing. trueNorth-referenciájú.
  final Bearing twd;

  /// A megfigyelés időbélyege.
  final DateTime timestamp;

  /// A derivált TWD minősége (live / held / unavailable). Alap: live.
  final TwdQuality twdQuality;

  /// Immutable update. Simple-form: `null` paraméter "ne változtass"
  /// jelentéssel bír.
  WindObservation copyWith({
    Bearing? twd,
    DateTime? timestamp,
    TwdQuality? twdQuality,
  }) {
    return WindObservation(
      twd: twd ?? this.twd,
      timestamp: timestamp ?? this.timestamp,
      twdQuality: twdQuality ?? this.twdQuality,
    );
  }

  @override
  List<Object?> get props => [twd, timestamp, twdQuality];

  @override
  bool? get stringify => true;
}
