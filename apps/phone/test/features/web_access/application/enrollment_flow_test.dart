import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/application/enrollment_flow.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/data/web_access_api_client.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

import '../web_access_fakes.dart';

void main() {
  late FakeWebServer server;
  late FakeKeys keys;
  late MemoryWebAccountStore store;
  late List<String> clientOrigins;
  late EnrollmentFlow flow;

  const prompt = BiometricPromptText(title: 'Regisztráció', cancel: 'Mégse');
  const owner = AccountInfo(
    userId: 'owner-1',
    name: 'Ákos',
    role: UserRole.owner,
  );
  final codes = List.generate(10, (index) => 'CODE$index-AAAAA');

  setUp(() {
    server = FakeWebServer();
    keys = FakeKeys();
    store = MemoryWebAccountStore(testAccount(origin: otherOrigin));
    clientOrigins = [];
    flow = EnrollmentFlow(
      clientFor: (origin) {
        clientOrigins.add(origin);
        return WebAccessApiClient(server.client, origin: origin);
      },
      keys: keys.operations,
      readIdentity: () async =>
          (deviceName: 'Pixel 8', model: 'Google Pixel 8'),
      saveAccount: store.write,
      clearAccount: store.delete,
    );
    server.routes[enrollmentsPath] = (_) => jsonResponse(
      encodeEnrollmentResult(
        EnrollmentResult(
          account: owner,
          deviceId: 'device-9',
          recoveryCodes: codes,
        ),
      ),
      status: 201,
    );
  });

  Future<Result<CompletedEnrollment, WebAccessError>> run() =>
      flow.run(enrollPayload(), prompt: prompt);

  test('replaces the old account and keys, then registers', () async {
    // Act
    final result = await run();

    // Assert
    final enrollment =
        (result as Ok<CompletedEnrollment, WebAccessError>).value;
    expect(enrollment.recoveryCodes, codes);
    expect(enrollment.deviceName, 'Pixel 8');
    expect(store.account, enrollment.account);
    expect(store.account?.origin, testOrigin);
    expect(store.account?.deviceId, 'device-9');
    expect(keys.calls, [
      'delete',
      'create:signing',
      'create:device',
      'sign:biometric',
    ]);
    expect(clientOrigins, [testOrigin]);
  });

  test('signs both public keys with the signing key', () async {
    // Act
    await run();

    // Assert
    expect(
      keys.signedMessages.single,
      enrollmentMessage(
        origin: testOrigin,
        token: testToken,
        publicKey: FakeKeys.signingKey,
        deviceKey: FakeKeys.deviceKey,
      ),
    );
    final body = FakeWebServer.bodyOf(server.requests.single);
    expect(body['model'], 'Google Pixel 8');
    expect(body['token'], testToken);
  });

  test('a dismissed prompt sends nothing and saves nothing', () async {
    // Arrange
    keys.biometricFailure = KeyOperationFailure.canceled;

    // Act
    final result = await run();

    // Assert
    expect(result, isA<Err<CompletedEnrollment, WebAccessError>>());
    expect(server.requests, isEmpty);
    expect(store.account, isNull);
  });

  test('a refused token leaves the phone without an account', () async {
    // Arrange
    server.routes[enrollmentsPath] = (_) =>
        errorResponse(const RequestExpired());

    // Act
    final result = await run();

    // Assert
    final error = (result as Err<CompletedEnrollment, WebAccessError>).error;
    expect(error, isA<ApiCallFailed>());
    expect(store.account, isNull);
  });

  test('a phone without fingerprints cannot create keys', () async {
    // Arrange
    keys.createFailure = KeyOperationFailure.unavailable;

    // Act
    final result = await run();

    // Assert
    final error = (result as Err<CompletedEnrollment, WebAccessError>).error;
    expect(
      (error as KeyOperationFailed).failure,
      KeyOperationFailure.unavailable,
    );
    expect(server.requests, isEmpty);
  });
}
