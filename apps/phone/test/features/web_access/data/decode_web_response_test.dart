import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/data/decode_web_response.dart';
import 'package:phone/features/web_access/data/web_api_failure.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

void main() {
  List<int> bytesOf(Object? json) => utf8.encode(jsonEncode(json));

  group('decodeWebResponse', () {
    test('decodes a success body with the given decoder', () {
      // Arrange
      final body = bytesOf(
        encodeAccountInfo(
          const AccountInfo(userId: 'u', name: 'Ákos', role: UserRole.owner),
        ),
      );

      // Act
      final result = decodeWebResponse(200, body, decodeAccountInfo);

      // Assert
      expect(result, isA<Ok<AccountInfo, WebApiFailure>>());
    });

    test('reads a 429 as too many attempts with its wait', () {
      // Arrange
      final body = bytesOf(encodeApiError(const TooManyAttempts(90)));

      // Act
      final result = decodeWebResponse(429, body, decodeAccountInfo);

      // Assert
      final failure = (result as Err<AccountInfo, WebApiFailure>).error;
      expect(failure, isA<WebServerFailure>());
      expect((failure as WebServerFailure).error, const TooManyAttempts(90));
    });

    test('a success body the decoder rejects is unreadable', () {
      // Act
      final result = decodeWebResponse(
        200,
        bytesOf({'x': 1}),
        decodeAccountInfo,
      );

      // Assert
      expect(
        (result as Err<AccountInfo, WebApiFailure>).error,
        isA<WebUnreadableResponse>(),
      );
    });
  });

  group('decodeWebNoContent', () {
    test('any status below 400 is a success, even with an empty body', () {
      // Act and assert
      expect(decodeWebNoContent(204, const []), isA<Ok<void, WebApiFailure>>());
    });

    test('an error envelope is a server failure', () {
      // Act
      final result = decodeWebNoContent(
        403,
        bytesOf(encodeApiError(const DeviceRevoked())),
      );

      // Assert
      final failure = (result as Err<void, WebApiFailure>).error;
      expect((failure as WebServerFailure).error, const DeviceRevoked());
    });
  });
}
