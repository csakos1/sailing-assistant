import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'record_fixtures.dart';

void main() {
  const validate = ValidateRaceResultInput();

  List<InputViolation> violationsOf(RaceResultInput input) =>
      switch (validate(input)) {
        Ok() => const [],
        Err(:final error) => error,
      };

  RaceResultInput normalized(RaceResultInput input) =>
      switch (validate(input)) {
        Ok(:final value) => value,
        Err(:final error) => throw StateError('Ok-t vartunk: $error'),
      };

  group('ValidateRaceResultInput accepts', () {
    test('an empty input', () {
      expect(violationsOf(const RaceResultInput()), isEmpty);
    });

    test('a complete, consistent result unchanged', () {
      expect(normalized(fullResultInput), fullResultInput);
    });

    test('a place equal to its own fleet size (last place)', () {
      const input = RaceResultInput(
        monohullPlace: FinishPlace(18),
        monohullFleetSize: 18,
      );

      expect(violationsOf(input), isEmpty);
    });

    test('a place without a fleet size and a fleet size without a place', () {
      const input = RaceResultInput(
        classPlace: FinishPlace(30),
        overallFleetSize: 24,
      );

      expect(violationsOf(input), isEmpty);
    });

    test('any fleet size next to DNF or DSQ', () {
      const input = RaceResultInput(
        overallPlace: Dnf(),
        overallFleetSize: 1,
        classPlace: Dsq(),
        classFleetSize: 56,
      );

      expect(violationsOf(input), isEmpty);
    });

    test('only one official time', () {
      final input = RaceResultInput(officialFinish: officialFinish);

      expect(violationsOf(input), isEmpty);
    });
  });

  group('ValidateRaceResultInput checks each place against its own fleet', () {
    test('and does not compare a place with another pair', () {
      // ARRANGE: the overall fleet is large, but the class fleet is small
      const input = RaceResultInput(
        classPlace: FinishPlace(5),
        classFleetSize: 4,
        overallPlace: FinishPlace(5),
        overallFleetSize: 24,
      );

      // ACT + ASSERT
      expect(violationsOf(input), [
        const PlaceExceedsFleetSize(InputField.classPlace),
      ]);
    });

    test('reporting every violated pair at once', () {
      // ARRANGE
      const input = RaceResultInput(
        classPlace: FinishPlace(10),
        classFleetSize: 9,
        overallPlace: FinishPlace(25),
        overallFleetSize: 24,
        monohullPlace: FinishPlace(14),
        monohullFleetSize: 12,
      );

      // ACT + ASSERT
      expect(violationsOf(input), [
        const PlaceExceedsFleetSize(InputField.classPlace),
        const PlaceExceedsFleetSize(InputField.overallPlace),
        const PlaceExceedsFleetSize(InputField.monohullPlace),
      ]);
    });
  });

  group('ValidateRaceResultInput rejects', () {
    test('a zero or negative place and fleet size, per field', () {
      // ARRANGE
      const input = RaceResultInput(
        overallPlace: FinishPlace(0),
        monohullFleetSize: -2,
      );

      // ACT + ASSERT
      expect(violationsOf(input), [
        const ValueNotPositive(InputField.overallPlace),
        const ValueNotPositive(InputField.monohullFleetSize),
      ]);
    });

    test('no order violation next to a non-positive value', () {
      const input = RaceResultInput(
        overallPlace: FinishPlace(3),
        overallFleetSize: 0,
      );

      expect(violationsOf(input), [
        const ValueNotPositive(InputField.overallFleetSize),
      ]);
    });

    test('a non-positive YS number', () {
      expect(violationsOf(const RaceResultInput(ysNumberHundredths: 0)), [
        const ValueNotPositive(InputField.ysNumberHundredths),
      ]);
    });

    test('a finish at the start, on the finish field', () {
      final input = RaceResultInput(
        officialStart: officialStart,
        officialFinish: officialStart,
      );

      expect(violationsOf(input), [const FinishNotAfterStart()]);
    });

    test('a finish before the start (the next-day case)', () {
      // ARRANGE: a Kekszalag finish typed without moving it to the next day
      final input = RaceResultInput(
        officialStart: DateTime.utc(2026, 7, 30, 7),
        officialFinish: DateTime.utc(2026, 7, 30, 6, 35),
      );

      // ACT + ASSERT
      final violations = violationsOf(input);
      expect(violations, [const FinishNotAfterStart()]);
      expect(violations.single.field, InputField.officialFinish);
    });

    test('collects violations of every rule together', () {
      final input = RaceResultInput(
        classPlace: const FinishPlace(-1),
        ysNumberHundredths: -5,
        officialStart: officialFinish,
        officialFinish: officialStart,
      );

      expect(violationsOf(input), [
        const ValueNotPositive(InputField.classPlace),
        const ValueNotPositive(InputField.ysNumberHundredths),
        const FinishNotAfterStart(),
      ]);
    });
  });

  group('ValidateRaceResultInput normalizes', () {
    test('blank prize and summary to null and trims the rest', () {
      // ARRANGE
      const input = RaceResultInput(
        prize: '   ',
        summary: '\n  Eros delnyugati.\n\n',
      );

      // ACT
      final result = normalized(input);

      // ASSERT
      expect(result.prize, isNull);
      expect(result.summary, 'Eros delnyugati.');
    });

    test('the official times to UTC', () {
      // ARRANGE
      final localStart = DateTime(2026, 7, 26, 11);
      final input = RaceResultInput(officialStart: localStart);

      // ACT
      final start = normalized(input).officialStart;

      // ASSERT
      expect(start?.isUtc, isTrue);
      expect(start, localStart.toUtc());
    });
  });
}
