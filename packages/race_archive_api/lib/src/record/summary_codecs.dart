import 'package:domain/domain.dart';
import 'package:race_archive_api/src/json/decode_error.dart';
import 'package:race_archive_api/src/json/json_reader.dart';
import 'package:race_archive_api/src/race/analysis_codecs.dart';
import 'package:race_archive_api/src/record/calendar_date_codec.dart';
import 'package:race_archive_api/src/record/race_origin.dart';
import 'package:race_archive_api/src/record/race_result.dart';
import 'package:race_archive_api/src/record/race_stats.dart';
import 'package:race_archive_api/src/record/race_summary.dart';
import 'package:race_archive_api/src/record/result_codecs.dart';
import 'package:race_archive_api/src/record/stats_window.dart';
import 'package:shared/shared.dart';

// A napló-sor kodekjei (ADR 0048 D6 + Addendum 2 H2, H3). Az eredet és az
// ablak `kind` mezővel különböztetett objektum; az időbélyegek UTC epoch
// ms-ben.

/// A `GET /api/races` válasza: `{"races": [...]}`.
Map<String, Object?> encodeRaceSummaries(List<RaceSummary> summaries) =>
    <String, Object?>{
      'races': [for (final summary in summaries) encodeRaceSummary(summary)],
    };

/// JSON → a napló sorai.
Result<List<RaceSummary>, DecodeError> decodeRaceSummaries(Object? json) =>
    runDecode(
      () => JsonReader.root(json).list(
        'races',
        (item, path) => readRaceSummary(JsonReader.at(item, path)),
      ),
    );

/// [RaceSummary] → JSON; a kézi verseny mentésének válasza is ez.
Map<String, Object?> encodeRaceSummary(RaceSummary summary) =>
    <String, Object?>{
      'id': summary.id,
      'name': summary.name,
      'origin': _encodeOrigin(summary.origin),
      'stats': _encodeStats(summary.stats),
      'result': switch (summary.result) {
        null => null,
        final RaceResult result => encodeRaceResult(result),
      },
    };

/// JSON → [RaceSummary].
Result<RaceSummary, DecodeError> decodeRaceSummary(Object? json) =>
    runDecode(() => readRaceSummary(JsonReader.root(json)));

/// Belső olvasó a beágyazó kodekeknek.
///
/// Az eredet és az ablak összhangját is ellenőrzi: telemetriás versenyhez
/// hivatalos vagy rögzítés-ablak, kézihez beírt érték vagy (régi trackből
/// számolt statnál) hivatalos ablak tartozik (H3, ADR 0050 D7).
RaceSummary readRaceSummary(JsonReader reader) {
  final origin = _readOrigin(reader.object('origin'));
  final statsReader = reader.object('stats');
  final stats = _readStats(statsReader);
  final isConsistent = switch ((origin, stats.window)) {
    (TelemetryOrigin(), OfficialWindow() || RecordingWindow()) => true,
    (ManualOrigin(), ManualEntry() || OfficialWindow()) => true,
    _ => false,
  };
  if (!isConsistent) {
    JsonReader.failAt(
      statsReader.childPath('window'),
      'window matching the race origin',
    );
  }
  final result = reader.optionalObject('result');
  return RaceSummary(
    id: reader.nonEmptyString('id'),
    name: reader.string('name'),
    origin: origin,
    stats: stats,
    result: result == null ? null : readRaceResult(result),
  );
}

Map<String, Object?> _encodeOrigin(RaceOrigin origin) => switch (origin) {
  TelemetryOrigin(:final recording) => <String, Object?>{
    'kind': _telemetry,
    ..._encodeTimeWindow(recording),
  },
  ManualOrigin(:final date) => <String, Object?>{
    'kind': _manual,
    'date': date.toIso(),
  },
};

RaceOrigin _readOrigin(JsonReader reader) => switch (reader.string('kind')) {
  _telemetry => TelemetryOrigin(_readTimeWindow(reader)),
  _manual => ManualOrigin(readCalendarDate(reader, 'date')),
  _ => JsonReader.failAt(reader.childPath('kind'), '$_telemetry|$_manual'),
};

Map<String, Object?> _encodeStats(RaceStats stats) => <String, Object?>{
  'window': _encodeWindow(stats.window),
  ...encodeTrackStats(stats.track),
  'avgWindMps': stats.avgWindMps,
  'maxWindMps': stats.maxWindMps,
  'windPoint': stats.windPoint?.name,
};

RaceStats _readStats(JsonReader reader) => RaceStats(
  window: _readWindow(reader.object('window')),
  track: readTrackStats(reader),
  avgWindMps: reader.optionalNumber('avgWindMps'),
  maxWindMps: reader.optionalNumber('maxWindMps'),
  windPoint: reader.optionalEnumByName('windPoint', CompassPoint.values),
);

Map<String, Object?> _encodeWindow(StatsWindow statsWindow) =>
    switch (statsWindow) {
      OfficialWindow(:final window) => <String, Object?>{
        'kind': _official,
        ..._encodeTimeWindow(window),
      },
      RecordingWindow(:final window) => <String, Object?>{
        'kind': _recording,
        ..._encodeTimeWindow(window),
      },
      ManualEntry() => <String, Object?>{'kind': _manual},
    };

StatsWindow _readWindow(JsonReader reader) => switch (reader.string('kind')) {
  _official => OfficialWindow(_readTimeWindow(reader)),
  _recording => RecordingWindow(_readTimeWindow(reader)),
  _manual => const ManualEntry(),
  _ => JsonReader.failAt(
    reader.childPath('kind'),
    '$_official|$_recording|$_manual',
  ),
};

Map<String, Object?> _encodeTimeWindow(TimeWindow window) => <String, Object?>{
  'start': window.start.millisecondsSinceEpoch,
  'end': window.end.millisecondsSinceEpoch,
};

TimeWindow _readTimeWindow(JsonReader reader) {
  final start = reader.utcMillis('start');
  final end = reader.utcMillis('end');
  // A TimeWindow konstruktora assert-tel védi a sorrendet; a dróton érkező
  // fordított ablak rossz bemenet, nem programozói hiba.
  if (end.isBefore(start)) {
    JsonReader.failAt(reader.childPath('end'), 'end not before start');
  }
  return TimeWindow(start: start, end: end);
}

const String _telemetry = 'telemetry';
const String _manual = 'manual';
const String _official = 'official';
const String _recording = 'recording';
