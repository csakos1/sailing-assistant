import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';

import 'record_fixtures.dart';

void main() {
  group('RaceResultInput codec', () {
    test('round-trips every field', () {
      final decoded = unwrap(
        decodeRaceResultInput(
          overTheWire(encodeRaceResultInput(fullResultInput)),
        ),
      );

      expect(decoded, fullResultInput);
    });

    test('writes placings as numbers or dnf/dsq and missing ones as null', () {
      // ARRANGE
      const input = RaceResultInput(
        classPlace: FinishPlace(2),
        overallPlace: Dsq(),
        monohullPlace: Dnf(),
      );

      // ACT
      final json = encodeRaceResultInput(input);

      // ASSERT
      expect(json['classPlace'], 2);
      expect(json['overallPlace'], 'dsq');
      expect(json['monohullPlace'], 'dnf');
      expect(json['classFleetSize'], isNull);
    });

    test('decodes an input with only some fields present', () {
      final decoded = unwrap(
        decodeRaceResultInput(<String, Object?>{'overallPlace': 'dnf'}),
      );

      expect(decoded, const RaceResultInput(overallPlace: Dnf()));
    });

    test('decodes an out-of-range place, leaving it to the validator', () {
      final decoded = unwrap(
        decodeRaceResultInput(<String, Object?>{'classPlace': 0}),
      );

      expect(decoded.classPlace, const FinishPlace(0));
    });

    test('accepts an integral double place, as the web sends numbers', () {
      final decoded = unwrap(
        decodeRaceResultInput(<String, Object?>{'overallPlace': 3.0}),
      );

      expect(decoded.overallPlace, const FinishPlace(3));
    });

    test('rejects an unknown placing symbol with its path', () {
      // ACT
      final error = errorOf(
        decodeRaceResultInput(<String, Object?>{'monohullPlace': 'DNF'}),
      );

      // ASSERT
      expect(error.path, r'$.monohullPlace');
      expect(error.expected, 'integer, "dnf", "dsq" or null');
    });

    test('rejects a fractional place', () {
      final error = errorOf(
        decodeRaceResultInput(<String, Object?>{'classPlace': 1.5}),
      );

      expect(error.path, r'$.classPlace');
    });

    test('rejects a YS number sent as a decimal string', () {
      final error = errorOf(
        decodeRaceResultInput(<String, Object?>{'ysNumberHundredths': '75,90'}),
      );

      expect(error.path, r'$.ysNumberHundredths');
    });
  });

  group('RaceResult codec', () {
    test('round-trips the stored result with id and save time', () {
      final decoded = unwrap(
        decodeRaceResult(overTheWire(encodeRaceResult(storedResult))),
      );

      expect(decoded, storedResult);
    });

    test('keeps the input fields flat next to the id', () {
      final json = encodeRaceResult(storedResult);

      expect(json['raceId'], 'race-1');
      expect(json['overallPlace'], 3);
      expect(json['ysNumberHundredths'], 7590);
    });

    test('rejects an empty race id', () {
      final json = encodeRaceResult(storedResult)..['raceId'] = '';

      expect(errorOf(decodeRaceResult(overTheWire(json))).path, r'$.raceId');
    });
  });

  group('RaceResultInput', () {
    test('is empty only when no field is set', () {
      expect(const RaceResultInput().isEmpty, isTrue);
      expect(const RaceResultInput(overallFleetSize: 24).isEmpty, isFalse);
      expect(const RaceResultInput(monohullPlace: Dsq()).isEmpty, isFalse);
    });

    test('is a podium when any placing is 1 to 3', () {
      expect(
        const RaceResultInput(monohullPlace: FinishPlace(3)).isPodium,
        isTrue,
      );
      expect(
        const RaceResultInput(
          classPlace: FinishPlace(4),
          overallPlace: Dnf(),
        ).isPodium,
        isFalse,
      );
      expect(const RaceResultInput().isPodium, isFalse);
    });

    test('derives the official elapsed time only from both times', () {
      expect(
        fullResultInput.officialElapsed,
        const Duration(hours: 5, minutes: 24),
      );
      expect(
        RaceResultInput(officialStart: officialStart).officialElapsed,
        isNull,
      );
    });
  });
}
