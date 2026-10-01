import 'package:race_archive_api/src/json/decode_error.dart';
import 'package:race_archive_api/src/json/json_reader.dart';
import 'package:race_archive_api/src/race/analysis_codecs.dart';
import 'package:race_archive_api/src/race/archived_race_codec.dart';
import 'package:race_archive_api/src/record/race_detail.dart';
import 'package:race_archive_api/src/record/race_origin.dart';
import 'package:race_archive_api/src/record/summary_codecs.dart';
import 'package:shared/shared.dart';

/// A `GET /api/races/{id}` válasza (ADR 0048 D6 + Addendum 2 H4).
Map<String, Object?> encodeRaceDetail(RaceDetail detail) => <String, Object?>{
  'summary': encodeRaceSummary(detail.summary),
  'telemetry': switch (detail.telemetry) {
    null => null,
    final TelemetryRaceData telemetry => <String, Object?>{
      'race': encodeArchivedRace(telemetry.race),
      'trackPoints': [
        for (final point in telemetry.trackPoints) encodeTrackPoint(point),
      ],
      'roundings': [
        for (final result in telemetry.roundings) encodeRoundingResult(result),
      ],
    },
  },
};

/// JSON → [RaceDetail].
///
/// A `telemetry` pontosan telemetriás eredetnél van jelen; az eltérés
/// dekódolási hiba a `telemetry` útvonalán.
Result<RaceDetail, DecodeError> decodeRaceDetail(Object? json) => runDecode(() {
  final reader = JsonReader.root(json);
  final summary = readRaceSummary(reader.object('summary'));
  final telemetryReader = reader.optionalObject('telemetry');
  final isTelemetry = summary.origin is TelemetryOrigin;
  if (isTelemetry != (telemetryReader != null)) {
    JsonReader.failAt(
      reader.childPath('telemetry'),
      isTelemetry ? 'object for a telemetry race' : 'null for a manual race',
    );
  }
  return RaceDetail(
    summary: summary,
    telemetry: telemetryReader == null
        ? null
        : TelemetryRaceData(
            race: readArchivedRace(telemetryReader.object('race')),
            trackPoints: telemetryReader.list('trackPoints', readTrackPoint),
            roundings: telemetryReader.list('roundings', readRoundingResult),
          ),
  );
});
