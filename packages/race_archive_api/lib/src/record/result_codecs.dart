import 'package:race_archive_api/src/json/decode_error.dart';
import 'package:race_archive_api/src/json/json_reader.dart';
import 'package:race_archive_api/src/record/placing.dart';
import 'package:race_archive_api/src/record/race_result.dart';
import 'package:race_archive_api/src/record/race_result_input.dart';
import 'package:shared/shared.dart';

// Az eredmény kodekjei (ADR 0048 D3 + Addendum 2 H4). A helyezés dróton
// szám, `"dnf"` vagy `"dsq"`; az időbélyegek UTC epoch ms-ben.

/// [Placing] → JSON-érték: szám, `"dnf"`, `"dsq"` vagy `null`.
Object? encodePlacing(Placing? placing) => switch (placing) {
  null => null,
  FinishPlace(:final place) => place,
  Dnf() => _dnf,
  Dsq() => _dsq,
};

/// A [key] mező helyezése a [reader] objektumában.
///
/// Bármely egész számot `FinishPlace`-ként fogad el; a ≥ 1 szabály a
/// validációé (Addendum 2 H4).
Placing? readPlacing(JsonReader reader, String key) =>
    switch (reader.optionalIntegerOrSymbol(key, const {_dnf, _dsq})) {
      null => null,
      final int place => FinishPlace(place),
      _dnf => const Dnf(),
      _dsq => const Dsq(),
      // Az olvasó csak egész számot, a két jelet vagy `null`-t ad vissza;
      // ide jutni programozói hiba, nem rossz bemenet.
      final Object other => throw StateError('Váratlan helyezés: $other'),
    };

/// [RaceResultInput] → JSON: a `PUT .../result` törzse.
Map<String, Object?> encodeRaceResultInput(RaceResultInput input) =>
    <String, Object?>{
      'classPlace': encodePlacing(input.classPlace),
      'classFleetSize': input.classFleetSize,
      'overallPlace': encodePlacing(input.overallPlace),
      'overallFleetSize': input.overallFleetSize,
      'monohullPlace': encodePlacing(input.monohullPlace),
      'monohullFleetSize': input.monohullFleetSize,
      'ysNumberHundredths': input.ysNumberHundredths,
      'officialStart': input.officialStart?.millisecondsSinceEpoch,
      'officialFinish': input.officialFinish?.millisecondsSinceEpoch,
      'prize': input.prize,
      'summary': input.summary,
    };

/// JSON → [RaceResultInput].
///
/// Csak az alakot ellenőrzi. A tartalmi szabályok a
/// `ValidateRaceResultInput` dolga, hogy a „rossz alak" és a „rossz érték"
/// két külön hibaként jusson a klienshez.
Result<RaceResultInput, DecodeError> decodeRaceResultInput(Object? json) =>
    runDecode(() => readRaceResultInput(JsonReader.root(json)));

/// Belső olvasó a beágyazó kodekeknek.
RaceResultInput readRaceResultInput(JsonReader reader) => RaceResultInput(
  classPlace: readPlacing(reader, 'classPlace'),
  classFleetSize: reader.optionalInteger('classFleetSize'),
  overallPlace: readPlacing(reader, 'overallPlace'),
  overallFleetSize: reader.optionalInteger('overallFleetSize'),
  monohullPlace: readPlacing(reader, 'monohullPlace'),
  monohullFleetSize: reader.optionalInteger('monohullFleetSize'),
  ysNumberHundredths: reader.optionalInteger('ysNumberHundredths'),
  officialStart: reader.optionalUtcMillis('officialStart'),
  officialFinish: reader.optionalUtcMillis('officialFinish'),
  prize: reader.optionalString('prize'),
  summary: reader.optionalString('summary'),
);

/// [RaceResult] → JSON: a bemenet mezői laposan, plusz az azonosító és a
/// mentés ideje.
Map<String, Object?> encodeRaceResult(RaceResult result) => <String, Object?>{
  'raceId': result.raceId,
  'updatedAt': result.updatedAt.millisecondsSinceEpoch,
  ...encodeRaceResultInput(result.content),
};

/// JSON → [RaceResult].
Result<RaceResult, DecodeError> decodeRaceResult(Object? json) =>
    runDecode(() => readRaceResult(JsonReader.root(json)));

/// Belső olvasó a beágyazó kodekeknek.
RaceResult readRaceResult(JsonReader reader) => RaceResult(
  raceId: reader.nonEmptyString('raceId'),
  content: readRaceResultInput(reader),
  updatedAt: reader.utcMillis('updatedAt'),
);

const String _dnf = 'dnf';
const String _dsq = 'dsq';
