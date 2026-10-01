import 'package:domain/domain.dart';
import 'package:race_archive_api/src/json/decode_error.dart';
import 'package:race_archive_api/src/json/json_reader.dart';
import 'package:race_archive_api/src/record/calendar_date_codec.dart';
import 'package:race_archive_api/src/record/manual_race_input.dart';
import 'package:race_archive_api/src/record/manual_race_request.dart';
import 'package:race_archive_api/src/record/race_result_input.dart';
import 'package:race_archive_api/src/record/result_codecs.dart';
import 'package:shared/shared.dart';

// A kézi verseny kodekjei (ADR 0048 D2, D6 + Addendum 2 H1, H4). Az égtáj
// az enum nevével utazik (`"southWest"`), a nap `"YYYY-MM-DD"` alakban.

/// [ManualRaceInput] → JSON.
Map<String, Object?> encodeManualRaceInput(ManualRaceInput input) =>
    <String, Object?>{
      'name': input.name,
      'date': input.date.toIso(),
      'distanceMeters': input.distanceMeters,
      'maxSpeedMps': input.maxSpeedMps,
      'avgWindMps': input.avgWindMps,
      'maxWindMps': input.maxWindMps,
      'windPoint': input.windPoint?.name,
    };

/// Belső olvasó a beágyazó kodekeknek.
ManualRaceInput readManualRaceInput(JsonReader reader) => ManualRaceInput(
  name: reader.string('name'),
  date: readCalendarDate(reader, 'date'),
  distanceMeters: reader.optionalNumber('distanceMeters'),
  maxSpeedMps: reader.optionalNumber('maxSpeedMps'),
  avgWindMps: reader.optionalNumber('avgWindMps'),
  maxWindMps: reader.optionalNumber('maxWindMps'),
  windPoint: reader.optionalEnumByName('windPoint', CompassPoint.values),
);

/// [ManualRaceRequest] → JSON: `{"race": …, "result": …}`.
Map<String, Object?> encodeManualRaceRequest(ManualRaceRequest request) =>
    <String, Object?>{
      'race': encodeManualRaceInput(request.race),
      'result': encodeRaceResultInput(request.result),
    };

/// JSON → [ManualRaceRequest]. A hiányzó vagy `null` `result` üres
/// eredmény.
Result<ManualRaceRequest, DecodeError> decodeManualRaceRequest(Object? json) =>
    runDecode(() {
      final reader = JsonReader.root(json);
      final result = reader.optionalObject('result');
      return ManualRaceRequest(
        race: readManualRaceInput(reader.object('race')),
        result: result == null
            ? const RaceResultInput()
            : readRaceResultInput(result),
      );
    });
