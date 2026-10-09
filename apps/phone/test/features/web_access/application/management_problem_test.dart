import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/application/management_problem.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/data/web_api_failure.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:race_archive_api/race_archive_api.dart';

void main() {
  ManagementProblem? problemOf(ApiError error) =>
      managementProblemOf(ApiCallFailed(WebServerFailure(error)));

  group('managementProblemOf', () {
    test('network trouble and unreadable answers are unreachable', () {
      expect(
        managementProblemOf(const ApiCallFailed(WebNetworkFailure('down'))),
        isA<ServerUnreachable>(),
      );
      expect(
        managementProblemOf(const ApiCallFailed(WebUnreadableResponse(502))),
        isA<ServerUnreachable>(),
      );
    });

    test('a server-side error counts as unreachable', () {
      expect(problemOf(const InternalError()), isA<ServerUnreachable>());
    });

    test('a revoked device and a refused key mean a revoked phone', () {
      expect(problemOf(const DeviceRevoked()), isA<PhoneRevoked>());
      expect(problemOf(const NotAuthenticated()), isA<PhoneRevoked>());
      expect(
        managementProblemOf(
          const KeyOperationFailed(KeyOperationFailure.keyMissing),
        ),
        isA<PhoneRevoked>(),
      );
    });

    test('an expired decision is no longer valid', () {
      expect(problemOf(const RequestExpired()), isA<NoLongerValid>());
    });

    test('too many attempts wait in whole minutes', () {
      // Act
      final problem = problemOf(const TooManyAttempts(61));

      // Assert
      expect((problem! as TryAgainLater).minutes, 2);
    });

    test('a refused action is a plain failure', () {
      expect(problemOf(const NotAllowed()), isA<ActionFailed>());
      expect(
        managementProblemOf(
          const KeyOperationFailed(KeyOperationFailure.lockedOut),
        ),
        isA<ActionFailed>(),
      );
    });

    test('a cancelled fingerprint is silent', () {
      expect(
        managementProblemOf(
          const KeyOperationFailed(KeyOperationFailure.canceled),
        ),
        isNull,
      );
    });
  });
}
