import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  const validate = ValidateRaceAnnotationInput();

  List<AnnotationViolation> violationsOf(RaceAnnotationInput input) =>
      switch (validate(input)) {
        Ok() => const [],
        Err(:final error) => error,
      };

  RaceAnnotationInput normalized(RaceAnnotationInput input) =>
      switch (validate(input)) {
        Ok(:final value) => value,
        Err(:final error) => throw StateError('Ok-t vartunk: $error'),
      };

  group('ValidateRaceAnnotationInput accepts', () {
    test('an empty input', () {
      expect(
        validate(const RaceAnnotationInput()),
        isA<Ok<Object?, Object?>>(),
      );
    });

    test('a complete, consistent result', () {
      // ARRANGE
      const input = RaceAnnotationInput(
        overallPlace: 3,
        overallFleetSize: 24,
        classPlace: 1,
        classFleetSize: 6,
        summary: 'Eros delnyugati.',
      );

      // ACT + ASSERT
      expect(normalized(input), input);
    });

    test('a place equal to the fleet size (last place)', () {
      const input = RaceAnnotationInput(overallPlace: 24, overallFleetSize: 24);

      expect(violationsOf(input), isEmpty);
    });

    test('a place without a fleet size and vice versa', () {
      const input = RaceAnnotationInput(overallPlace: 3, classFleetSize: 6);

      expect(violationsOf(input), isEmpty);
    });
  });

  group('ValidateRaceAnnotationInput rejects', () {
    test('a zero or negative place and fleet size, per field', () {
      // ARRANGE
      const input = RaceAnnotationInput(overallPlace: 0, classFleetSize: -2);

      // ACT
      final violations = violationsOf(input);

      // ASSERT
      expect(violations, const [
        ValueNotPositive(AnnotationField.overallPlace),
        ValueNotPositive(AnnotationField.classFleetSize),
      ]);
    });

    test('a place greater than the fleet size, on the place field', () {
      const input = RaceAnnotationInput(classPlace: 7, classFleetSize: 6);

      expect(violationsOf(input), const [
        PlaceExceedsFleetSize(AnnotationField.classPlace),
      ]);
    });

    test('reports violations of both pairs at once', () {
      // ARRANGE
      const input = RaceAnnotationInput(
        overallPlace: 30,
        overallFleetSize: 24,
        classPlace: 0,
      );

      // ACT
      final violations = violationsOf(input);

      // ASSERT
      expect(violations, const [
        PlaceExceedsFleetSize(AnnotationField.overallPlace),
        ValueNotPositive(AnnotationField.classPlace),
      ]);
    });

    test('does not add an ordering violation next to a non-positive one', () {
      // A 0-s mezony mellett a "helyezes > mezony" masodlagos es
      // felrevezeto lenne.
      const input = RaceAnnotationInput(overallPlace: 3, overallFleetSize: 0);

      expect(violationsOf(input), const [
        ValueNotPositive(AnnotationField.overallFleetSize),
      ]);
    });
  });

  group('ValidateRaceAnnotationInput normalizes the summary', () {
    test('by trimming surrounding whitespace but keeping inner lines', () {
      const input = RaceAnnotationInput(
        summary: '\n  Elso bekezdes.\n\nMasodik.  \n',
      );

      expect(normalized(input).summary, 'Elso bekezdes.\n\nMasodik.');
    });

    test('into null when it is whitespace only', () {
      const input = RaceAnnotationInput(overallPlace: 2, summary: ' \n\t ');

      expect(normalized(input).summary, isNull);
    });
  });

  group('RaceAnnotationInput.isEmpty', () {
    test('is true only when every field is null', () {
      expect(const RaceAnnotationInput().isEmpty, isTrue);
      expect(const RaceAnnotationInput(classFleetSize: 5).isEmpty, isFalse);
      expect(const RaceAnnotationInput(summary: 'x').isEmpty, isFalse);
    });
  });
}
