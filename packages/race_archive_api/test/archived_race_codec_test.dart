import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

// JSON-szovegen at kodol-dekodol, ahogy a droton utazik: igy a jsonDecode
// valodi Map<String, dynamic> / List<dynamic> tipusait is lefedjuk.
Result<Race, DecodeError> roundTrip(Map<String, Object?> json) =>
    decodeArchivedRace(jsonDecode(jsonEncode(json)));

DecodeError errorOf(Result<Race, DecodeError> result) => switch (result) {
  Ok() => throw StateError('Err-t vartunk, Ok jott'),
  Err(:final error) => error,
};

void main() {
  group('encodeArchivedRace / decodeArchivedRace', () {
    test('round-trips a finished race with marks and rounding times', () {
      // ARRANGE
      final race = finishedRace();

      // ACT
      final result = roundTrip(encodeArchivedRace(race));

      // ASSERT
      expect(result, Ok<Race, DecodeError>(race));
    });

    test('round-trips a markless finished race (ADR 0046)', () {
      // ARRANGE
      final race = Race.create(
        id: 'r-markless',
        name: 'Boja nelkul',
        marks: const [],
      ).start(at: raceStart).finish(at: raceFinish);

      // ACT
      final result = roundTrip(encodeArchivedRace(race));

      // ASSERT
      expect(result, Ok<Race, DecodeError>(race));
    });

    test('does not put status or activeMarkIndex on the wire', () {
      final json = encodeArchivedRace(finishedRace());

      expect(json.containsKey('status'), isFalse);
      expect(json.containsKey('activeMarkIndex'), isFalse);
    });

    test('rejects encoding a race that has not finished', () {
      final active = Race.create(
        id: 'r2',
        name: 'Futo',
        marks: const [tihanyMark],
      ).start(at: raceStart);

      expect(() => encodeArchivedRace(active), throwsArgumentError);
    });

    test('reports the path of a missing finishedAt', () {
      // ARRANGE
      final json = encodeArchivedRace(finishedRace())..remove('finishedAt');

      // ACT
      final error = errorOf(roundTrip(json));

      // ASSERT
      expect(error.path, r'$.finishedAt');
    });

    test('rejects finishedAt before startedAt', () {
      final json = encodeArchivedRace(finishedRace())
        ..['finishedAt'] = raceStart
            .subtract(const Duration(minutes: 1))
            .millisecondsSinceEpoch;

      expect(errorOf(roundTrip(json)).path, r'$.finishedAt');
    });

    test('rejects an empty race name', () {
      final json = encodeArchivedRace(finishedRace())..['name'] = '';

      expect(errorOf(roundTrip(json)).path, r'$.name');
    });

    test('rejects a mark sequence below 1 with the mark path', () {
      // ARRANGE
      final json = encodeArchivedRace(finishedRace());
      final marks = json['marks']! as List<Object?>;
      (marks[1]! as Map<String, Object?>)['seq'] = 0;

      // ACT
      final error = errorOf(roundTrip(json));

      // ASSERT
      expect(error.path, r'$.marks[1].seq');
    });

    test('rejects an out-of-range mark coordinate at the pos object', () {
      // ARRANGE
      final json = encodeArchivedRace(finishedRace());
      final marks = json['marks']! as List<Object?>;
      final mark = marks[0]! as Map<String, Object?>;
      (mark['pos']! as Map<String, Object?>)['lat'] = 91;

      // ACT
      final error = errorOf(roundTrip(json));

      // ASSERT
      expect(error.path, r'$.marks[0].pos');
    });

    test('rejects a non-object root', () {
      expect(errorOf(decodeArchivedRace(<Object?>[])).path, r'$');
    });
  });
}
