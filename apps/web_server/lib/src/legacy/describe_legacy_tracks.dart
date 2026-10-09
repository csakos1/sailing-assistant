import 'package:web_server/src/legacy/legacy_csv_slice.dart';
import 'package:web_server/src/legacy/legacy_track_applier.dart';
import 'package:web_server/src/legacy/legacy_track_plan_item.dart';
import 'package:web_server/src/legacy/ydvr_csv_problem.dart';

/// A lefedettség, amely alatt a próbafuttatás figyelmeztet (ADR 0050 D4).
const double legacyCoverageWarningThreshold = 0.8;

/// A CSV kivágásának és a tervnek a kiírása a próbafuttatáshoz (ADR 0050
/// D4 + Addendum 1 E3, E4).
///
/// Versenyenként a mintaszám, a lefedettség, a pozíciókból számolt táv és
/// a beírt táv áll, hogy a track az Excellel összevethető legyen.
List<String> describeLegacyTracks(
  LegacyCsvSlice slice,
  List<LegacyTrackPlanItem> plan,
) {
  final planned = plan.whereType<PlannedLegacyTrack>().toList();
  final withoutTrack = [
    for (final item in plan)
      if (item is! PlannedLegacyTrack) item,
  ];
  return [
    _csvLine(slice),
    'Track kerül fel: ${planned.length}',
    for (final item in planned) ..._plannedLines(item),
    'Nincs track (a korábbi törlődik): ${withoutTrack.length}',
    for (final item in withoutTrack) '  ${_label(item)} · ${_reasonOf(item)}',
  ];
}

/// Az `--apply` eredményének kiírása.
List<String> describeLegacyTrackApply(LegacyTrackApplyReport report) => [
  'Track írva: ${report.written}',
  'Track nélkül (törölve, ha volt): ${report.cleared}',
];

/// A fejléc hibájának kiírása; az import ekkor nem indul.
List<String> describeYdvrCsvHeaderError(YdvrCsvHeaderError error) => [
  if (error.missing.isNotEmpty)
    'Hiányzó oszlop a CSV-ben: ${error.missing.join(', ')}',
  if (error.duplicated.isNotEmpty)
    'Ismétlődő oszlop a CSV-ben: ${error.duplicated.join(', ')}',
];

String _csvLine(LegacyCsvSlice slice) {
  final rows = 'CSV: ${slice.rowCount} sor';
  final first = slice.firstProblem;
  if (first == null) return '$rows, hibás sor nincs';
  return '$rows, ${slice.problemCount} hibás sor kihagyva (első: '
      '${first.lineNumber}. sor, ${_problemLabel(first.problem)})';
}

List<String> _plannedLines(PlannedLegacyTrack item) => [
  _plannedLine(item),
  if (item.coverage < legacyCoverageWarningThreshold) _coverageWarningLine(),
];

String _plannedLine(PlannedLegacyTrack item) =>
    '  ${_label(item)} · ${item.samples.length} minta, '
    '${_percent(item.coverage)} lefedettség, '
    'táv ${_kilometers(item.distanceMeters)} '
    '(beírva: ${_kilometers(item.race.input.distanceMeters)})';

String _coverageWarningLine() =>
    '    FIGYELEM: a lefedettség '
    '${_percent(legacyCoverageWarningThreshold)} alatti';

String _label(LegacyTrackPlanItem item) =>
    '${item.race.input.date.toIso()} ${item.race.input.name} '
    '[${item.race.id}]';

String _reasonOf(LegacyTrackPlanItem item) => switch (item) {
  LegacyTrackWithoutWindow() => 'nincs hivatalos rajt és befutás',
  LegacyTrackTooShort(:final sampleCount, :final positionCount) =>
    'kettőnél kevesebb pozíció ($sampleCount minta, '
        '$positionCount pozíció)',
  PlannedLegacyTrack() => 'track kerül fel',
};

String _problemLabel(YdvrCsvRowProblem problem) {
  final kind = switch (problem.kind) {
    YdvrCsvProblemKind.cellCount => 'eltérő cellaszám',
    YdvrCsvProblemKind.time => 'olvashatatlan idő',
    YdvrCsvProblemKind.number => 'olvashatatlan szám',
    YdvrCsvProblemKind.coordinate => 'tartományon kívüli koordináta',
  };
  final column = problem.column;
  return column == null ? kind : '$kind: $column';
}

String _percent(double ratio) => '${(ratio * 100).round()} %';

String _kilometers(double? meters) => meters == null
    ? '–'
    : '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
