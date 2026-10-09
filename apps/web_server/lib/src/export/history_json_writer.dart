import 'dart:convert';
import 'dart:io';

import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/server_log.dart';

/// A `foretack-history.json` `format` mezője (ADR 0050 Addendum 3 G6).
const String historyJsonFormat = 'foretack-history';

/// A `foretack-history.json` szerkezetének verziója; a szerkezet
/// változásakor nő.
const int historyJsonVersion = 1;

/// A napló sorainak olvasója (a `RaceSummaryService` hívása).
typedef RaceSummariesReader = Future<List<RaceSummary>> Function();

/// Egy verseny részletezőjének olvasója (a `RaceDetailService` hívása).
typedef RaceDetailReader = Future<RaceDetail?> Function(String raceId);

/// A `foretack-history.json` írója (ADR 0050 D8 + Addendum 3 G6).
///
/// `{"format", "version", "exportedAt", "races": [...]}`, a `races` elemei
/// a szerződés `encodeRaceDetail` kódolójával, a napló sorrendjében. A
/// részletező a napló sorát is tartalmazza, így külön lista nem kell.
final class HistoryJsonWriter {
  /// Író a [readSummaries] és a [readDetail] olvasókkal.
  const HistoryJsonWriter({
    required RaceSummariesReader readSummaries,
    required RaceDetailReader readDetail,
    ServerLog log = ignoreServerLog,
  }) : _readSummaries = readSummaries,
       _readDetail = readDetail,
       _log = log;

  final RaceSummariesReader _readSummaries;
  final RaceDetailReader _readDetail;
  final ServerLog _log;

  /// A JSON a [sink]-be; a visszatérés a kiírt versenyek száma.
  ///
  /// Versenyenként ürít (flush), így a memóriában egyszerre egy részletező
  /// van. A [sink]-et nem zárja le.
  Future<int> write(IOSink sink, {required DateTime exportedAt}) async {
    sink.write(
      '{"format":${jsonEncode(historyJsonFormat)},'
      '"version":$historyJsonVersion,'
      '"exportedAt":${jsonEncode(exportedAt.toUtc().toIso8601String())},'
      '"races":[',
    );
    var written = 0;
    for (final summary in await _readSummaries()) {
      final detail = await _readDetail(summary.id);
      // A napló és a részletező ugyanabból a pillanatképből olvas; az
      // eltérés hibát jelezne, de egy verseny miatt nem bukik az export.
      if (detail == null) {
        _log('export: nincs részletező, kimarad: ${summary.id}');
        continue;
      }
      if (written > 0) sink.write(',');
      sink.write(jsonEncode(encodeRaceDetail(detail)));
      written++;
      await sink.flush();
    }
    sink.write(']}');
    await sink.flush();
    return written;
  }
}
