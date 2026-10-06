import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/polar/polar_stats.dart';

/// Egy szezon időre súlyozott polár-sora az „Összes év" nézethez (ADR
/// 0049 D12, D14, Addendum 4 U7).
final class SeasonPolarSummary extends Equatable {
  /// Összesítés a [year] szezonhoz.
  const SeasonPolarSummary({
    required this.year,
    required this.raceCount,
    this.timeWeighted,
  });

  /// A szezon éve.
  final int year;

  /// Hány versenynek van mutatója.
  final int raceCount;

  /// Az időre súlyozott sor; `null`, ha egy versenynek sincs mutatója.
  final PolarStats? timeWeighted;

  @override
  List<Object?> get props => [year, raceCount, timeWeighted];
}
