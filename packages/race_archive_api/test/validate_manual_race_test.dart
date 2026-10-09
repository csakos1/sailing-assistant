import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'record_fixtures.dart';

void main() {
  ManualRaceInput race({
    String name = 'IX. Lelle Kupa',
    double? distanceMeters = 9800,
    double? maxSpeedMps = 3.55,
    double? avgWindMps,
    double? maxWindMps,
  }) => ManualRaceInput(
    name: name,
    date: manualDate,
    distanceMeters: distanceMeters,
    maxSpeedMps: maxSpeedMps,
    avgWindMps: avgWindMps,
    maxWindMps: maxWindMps,
    windPoint: CompassPoint.southEast,
  );

  group('ValidateManualRaceInput', () {
    const validate = ValidateManualRaceInput();

    List<InputViolation> violationsOf(ManualRaceInput input) =>
        switch (validate(input)) {
          Ok() => const [],
          Err(:final error) => error,
        };

    test('accepts a valid race unchanged', () {
      expect(
        validate(race()),
        Ok<ManualRaceInput, List<InputViolation>>(race()),
      );
    });

    test('accepts zero values: a calm day is still data', () {
      expect(
        violationsOf(race(distanceMeters: 0, avgWindMps: 0, maxWindMps: 0)),
        isEmpty,
      );
    });

    test('trims the name', () {
      final result = validate(race(name: '  IX. Lelle Kupa \n'));

      expect(result, Ok<ManualRaceInput, List<InputViolation>>(race()));
    });

    test('rejects a blank name', () {
      expect(violationsOf(race(name: '  ')), [
        const ValueEmpty(InputField.name),
      ]);
    });

    test('rejects every negative quantity at once, in field order', () {
      // ARRANGE
      final input = race(
        distanceMeters: -1,
        maxSpeedMps: -0.1,
        avgWindMps: -2,
        maxWindMps: -3,
      );

      // ACT + ASSERT
      expect(violationsOf(input), [
        const ValueNegative(InputField.distanceMeters),
        const ValueNegative(InputField.maxSpeedMps),
        const ValueNegative(InputField.avgWindMps),
        const ValueNegative(InputField.maxWindMps),
      ]);
    });
  });

  group('ValidateManualRaceRequest', () {
    const validate = ValidateManualRaceRequest();

    // Az Err == a listat identitas szerint hasonlitana, ezert a
    // szabalysertes-listat kulon vesszuk ki.
    List<InputViolation> violationsOf(ManualRaceRequest request) =>
        switch (validate(request)) {
          Ok() => const [],
          Err(:final error) => error,
        };

    test('returns both parts normalized', () {
      // ARRANGE
      final request = ManualRaceRequest(
        race: race(name: ' IX. Lelle Kupa '),
        result: const RaceResultInput(prize: ' fa erem '),
      );

      // ACT
      final result = validate(request);

      // ASSERT
      expect(
        result,
        Ok<ManualRaceRequest, List<InputViolation>>(
          ManualRaceRequest(
            race: race(),
            result: const RaceResultInput(prize: 'fa erem'),
          ),
        ),
      );
    });

    test('lists the race violations before the result violations', () {
      // ARRANGE
      final request = ManualRaceRequest(
        race: race(name: '', distanceMeters: -1),
        result: const RaceResultInput(
          overallPlace: FinishPlace(30),
          overallFleetSize: 24,
        ),
      );

      // ACT + ASSERT
      expect(violationsOf(request), [
        const ValueEmpty(InputField.name),
        const ValueNegative(InputField.distanceMeters),
        const PlaceExceedsFleetSize(InputField.overallPlace),
      ]);
    });

    test('reports result violations even when the race part is valid', () {
      final request = ManualRaceRequest(
        race: race(),
        result: const RaceResultInput(ysNumberHundredths: 0),
      );

      expect(violationsOf(request), [
        const ValueNotPositive(InputField.ysNumberHundredths),
      ]);
    });
  });
}
