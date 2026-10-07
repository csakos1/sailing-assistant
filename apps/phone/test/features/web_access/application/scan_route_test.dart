import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/application/scan_problem.dart';
import 'package:phone/features/web_access/application/scan_route.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../web_access_fakes.dart';

// A V5 tablazata soronkent.
void main() {
  final loginText = encodeQrPayload(loginPayload());
  final foreignLoginText = encodeQrPayload(loginPayload(origin: otherOrigin));
  final enrollText = encodeQrPayload(enrollPayload());
  final foreignEnrollText = encodeQrPayload(
    enrollPayload(origin: otherOrigin),
  );

  test('an ordinary web address is not a Foretack code', () {
    // Act
    final route = routeScan('https://example.com', testAccount());

    // Assert
    expect(
      route,
      isA<ScanRejected>().having(
        (rejected) => rejected.problem,
        'problem',
        isA<NotForetackCode>(),
      ),
    );
  });

  test('a newer code version asks for an app update', () {
    // Act
    final route = routeScan('foretack-login:v9:abc', testAccount());

    // Assert
    expect(
      (route as ScanRejected).problem,
      isA<UnsupportedCode>(),
    );
  });

  test('a login code of the registered server signs in', () {
    // Arrange
    final account = testAccount();

    // Act
    final route = routeScan(loginText, account);

    // Assert
    expect(route, isA<LoginScan>());
    expect((route as LoginScan).account, account);
    expect(route.payload, loginPayload());
  });

  test('a login code of another server names that server', () {
    // Act
    final route = routeScan(foreignLoginText, testAccount());

    // Assert
    final problem = (route as ScanRejected).problem;
    expect((problem as ForeignServer).host, 'archivum.example.hu');
  });

  test('a login code on a phone without an account asks to join', () {
    // Act
    final route = routeScan(loginText, null);

    // Assert
    expect(route, isA<JoinScan>());
  });

  test('an enrollment code on a fresh phone registers it', () {
    // Act
    final route = routeScan(enrollText, null);

    // Assert
    expect(route, isA<EnrollScan>());
    expect((route as EnrollScan).replacing, isNull);
  });

  test('an enrollment code on a registered phone needs confirmation', () {
    // Arrange
    final account = testAccount();

    // Act
    final sameServer = routeScan(enrollText, account);
    final otherServer = routeScan(foreignEnrollText, account);

    // Assert
    expect((sameServer as EnrollScan).replacing, account);
    expect((otherServer as EnrollScan).replacing, account);
    expect(otherServer.payload.origin, otherOrigin);
  });

  test('a trailing newline from the CLI pipe is ignored', () {
    // Act
    final route = routeScan('$enrollText\n', null);

    // Assert
    expect(route, isA<EnrollScan>());
  });
}
