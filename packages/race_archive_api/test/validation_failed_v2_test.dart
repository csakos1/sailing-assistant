import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';

import 'record_fixtures.dart';

void main() {
  group('ValidationFailed with v2 violations', () {
    test('round-trips every violation kind', () {
      // ARRANGE
      const error = ValidationFailed([
        ValueNotPositive(InputField.ysNumberHundredths),
        PlaceExceedsFleetSize(InputField.monohullPlace),
        FinishNotAfterStart(),
        ValueNegative(InputField.maxWindMps),
        ValueEmpty(InputField.name),
      ]);

      // ACT
      final decoded = unwrap(
        decodeApiError(overTheWire(encodeApiError(error))),
      );

      // ASSERT
      expect(decoded, error);
    });

    test('writes each violation as a field name and a code', () {
      // ACT
      final json = encodeApiError(
        const ValidationFailed([
          FinishNotAfterStart(),
          ValueEmpty(InputField.name),
        ]),
      );

      // ASSERT
      expect(objectAt(json, 'error')['violations'], [
        {'field': 'officialFinish', 'code': 'finishNotAfterStart'},
        {'field': 'name', 'code': 'valueEmpty'},
      ]);
    });

    test('keeps the v1 aliases interchangeable with the v2 types', () {
      // A web_server az S5b-3-ig a v1 neveket hasznalja (Addendum 2 H5).
      const AnnotationViolation violation = PlaceExceedsFleetSize(
        AnnotationField.overallPlace,
      );

      expect(violation.field, InputField.overallPlace);
    });

    test('rejects finishNotAfterStart on another field', () {
      // ARRANGE
      final json = <String, Object?>{
        'error': <String, Object?>{
          'code': 'validationFailed',
          'violations': [
            {'field': 'officialStart', 'code': 'finishNotAfterStart'},
          ],
        },
      };

      // ACT
      final error = errorOf(decodeApiError(json));

      // ASSERT
      expect(error.path, r'$.error.violations[0].code');
    });
  });

  group('v2 routes', () {
    test('build the result and manual race paths with an encoded id', () {
      expect(raceResultPath('a/b'), '/api/races/a%2Fb/result');
      expect(manualRacesPath, '/api/manual-races');
      expect(manualRacePath('a/b'), '/api/manual-races/a%2Fb');
    });
  });
}
