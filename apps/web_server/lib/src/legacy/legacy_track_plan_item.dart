import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:web_server/src/legacy/legacy_track_sample.dart';
import 'package:web_server/src/web_db/manual_race_record.dart';

/// Egy kézi verseny a track-import tervében (ADR 0050 D4 + Addendum 1
/// E4).
///
/// Sealed, hogy a kiírás és a végrehajtás kimerítő `switch`-csel döntsön.
sealed class LegacyTrackPlanItem extends Equatable {
  const LegacyTrackPlanItem(this.race);

  /// A kézi verseny.
  final ManualRaceRecord race;
}

/// Track kerül fel: a hivatalos ablak mintái.
final class PlannedLegacyTrack extends LegacyTrackPlanItem {
  /// Track a [window] ablakból a [samples] mintákkal.
  const PlannedLegacyTrack(
    super.race, {
    required this.window,
    required this.samples,
    required this.coverage,
    required this.distanceMeters,
  });

  /// A hivatalos ablak.
  final TimeWindow window;

  /// A minták időrendben.
  final List<LegacyTrackSample> samples;

  /// A lefedettség `[0, 1]`-ben: mintaszám × 10 mp ÷ az ablak hossza,
  /// legfeljebb 1 (E4).
  final double coverage;

  /// A pozíciókból számolt táv méterben (haversine, mint a telefonon).
  final double? distanceMeters;

  @override
  List<Object?> get props => [race, window, samples, coverage, distanceMeters];
}

/// Nincs track: a kézi versenynek nincs hivatalos ablaka (D2).
final class LegacyTrackWithoutWindow extends LegacyTrackPlanItem {
  /// A [race] hivatalos ablak nélkül.
  const LegacyTrackWithoutWindow(super.race);

  @override
  List<Object?> get props => [race];
}

/// Nincs track: az ablakban kettőnél kevesebb pozíció van (D4).
final class LegacyTrackTooShort extends LegacyTrackPlanItem {
  /// A [race] a [window] ablakában [sampleCount] mintával, ebből
  /// [positionCount] pozícióval.
  const LegacyTrackTooShort(
    super.race, {
    required this.window,
    required this.sampleCount,
    required this.positionCount,
  });

  /// A hivatalos ablak.
  final TimeWindow window;

  /// Az ablakba eső minták száma.
  final int sampleCount;

  /// Ebből a pozíciós minták száma.
  final int positionCount;

  @override
  List<Object?> get props => [race, window, sampleCount, positionCount];
}
