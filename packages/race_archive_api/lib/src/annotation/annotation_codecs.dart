import 'package:race_archive_api/src/annotation/race_annotation.dart';
import 'package:race_archive_api/src/annotation/race_annotation_input.dart';
import 'package:race_archive_api/src/json/decode_error.dart';
import 'package:race_archive_api/src/json/json_reader.dart';
import 'package:shared/shared.dart';

/// [RaceAnnotationInput] → JSON: a `PUT .../annotation` törzse.
Map<String, Object?> encodeRaceAnnotationInput(RaceAnnotationInput input) =>
    <String, Object?>{
      'overallPlace': input.overallPlace,
      'overallFleetSize': input.overallFleetSize,
      'classPlace': input.classPlace,
      'classFleetSize': input.classFleetSize,
      'summary': input.summary,
    };

/// JSON → [RaceAnnotationInput].
///
/// Csak az alakot ellenőrzi (egész szám vagy `null`, szöveg vagy `null`).
/// A tartalmi szabályok a `ValidateRaceAnnotationInput` dolga, hogy a
/// „rossz alak" és a „rossz érték" két külön hibaként jusson a klienshez.
Result<RaceAnnotationInput, DecodeError> decodeRaceAnnotationInput(
  Object? json,
) => runDecode(() => readRaceAnnotationInput(JsonReader.root(json)));

/// Belső olvasó a beágyazó kodekeknek.
RaceAnnotationInput readRaceAnnotationInput(JsonReader reader) =>
    RaceAnnotationInput(
      overallPlace: reader.optionalInteger('overallPlace'),
      overallFleetSize: reader.optionalInteger('overallFleetSize'),
      classPlace: reader.optionalInteger('classPlace'),
      classFleetSize: reader.optionalInteger('classFleetSize'),
      summary: reader.optionalString('summary'),
    );

/// [RaceAnnotation] → JSON: a bemenet mezői laposan, plusz az azonosító és
/// a mentés ideje.
Map<String, Object?> encodeRaceAnnotation(RaceAnnotation annotation) =>
    <String, Object?>{
      'raceId': annotation.raceId,
      'updatedAt': annotation.updatedAt.millisecondsSinceEpoch,
      ...encodeRaceAnnotationInput(annotation.content),
    };

/// JSON → [RaceAnnotation].
Result<RaceAnnotation, DecodeError> decodeRaceAnnotation(Object? json) =>
    runDecode(() => readRaceAnnotation(JsonReader.root(json)));

/// Belső olvasó a beágyazó kodekeknek.
RaceAnnotation readRaceAnnotation(JsonReader reader) => RaceAnnotation(
  raceId: reader.nonEmptyString('raceId'),
  content: readRaceAnnotationInput(reader),
  updatedAt: reader.utcMillis('updatedAt'),
);
