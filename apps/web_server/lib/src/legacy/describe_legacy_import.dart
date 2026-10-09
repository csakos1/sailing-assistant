import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/legacy/budapest_time.dart';
import 'package:web_server/src/legacy/legacy_apply_report.dart';
import 'package:web_server/src/legacy/legacy_import_plan.dart';
import 'package:web_server/src/legacy/legacy_plan_item.dart';
import 'package:web_server/src/legacy/legacy_race.dart';
import 'package:web_server/src/legacy/legacy_row_problem.dart';
import 'package:web_server/src/legacy/legacy_row_reader.dart';
import 'package:web_server/src/legacy/telemetry_candidate.dart';
import 'package:web_server/src/web_db/manual_race_record.dart';

/// A terv kiírása a próbafuttatáshoz, soronként (ADR 0048 Addendum 6 M1).
///
/// Minden tételnél ott áll, mi íródna, hogy a terv a futtatás előtt
/// cellára pontosan ellenőrizhető legyen.
///
/// Az [existingResultIds] és az [existingManualIds] a már tárolt
/// eredmények és kézi versenyek azonosítói: az ilyen tétel `--overwrite`
/// nélkül kimarad (M4), és a terv ezt a sorában jelzi.
List<String> describeLegacyPlan(
  LegacyImportPlan plan, {
  Set<String> existingResultIds = const {},
  Set<String> existingManualIds = const {},
}) {
  final results = plan.items.whereType<PlannedResult>().toList();
  final manualRaces = plan.items.whereType<PlannedManualRace>().toList();
  final ambiguous = plan.items.whereType<AmbiguousRow>().toList();
  final rejected = plan.items.whereType<RejectedRow>().toList();
  return [
    'Telemetriás versenyhez párosítva: ${results.length}',
    for (final item in results)
      ..._resultLines(
        item,
        // Üres eredményt az --overwrite sem ír, ezért nem is jelezzük.
        hasResult:
            !item.result.isEmpty && existingResultIds.contains(item.target.id),
      ),
    'Új kézi verseny: ${manualRaces.length}',
    for (final item in manualRaces)
      ..._manualRaceLines(item, exists: existingManualIds.contains(item.id)),
    'Nem egyértelmű, --match kell: ${ambiguous.length}',
    for (final item in ambiguous) ..._ambiguousLines(item),
    'Hibás sor, nem íródik: ${rejected.length}',
    for (final item in rejected) ..._rejectedLines(item),
    'Csak telemetria, nincs Excel-sora: ${plan.telemetryOnly.length}',
    for (final race in plan.telemetryOnly) '  ${_candidateLabel(race)}',
    if (plan.matchProblems.isNotEmpty) ...[
      '--match hibák (az --apply nem fut): ${plan.matchProblems.length}',
      for (final problem in plan.matchProblems) '  $problem',
    ],
  ];
}

/// Az `--apply` eredményének kiírása.
List<String> describeLegacyApply(LegacyApplyReport report) => [
  'Eredmény írva: ${report.writtenResults.length}',
  'Új kézi verseny: ${report.createdManualRaces.length}',
  'Felülírt kézi verseny: ${report.overwrittenManualRaces.length}',
  _skippedResultsHeading(report),
  for (final item in report.skippedResults)
    '  ${_rowLabel(item.race)} → ${_candidateLabel(item.target)}',
  _skippedManualHeading(report),
  for (final item in report.skippedManualRaces) '  ${_rowLabel(item.race)}',
  'Üres eredmény, nincs mit írni: ${report.emptyResults.length}',
  for (final item in report.emptyResults)
    '  ${_rowLabel(item.race)} → ${_candidateLabel(item.target)}',
];

/// A fejléc-ellenőrzés kiírása (M8); üres, ha minden fejléc ismert.
List<String> describeLegacyColumns({
  required List<String> unknown,
  required List<String> missing,
}) => [
  if (unknown.isNotEmpty)
    'Ismeretlen oszlop, nem importálódna: ${unknown.join(', ')}',
  if (missing.isNotEmpty) 'Hiányzó oszlop: ${missing.join(', ')}',
];

String _skippedResultsHeading(LegacyApplyReport report) =>
    'Kihagyva, már van eredmény (--overwrite nélkül): '
    '${report.skippedResults.length}';

String _skippedManualHeading(LegacyApplyReport report) =>
    'Kihagyva, a kézi verseny már létezik (--overwrite nélkül): '
    '${report.skippedManualRaces.length}';

List<String> _resultLines(PlannedResult item, {required bool hasResult}) => [
  _resultHeading(item),
  '    → ${_candidateLabel(item.target)}',
  if (hasResult) '    MÁR VAN EREDMÉNYE: csak --overwrite-tal íródik',
  '    ${_resultSummary(item.result)}',
  for (final note in item.race.notes) '    megjegyzés: $note',
];

String _resultHeading(PlannedResult item) =>
    '  ${_rowLabel(item.race)}'
    '${item.splitDay == null ? '' : ' · ${item.splitDay}. nap'}'
    '${item.isExplicit ? ' · --match' : ''}';

List<String> _manualRaceLines(
  PlannedManualRace item, {
  required bool exists,
}) => [
  '  ${_rowLabel(item.race)} [${item.id}]',
  if (exists) '    MÁR LÉTEZIK: csak --overwrite-tal íródik',
  '    ${_resultSummary(item.race.result)}',
  '    ${_statsSummary(item.race.manualRace)}',
  for (final note in item.race.notes) '    megjegyzés: $note',
  for (final other in item.sameDayManualRaces) _duplicateWarning(other),
];

String _duplicateWarning(ManualRaceRecord other) =>
    '    FIGYELEM: ezen a napon már van kézi verseny: '
    '${other.input.name} [${other.id}]';

List<String> _ambiguousLines(AmbiguousRow item) => [
  '  ${_rowLabel(item.race)} · ${_reasonLabel(item.reason)}',
  for (final candidate in item.candidates)
    '    jelölt: ${_candidateLabel(candidate)}',
];

List<String> _rejectedLines(RejectedRow item) => [
  '  ${item.rejection.rowNumber}. sor ${item.rejection.name ?? '(névtelen)'}',
  for (final problem in item.rejection.problems) _problemLine(problem),
];

String _problemLine(LegacyRowProblem problem) =>
    '    ${problem.column}: ${_kindLabel(problem.kind)}'
    '${problem.detail == null ? '' : ' (${problem.detail})'}';

String _rowLabel(LegacyRace race) =>
    '${race.rowNumber}. sor ${race.date.toIso()} ${race.name}';

String _candidateLabel(TelemetryCandidate race) =>
    '${_localDateTime(race.startedAt)} ${race.name} [${race.id}]';

String _reasonLabel(AmbiguityReason reason) => switch (reason) {
  AmbiguityReason.severalOnDay => 'a napon több verseny van',
  AmbiguityReason.twoDayMismatch =>
    'kétnapos sor, de a két napon nem egy-egy verseny van',
  AmbiguityReason.sharedCandidate => 'egy verseny több sorhoz is illene',
};

String _kindLabel(LegacyProblemKind kind) => switch (kind) {
  LegacyProblemKind.missing => 'üres',
  LegacyProblemKind.unreadable => 'olvashatatlan',
  LegacyProblemKind.invalid => 'érvénytelen',
};

String _resultSummary(RaceResultInput result) {
  final parts = [
    if (result.classPlace case final placing?) 'oszt. ${_placing(placing)}',
    if (result.overallPlace case final placing?)
      'absz. ${_placing(placing)}${_fleetSuffix(result.overallFleetSize)}',
    if (result.monohullPlace case final placing?) 'egyt. ${_placing(placing)}',
    if (result.ysNumberHundredths case final ys?) 'YS ${_hundredths(ys)}',
    if (result.officialStart case final start?) 'rajt ${_localDateTime(start)}',
    if (result.officialFinish case final finish?)
      'befutás ${_localDateTime(finish)}',
    if (result.prize != null) 'díj ✓',
  ];
  return parts.isEmpty ? 'eredmény: nincs' : 'eredmény: ${parts.join(' · ')}';
}

String _statsSummary(ManualRaceInput race) {
  final parts = [
    if (race.distanceMeters case final meters?)
      'táv ${_decimal(meters / 1000)} km',
    if (race.maxSpeedMps case final mps?) 'max ${_decimal(mps / _knot)} kn',
    if (race.avgWindMps case final mps?) 'szél ${_decimal(mps / _knot)} kn',
    if (race.maxWindMps case final mps?) 'max szél ${_decimal(mps / _knot)} kn',
    if (race.windPoint case final point?) 'irány ${_windLabel(point)}',
  ];
  return parts.isEmpty ? 'stat: nincs' : 'stat: ${parts.join(' · ')}';
}

const double _knot = 1852 / 3600;

String _windLabel(CompassPoint point) => legacyCompassPointsByLabel.entries
    .firstWhere((entry) => entry.value == point)
    .key;

String _fleetSuffix(int? fleetSize) => fleetSize == null ? '' : '/$fleetSize';

String _placing(Placing placing) => switch (placing) {
  FinishPlace(:final place) => '$place.',
  Dnf() => 'DNF',
  Dsq() => 'DSQ',
};

String _hundredths(int value) =>
    '${value ~/ 100},${(value % 100).toString().padLeft(2, '0')}';

String _decimal(double value) => value.toStringAsFixed(1).replaceAll('.', ',');

String _localDateTime(DateTime instant) {
  final local = budapestWallClockOf(instant);
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}
