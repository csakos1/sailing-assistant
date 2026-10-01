import 'package:domain/domain.dart';
import 'package:race_archive_api/src/json/json_reader.dart';
import 'package:race_archive_api/src/race/archive_track_point.dart';
import 'package:shared/shared.dart';

// A verseny-részletező elemzési adatainak kodekjei (ADR 0047 Addendum 1
// A4): TrackStats, RoundingResult, track-pont. Belső fájl — a barrel nem
// exportálja, a RaceListItem / LegacyRaceDetail kodekje hívja.

/// [TrackStats] → JSON. Minden mező opcionális, mint a domainben.
Map<String, Object?> encodeTrackStats(TrackStats stats) => <String, Object?>{
  'maxSpeedMps': stats.maxSpeedMps,
  'avgSpeedMps': stats.avgSpeedMps,
  'distanceMeters': stats.distanceMeters,
};

/// JSON → [TrackStats].
TrackStats readTrackStats(JsonReader reader) => TrackStats(
  maxSpeedMps: reader.optionalNumber('maxSpeedMps'),
  avgSpeedMps: reader.optionalNumber('avgSpeedMps'),
  distanceMeters: reader.optionalNumber('distanceMeters'),
);

/// [RoundingResult] → JSON; az időtartamok milliszekundumban.
Map<String, Object?> encodeRoundingResult(RoundingResult result) =>
    <String, Object?>{
      'fromMark': result.fromMark,
      'toMark': result.toMark,
      'roundedAt': result.roundedAt.millisecondsSinceEpoch,
      'predictedTwaDeg': result.predictedTwaDeg,
      'markTwaDeg': result.markTwaDeg,
      'forecastBandDeg': result.forecastBandDeg,
      'predictedConfidence': result.predictedConfidence,
      'leadTimeMs': result.leadTime?.inMilliseconds,
      'lastReliableLeadTimeMs': result.lastReliableLeadTime?.inMilliseconds,
      'actualSampleCount': result.actualSampleCount,
    };

/// JSON-elem → [RoundingResult], a `list` olvasó elem-callbackjeként.
RoundingResult readRoundingResult(Object? item, String path) {
  final reader = JsonReader.at(item, path);
  return RoundingResult(
    fromMark: reader.string('fromMark'),
    toMark: reader.string('toMark'),
    roundedAt: reader.utcMillis('roundedAt'),
    predictedTwaDeg: reader.optionalNumber('predictedTwaDeg'),
    markTwaDeg: reader.optionalNumber('markTwaDeg'),
    forecastBandDeg: reader.optionalNumber('forecastBandDeg'),
    predictedConfidence: reader.optionalString('predictedConfidence'),
    leadTime: reader.optionalDurationMillis('leadTimeMs'),
    lastReliableLeadTime: reader.optionalDurationMillis(
      'lastReliableLeadTimeMs',
    ),
    actualSampleCount: reader.integerAtLeast('actualSampleCount', 0),
  );
}

/// [ArchiveTrackPoint] → kompakt tömb: `[lat, lon, sogMps|null]`.
List<Object?> encodeTrackPoint(ArchiveTrackPoint point) => <Object?>[
  point.position.latitude,
  point.position.longitude,
  point.sogMps,
];

/// Kompakt tömb → [ArchiveTrackPoint], a `list` olvasó elem-callbackjeként.
ArchiveTrackPoint readTrackPoint(Object? item, String path) {
  const expected = '[lat, lon, sogMps|null]';
  if (item is! List<Object?> || item.length != 3) {
    JsonReader.failAt(path, expected);
  }
  final lat = item[0];
  final lon = item[1];
  if (lat is! num || lon is! num) JsonReader.failAt(path, expected);
  final sogMps = switch (item[2]) {
    null => null,
    final num value when value.isFinite => value.toDouble(),
    _ => JsonReader.failAt(path, expected),
  };
  final result = Coordinate.tryFromDegrees(
    latitude: lat.toDouble(),
    longitude: lon.toDouble(),
  );
  return switch (result) {
    Ok(value: final position) => ArchiveTrackPoint(
      position: position,
      sogMps: sogMps,
    ),
    Err() => JsonReader.failAt(path, 'coordinate within range'),
  };
}
