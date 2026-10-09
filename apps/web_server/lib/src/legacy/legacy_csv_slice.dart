import 'package:equatable/equatable.dart';
import 'package:web_server/src/legacy/legacy_track_sample.dart';
import 'package:web_server/src/legacy/ydvr_csv_problem.dart';

/// Az első hibás `polar.csv`-sor: a sorszáma (a fejléc az 1.) és az oka.
typedef YdvrCsvLineProblem = ({int lineNumber, YdvrCsvRowProblem problem});

/// A `polar.csv` egy menetben kivágott ablakai (ADR 0050 D4 + Addendum 1
/// E3).
final class LegacyCsvSlice extends Equatable {
  /// Kivágás a versenyenkénti [tracks]-szel és a sorok számaival.
  const LegacyCsvSlice({
    required this.rowCount,
    required this.problemCount,
    required this.tracks,
    this.firstProblem,
  });

  /// A fejléc utáni nem üres sorok száma.
  final int rowCount;

  /// A kihagyott hibás sorok száma.
  final int problemCount;

  /// Az első hibás sor, vagy `null`, ha nem volt.
  final YdvrCsvLineProblem? firstProblem;

  /// A versenyek mintái időrendben; csak a legalább egy mintát kapott
  /// verseny szerepel.
  final Map<String, List<LegacyTrackSample>> tracks;

  @override
  List<Object?> get props => [rowCount, problemCount, firstProblem, tracks];
}
