import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/application/browser_description.dart';
import 'package:phone/features/web_access/application/scan_problem.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/data/web_api_failure.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:race_archive_api/race_archive_api.dart';

void main() {
  ScanProblem? problemOf(ApiError error, {bool isOwner = false}) =>
      scanProblemOf(
        ApiCallFailed(WebServerFailure(error)),
        isOwner: isOwner,
      );

  group('scanProblemOf', () {
    test('an expired request is an expired code', () {
      expect(problemOf(const RequestExpired()), isA<ExpiredCode>());
    });

    test('an expired enrollment code points to the server', () {
      // Act
      final problem = scanProblemOf(
        const ApiCallFailed(WebServerFailure(RequestExpired())),
        isOwner: true,
        kind: ScanKind.enrollment,
      );

      // Assert
      expect((problem! as ExpiredCode).kind, ScanKind.enrollment);
    });

    test('an expired code while joining keeps the join kind', () {
      // Act
      final problem = scanProblemOf(
        const ApiCallFailed(WebServerFailure(RequestExpired())),
        isOwner: false,
        kind: ScanKind.join,
      );

      // Assert
      expect((problem! as ExpiredCode).kind, ScanKind.join);
    });

    test('a revoked device or a rejected token is a revoked phone', () {
      // Act
      final revoked = problemOf(const DeviceRevoked(), isOwner: true);
      final rejected = problemOf(const NotAuthenticated());

      // Assert
      expect((revoked! as DeviceRevokedProblem).isOwner, isTrue);
      expect((rejected! as DeviceRevokedProblem).isOwner, isFalse);
    });

    test('a 429 waits whole minutes, at least one', () {
      // Act
      final short = problemOf(const TooManyAttempts(5));
      final long = problemOf(const TooManyAttempts(61));

      // Assert
      expect((short! as TooManyAttemptsProblem).minutes, 1);
      expect((long! as TooManyAttemptsProblem).minutes, 2);
    });

    test('network trouble and any other server error mean no connection', () {
      // Act and assert
      expect(problemOf(const InternalError()), isA<NoConnection>());
      expect(
        scanProblemOf(
          const ApiCallFailed(WebNetworkFailure('down')),
          isOwner: false,
        ),
        isA<NoConnection>(),
      );
      expect(
        scanProblemOf(
          const ApiCallFailed(WebUnreadableResponse(502)),
          isOwner: false,
        ),
        isA<NoConnection>(),
      );
    });

    test('a dismissed fingerprint prompt closes silently', () {
      // Act
      final problem = scanProblemOf(
        const KeyOperationFailed(KeyOperationFailure.canceled),
        isOwner: true,
      );

      // Assert
      expect(problem, isNull);
    });

    test('a lost key is a revoked phone, a locked sensor says so', () {
      // Act
      final lost = scanProblemOf(
        const KeyOperationFailed(KeyOperationFailure.keyMissing),
        isOwner: false,
      );
      final locked = scanProblemOf(
        const KeyOperationFailed(KeyOperationFailure.lockedOut),
        isOwner: false,
      );

      // Assert
      expect(lost, isA<DeviceRevokedProblem>());
      expect(locked, isA<BiometricsLockedOut>());
    });
  });

  group('describeBrowserLogin', () {
    test('joins browser, system and place', () {
      // Arrange
      const details = BrowserLoginDetails(
        browser: 'Chrome',
        os: 'Linux',
        ip: '203.0.113.7',
        country: 'HU',
        city: 'Budapest',
      );

      // Act and assert
      expect(describeBrowserLogin(details), 'Chrome · Linux · Budapest, HU');
    });

    test('skips missing parts', () {
      // Arrange
      const details = BrowserLoginDetails(
        browser: 'Firefox',
        ip: '203.0.113.7',
        country: 'HU',
      );

      // Act and assert
      expect(describeBrowserLogin(details), 'Firefox · HU');
    });

    test('shows the address when nothing else is known', () {
      // Arrange
      const details = BrowserLoginDetails(ip: '127.0.0.1');

      // Act and assert
      expect(describeBrowserLogin(details), '127.0.0.1');
    });
  });
}
