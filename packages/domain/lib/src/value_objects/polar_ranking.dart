import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// A versenyek rangja egy szezonban (ADR 0049 D9, Addendum 3 T6).
@immutable
class PolarRanking extends Equatable {
  /// Rangsor a [ranks] térképből: versenyazonosító → rang (1 a legjobb).
  PolarRanking(Map<String, int> ranks) : ranks = Map.unmodifiable(ranks);

  /// A rangot kapott versenyek rangja.
  final Map<String, int> ranks;

  /// Hány verseny kapott rangot.
  int get rankedCount => ranks.length;

  /// A [raceId] verseny rangja; `null`, ha nem kapott rangot.
  int? rankOf(String raceId) => ranks[raceId];

  @override
  List<Object?> get props => [ranks];
}
