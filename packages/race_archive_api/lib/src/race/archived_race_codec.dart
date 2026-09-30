import 'package:domain/domain.dart';
import 'package:race_archive_api/src/json/decode_error.dart';
import 'package:race_archive_api/src/json/json_reader.dart';
import 'package:shared/shared.dart';

/// Egy archivált (befejezett) verseny JSON-alakja (ADR 0047 Addendum 1 A3).
///
/// A dróton nincs `status` és `activeMarkIndex`: az archívum csak
/// befejezett versenyt tartalmaz (D6), ezért a dekóder a
/// `finished` + `activeMarkIndex == marks.length` alakot építi, és a
/// `Race` invariánsa szerkezetileg teljesül.
///
/// Nem befejezett versenyre [ArgumentError]-t dob: az programozói hiba, a
/// szerver ilyet nem archivál.
Map<String, Object?> encodeArchivedRace(Race race) {
  if (race.status != RaceStatus.finished) {
    throw ArgumentError.value(
      race.status,
      'race.status',
      'Csak befejezett verseny archiválható.',
    );
  }
  // A `finished` invariáns garantálja, hogy mindkét időbélyeg nem-null
  // (Race._invariantHolds), ezért a `!` itt nem bukhat el.
  return <String, Object?>{
    'id': race.id,
    'name': race.name,
    'startedAt': race.startedAt!.millisecondsSinceEpoch,
    'finishedAt': race.finishedAt!.millisecondsSinceEpoch,
    'marks': [for (final mark in race.marks) _encodeMark(mark)],
  };
}

/// Egy archivált verseny dekódolása untrusted JSON-ból.
Result<Race, DecodeError> decodeArchivedRace(Object? json) =>
    runDecode(() => readArchivedRace(JsonReader.root(json)));

/// Belső olvasó: a beágyazó DTO-k kodekjei használják.
Race readArchivedRace(JsonReader reader) {
  final marks = reader.list(
    'marks',
    (item, path) => _readMark(JsonReader.at(item, path)),
  );
  final startedAt = reader.utcMillis('startedAt');
  final finishedAt = reader.utcMillis('finishedAt');
  if (finishedAt.isBefore(startedAt)) {
    JsonReader.failAt(reader.childPath('finishedAt'), 'not before startedAt');
  }
  return Race(
    id: reader.nonEmptyString('id'),
    name: reader.nonEmptyString('name'),
    marks: marks,
    status: RaceStatus.finished,
    activeMarkIndex: marks.length,
    startedAt: startedAt,
    finishedAt: finishedAt,
  );
}

Map<String, Object?> _encodeMark(Mark mark) => <String, Object?>{
  'seq': mark.sequence,
  'name': mark.name,
  'pos': <String, Object?>{
    'lat': mark.position.latitude,
    'lon': mark.position.longitude,
  },
  'roundedAt': mark.roundedAt?.millisecondsSinceEpoch,
};

Mark _readMark(JsonReader reader) => Mark(
  sequence: reader.integerAtLeast('seq', 1),
  name: reader.nonEmptyString('name'),
  position: reader.coordinate('pos'),
  roundedAt: reader.optionalUtcMillis('roundedAt'),
);
