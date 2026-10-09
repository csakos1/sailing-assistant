import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/polar/polar_stats.dart';
import 'package:race_archive_api/src/polar/race_polar_row.dart';

/// Egy szezon polár-táblázata (ADR 0049 D11, D12, Addendum 4 U7, U8).
final class SeasonPolarTable extends Equatable {
  /// Táblázat a [year] szezonhoz.
  const SeasonPolarTable({
    required this.year,
    required this.rows,
    required this.rankedCount,
    this.raceAverage,
    this.timeWeighted,
  });

  /// A szezon éve.
  final int year;

  /// A versenyek sorai dátum szerint növekvő sorrendben.
  final List<RacePolarRow> rows;

  /// A futamok átlaga sor; `null`, ha egy versenynek sincs mutatója.
  final PolarStats? raceAverage;

  /// Az időre súlyozott sor; `null`, ha egy versenynek sincs mutatója.
  final PolarStats? timeWeighted;

  /// Hány verseny kapott rangot.
  final int rankedCount;

  /// Igaz, ha valamelyik sor elavult vagy hiányzik: a szerver még
  /// frissít.
  bool get isStale =>
      rows.any((row) => row.cacheState != PolarCacheState.fresh);

  @override
  List<Object?> get props => [
    year,
    rows,
    raceAverage,
    timeWeighted,
    rankedCount,
  ];
}
