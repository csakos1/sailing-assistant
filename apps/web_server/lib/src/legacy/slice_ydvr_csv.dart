import 'package:shared/shared.dart';
import 'package:web_server/src/legacy/legacy_csv_slice.dart';
import 'package:web_server/src/legacy/legacy_track_sample.dart';
import 'package:web_server/src/legacy/legacy_track_window.dart';
import 'package:web_server/src/legacy/ydvr_csv_columns.dart';
import 'package:web_server/src/legacy/ydvr_csv_problem.dart';

/// A `polar.csv` [lines] soraiból a [windows] ablakaiba eső minták,
/// versenyenként (ADR 0050 D2, D4 + Addendum 1 E3).
///
/// Egy menetben olvas, így a 100 MB-os fájl soronként streamelhető. A
/// sorok sorrendjére nem támaszkodik: az ablakokat a kezdetük szerint
/// rendezi, és minden sornál csak a már elkezdődötteket nézi. Az ablakon
/// kívüli sor csak az időbélyegig bomlik.
///
/// Egy versenyen belül az ismétlődő időbélyeg közül a későbbi sor marad.
/// Ilyen az őszi óraátállítás kétértelmű órája is (02:00–03:00), mert a
/// helyi idő mindkétszer ugyanarra a pillanatra képződik; versenyidőben
/// ez nem fordul elő.
/// A határok az ablakhoz tartoznak. Hiba csak a fejlécre jön; a hibás sor
/// kimarad, és a számuk a kivágásban áll.
Future<Result<LegacyCsvSlice, YdvrCsvHeaderError>> sliceYdvrCsv(
  Stream<String> lines,
  List<LegacyTrackWindow> windows,
) async {
  final sortedWindows = [...windows]
    ..sort((a, b) => a.window.start.compareTo(b.window.start));
  final collector = _SliceCollector();
  YdvrCsvColumns? columns;
  var lineNumber = 0;
  await for (final line in lines) {
    lineNumber++;
    if (columns == null) {
      switch (YdvrCsvColumns.fromHeader(line)) {
        case Ok(:final value):
          columns = value;
        case Err(:final error):
          return Err<LegacyCsvSlice, YdvrCsvHeaderError>(error);
      }
      continue;
    }
    if (line.trim().isEmpty) continue;
    collector.addRow();
    _readLine(columns, line, lineNumber, sortedWindows, collector);
  }
  if (columns == null) {
    // Üres fájl: egyetlen kötelező oszlop sincs meg.
    return const Err<LegacyCsvSlice, YdvrCsvHeaderError>(
      YdvrCsvHeaderError(missing: YdvrCsvColumns.requiredColumns),
    );
  }
  return Ok<LegacyCsvSlice, YdvrCsvHeaderError>(collector.build());
}

void _readLine(
  YdvrCsvColumns columns,
  String line,
  int lineNumber,
  List<LegacyTrackWindow> sortedWindows,
  _SliceCollector collector,
) {
  final cells = splitYdvrCsvLine(line);
  final DateTime timestamp;
  switch (columns.timestampOf(cells)) {
    case Ok(:final value):
      timestamp = value;
    case Err(:final error):
      collector.addProblem(lineNumber, error);
      return;
  }
  final raceIds = _raceIdsAt(timestamp, sortedWindows);
  if (raceIds.isEmpty) return;
  switch (columns.sampleOf(cells, timestamp)) {
    case Ok(:final value):
      collector.addSample(raceIds, value);
    case Err(:final error):
      collector.addProblem(lineNumber, error);
  }
}

// A kezdet szerint rendezett ablakokon a még el nem kezdődöttnél megáll.
List<String> _raceIdsAt(DateTime moment, List<LegacyTrackWindow> sorted) {
  final raceIds = <String>[];
  for (final entry in sorted) {
    if (entry.window.start.isAfter(moment)) break;
    if (!moment.isAfter(entry.window.end)) raceIds.add(entry.raceId);
  }
  return raceIds;
}

// A kivágás gyűjtője; csak a sliceYdvrCsv használja, egy futás idejére.
final class _SliceCollector {
  int _rowCount = 0;
  int _problemCount = 0;
  YdvrCsvLineProblem? _firstProblem;
  // Versenyenként az időbélyeg (ms) szerint: az ismétlődés felülír.
  final Map<String, Map<int, LegacyTrackSample>> _samples = {};

  void addRow() => _rowCount++;

  void addProblem(int lineNumber, YdvrCsvRowProblem problem) {
    _problemCount++;
    _firstProblem ??= (lineNumber: lineNumber, problem: problem);
  }

  void addSample(List<String> raceIds, LegacyTrackSample sample) {
    for (final raceId in raceIds) {
      (_samples[raceId] ??= {})[sample.timestamp.millisecondsSinceEpoch] =
          sample;
    }
  }

  LegacyCsvSlice build() => LegacyCsvSlice(
    rowCount: _rowCount,
    problemCount: _problemCount,
    firstProblem: _firstProblem,
    tracks: {
      for (final MapEntry(key: raceId, value: byTime) in _samples.entries)
        raceId: [
          for (final entry in byTime.entries.toList()..sort(_byTimestamp))
            entry.value,
        ],
    },
  );
}

int _byTimestamp(
  MapEntry<int, LegacyTrackSample> a,
  MapEntry<int, LegacyTrackSample> b,
) => a.key.compareTo(b.key);
