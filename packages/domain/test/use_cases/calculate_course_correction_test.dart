import 'package:domain/src/use_cases/calculate_course_correction.dart';
import 'package:domain/src/value_objects/angle.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:test/test.dart';

void main() {
  group('CalculateCourseCorrection', () {
    const useCase = CalculateCourseCorrection();

    group('alapesetek', () {
      test('azonos bearing → 0° korrekció', () {
        const direction = Bearing.true_(90);
        const mark = Bearing.true_(90);
        expect(
          useCase(bearingToMark: mark, effectiveDirection: direction),
          equals(const Angle(degrees: 0)),
        );
      });

      test('jobbra +30° normal tartományban (90° → 120°)', () {
        const direction = Bearing.true_(90);
        const mark = Bearing.true_(120);
        expect(
          useCase(bearingToMark: mark, effectiveDirection: direction),
          equals(const Angle(degrees: 30)),
        );
      });

      test('balra -30° normal tartományban (90° → 60°)', () {
        const direction = Bearing.true_(90);
        const mark = Bearing.true_(60);
        expect(
          useCase(bearingToMark: mark, effectiveDirection: direction),
          equals(const Angle(degrees: -30)),
        );
      });
    });

    group('north-wrap (signed shortest-path)', () {
      test('350° → 10° rövidebb úton +20° (NEM -340°)', () {
        const direction = Bearing.true_(350);
        const mark = Bearing.true_(10);
        expect(
          useCase(bearingToMark: mark, effectiveDirection: direction),
          equals(const Angle(degrees: 20)),
        );
      });

      test('10° → 350° rövidebb úton -20° (NEM +340°)', () {
        const direction = Bearing.true_(10);
        const mark = Bearing.true_(350);
        expect(
          useCase(bearingToMark: mark, effectiveDirection: direction),
          equals(const Angle(degrees: -20)),
        );
      });
    });

    group('antipodális határeset', () {
      test('180°-os különbség → -180° (felső szél exkluzív)', () {
        const direction = Bearing.true_(0);
        const mark = Bearing.true_(180);
        // Angle normalize: ((180 - 0 + 180) % 360) - 180 = -180.
        expect(
          useCase(bearingToMark: mark, effectiveDirection: direction),
          equals(const Angle(degrees: -180)),
        );
      });
    });

    group('null effectiveDirection', () {
      test('null direction → null result', () {
        const mark = Bearing.true_(120);
        expect(
          useCase(bearingToMark: mark, effectiveDirection: null),
          isNull,
        );
      });
    });

    group('reference-mismatch', () {
      test('true és magnetic párral hívva → AssertionError dev mode-ban', () {
        const mark = Bearing.true_(90);
        const direction = Bearing.magnetic_(80);
        expect(
          () => useCase(bearingToMark: mark, effectiveDirection: direction),
          throwsA(isA<AssertionError>()),
        );
      });
    });
  });
}
