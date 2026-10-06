import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/polar/race_polar_row.dart';

/// Egy verseny polár-blokkja a részletezőhöz (ADR 0049 D12, D14,
/// Addendum 4 U7).
final class RacePolarDetail extends Equatable {
  /// Részletező a [row] sorral.
  const RacePolarDetail({required this.row, required this.rankedCount});

  /// A verseny sora, a szezonbeli ranggal.
  final RacePolarRow row;

  /// Hány verseny kapott rangot a szezonban (pl. „4. / 8").
  final int rankedCount;

  @override
  List<Object?> get props => [row, rankedCount];
}
