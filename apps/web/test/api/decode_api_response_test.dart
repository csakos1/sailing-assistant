import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/api/decode_api_response.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

void main() {
  const emptyReport = ImportReport(
    added: [],
    updated: [],
    skipped: [],
    warnings: [],
  );

  Result<ImportReport, ApiFailure> decode(int status, String body) =>
      decodeApiResponse(status, body, decodeImportReport);

  group('decodeApiResponse', () {
    test('decodes a success body with the given decoder', () {
      // ACT
      final result = decode(200, jsonEncode(encodeImportReport(emptyReport)));

      // ASSERT
      expect(result, const Ok<ImportReport, ApiFailure>(emptyReport));
    });

    test('turns an error envelope into a server failure', () {
      // ARRANGE
      const error = ImportRejected(
        SchemaTooNew(fileVersion: 9, serverVersion: 8),
      );

      // ACT
      final result = decode(422, jsonEncode(encodeApiError(error)));

      // ASSERT
      expect(
        switch (result) {
          Err(error: ServerFailure(:final error)) => error,
          _ => null,
        },
        error,
      );
    });

    test('reports a body that is not JSON as unreadable', () {
      // ACT
      final result = decode(502, '<html>Bad Gateway</html>');

      // ASSERT
      expect(
        switch (result) {
          Err(error: UnreadableResponse(:final statusCode)) => statusCode,
          _ => null,
        },
        502,
      );
    });

    test('reports a success body of the wrong shape as unreadable', () {
      // ACT
      final result = decode(200, '{"added": 1}');

      // ASSERT
      expect(
        switch (result) {
          Err(error: UnreadableResponse(:final decodeError)) =>
            decodeError != null,
          _ => false,
        },
        isTrue,
      );
    });
  });
}
