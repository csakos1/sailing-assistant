import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/annotation/annotation_codecs.dart';
import 'package:race_archive_api/src/annotation/race_annotation.dart';
import 'package:race_archive_api/src/json/decode_error.dart';
import 'package:race_archive_api/src/json/json_reader.dart';
import 'package:race_archive_api/src/race/analysis_codecs.dart';
import 'package:race_archive_api/src/race/archived_race_codec.dart';
import 'package:shared/shared.dart';

/// A versenynapló egy eleme (ADR 0047 Addendum 1 A5).
///
/// Elég a napló minden eleméhez: az év- és hónap-bontást a web a
/// `BuildRaceLog`-gal számolja a [race]-ekből, a stat-csík a [trackStats]-ot
/// összegzi, a sor a helyezést az [annotation]-ból veszi.
final class RaceListItem extends Equatable {
  /// Napló-elem a [race]-hez.
  const RaceListItem({
    required this.race,
    required this.trackStats,
    this.annotation,
  });

  /// A befejezett verseny.
  final Race race;

  /// A verseny track-statisztikája (a szerver `race_track_stats` cache-éből).
  final TrackStats trackStats;

  /// Az eredmény-adatok; `null`, ha még nincs rögzítve.
  final RaceAnnotation? annotation;

  @override
  List<Object?> get props => [race, trackStats, annotation];
}

/// A `GET /api/races` válasza: `{"races": [...]}`.
Map<String, Object?> encodeRaceList(List<RaceListItem> items) =>
    <String, Object?>{
      'races': [for (final item in items) _encodeRaceListItem(item)],
    };

/// JSON → a napló elemei.
Result<List<RaceListItem>, DecodeError> decodeRaceList(Object? json) =>
    runDecode(() => JsonReader.root(json).list('races', _readRaceListItem));

Map<String, Object?> _encodeRaceListItem(RaceListItem item) =>
    <String, Object?>{
      'race': encodeArchivedRace(item.race),
      'trackStats': encodeTrackStats(item.trackStats),
      'annotation': switch (item.annotation) {
        null => null,
        final RaceAnnotation annotation => encodeRaceAnnotation(annotation),
      },
    };

RaceListItem _readRaceListItem(Object? item, String path) {
  final reader = JsonReader.at(item, path);
  final annotation = reader.optionalObject('annotation');
  return RaceListItem(
    race: readArchivedRace(reader.object('race')),
    trackStats: readTrackStats(reader.object('trackStats')),
    annotation: annotation == null ? null : readRaceAnnotation(annotation),
  );
}
