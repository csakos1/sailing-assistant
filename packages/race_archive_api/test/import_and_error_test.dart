import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

T unwrap<T>(Result<T, DecodeError> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError('Ok-t vartunk: $error'),
};

Object? overTheWire(Map<String, Object?> json) => jsonDecode(jsonEncode(json));

void main() {
  group('ImportReport', () {
    test('round-trips added, updated, skipped races and warnings', () {
      // ARRANGE
      final report = ImportReport(
        added: [
          ImportedRace(
            id: 'a',
            name: 'Kekszalag',
            finishedAt: DateTime.utc(2026, 7, 18, 13),
          ),
        ],
        updated: [
          ImportedRace(
            id: 'b',
            name: 'Szent Mihaly',
            finishedAt: DateTime.utc(2026, 9, 27, 16),
          ),
        ],
        skipped: const [
          SkippedRace(id: 'c', name: 'Edzes', status: RaceStatus.active),
        ],
        warnings: const [ImportWarning.walIgnored],
      );

      // ACT
      final decoded = unwrap(
        decodeImportReport(overTheWire(encodeImportReport(report))),
      );

      // ASSERT
      expect(decoded, report);
    });
  });

  group('ApiError', () {
    final errors = <ApiError>[
      const MalformedRequest(
        DecodeError(path: r'$.overallPlace', expected: 'integer or null'),
      ),
      const ValidationFailed([
        PlaceExceedsFleetSize(InputField.overallPlace),
        ValueNotPositive(InputField.classFleetSize),
      ]),
      const RaceNotFound('race-404'),
      const ImportRejected(MainFileMissing()),
      const ImportRejected(NotSqliteDatabase()),
      const ImportRejected(NotForetackDatabase()),
      const ImportRejected(SchemaTooNew(fileVersion: 6, serverVersion: 5)),
      const MissingClientHeader(),
      const PayloadTooLarge(65536),
      const PolarUnavailable(),
      const ExportInProgress(),
      const InternalError(),
      const NotAuthenticated(),
      const NotAllowed(),
      const TooManyAttempts(240),
      const RequestExpired(),
      const DeviceRevoked(),
    ];

    for (final error in errors) {
      test('round-trips ${error.runtimeType} (${error.props})', () {
        final decoded = unwrap(
          decodeApiError(overTheWire(encodeApiError(error))),
        );

        expect(decoded, error);
      });
    }

    test('wraps the payload in an error envelope with a code', () {
      final json = encodeApiError(const RaceNotFound('x'));

      expect(json, {
        'error': {'code': 'raceNotFound', 'raceId': 'x'},
      });
    });

    test('maps each error to its HTTP status', () {
      expect(
        errors.map((error) => error.httpStatus),
        [
          400,
          422,
          404,
          422,
          422,
          422,
          422,
          403,
          413,
          503,
          409,
          500,
          401,
          403,
          429,
          410,
          403,
        ],
      );
    });

    test('rejects a retry delay shorter than a second', () {
      final result = decodeApiError(<String, Object?>{
        'error': <String, Object?>{
          'code': 'tooManyAttempts',
          'retryAfterSeconds': 0,
        },
      });

      expect(
        result,
        const Err<ApiError, DecodeError>(
          DecodeError(
            path: r'$.error.retryAfterSeconds',
            expected: 'integer >= 1',
          ),
        ),
      );
    });

    test('rejects an unknown error code', () {
      final result = decodeApiError(<String, Object?>{
        'error': <String, Object?>{'code': 'teapot'},
      });

      expect(
        result,
        const Err<ApiError, DecodeError>(
          DecodeError(path: r'$.error.code', expected: 'api error code'),
        ),
      );
    });
  });

  group('routes', () {
    test('percent-encode the race id in the path', () {
      expect(racePath('a/b'), '/api/races/a%2Fb');
      expect(racePolarPath('a/b'), '/api/races/a%2Fb/polar');
    });

    test('put the year into the season path', () {
      expect(polarSeasonPath(2026), '/api/polar/seasons/2026');
    });
  });
}
