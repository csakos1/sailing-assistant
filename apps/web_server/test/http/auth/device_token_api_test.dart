import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:web_server/src/auth_db/device_repository.dart';

import 'auth_harness.dart';
import 'test_phone.dart';

void main() {
  late AuthHarness harness;
  late TestPhone phone;
  late String deviceId;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    harness = AuthHarness();
    phone = TestPhone.first();
    deviceId = (await harness.enroll(phone)).deviceId;
  });

  tearDown(() => harness.close());

  Future<IssuedSecret> challenge() async => decodeOk(
    await harness.send(
      'POST',
      deviceChallengesPath,
      json: encodeDeviceChallengeRequest(deviceId),
    ),
    decodeIssuedSecret,
    status: 201,
  );

  Future<Response> tokenFor(String challenge, {TestKey? signer}) =>
      harness.send(
        'POST',
        deviceTokensPath,
        json: harness.signedTokenRequest(
          signer ?? phone.deviceKey,
          deviceId,
          challenge,
        ),
      );

  Future<Response> me(String token) => harness.send(
    'GET',
    mePath,
    headers: {'authorization': 'Bearer $token'},
  );

  group('device token', () {
    test('is issued for a challenge signed with the device key', () async {
      // ARRANGE
      final issued = await challenge();

      // ACT
      final token = await decodeOk(
        await tokenFor(issued.value),
        decodeIssuedSecret,
        status: 201,
      );

      // ASSERT
      expect(token.expiresAt, harness.now.add(const Duration(minutes: 15)));
      final account = await decodeOk(await me(token.value), decodeAccountInfo);
      expect(account.role, UserRole.owner);
      final device = await DeviceRepository(harness.database).get(deviceId);
      expect(device?.lastUsedAt, harness.now);
    });

    test('is refused for a signature with the signing key', () async {
      final issued = await challenge();

      final response = await tokenFor(issued.value, signer: phone.signingKey);

      expect(response.statusCode, 401);
      expect(await errorOf(response), const NotAuthenticated());
    });

    test('uses a challenge only once, even after a wrong signature', () async {
      final issued = await challenge();
      await tokenFor(issued.value, signer: phone.signingKey);

      final response = await tokenFor(issued.value);

      expect(response.statusCode, 410);
      expect(await errorOf(response), const RequestExpired());
    });

    test('refuses an expired challenge', () async {
      final issued = await challenge();
      harness.advance(const Duration(seconds: 60));

      final response = await tokenFor(issued.value);

      expect(await errorOf(response), const RequestExpired());
    });

    test('refuses a challenge issued to another device', () async {
      // ARRANGE
      final other = TestPhone.second();
      final otherId = (await harness.enroll(other)).deviceId;
      final issued = await challenge();

      // ACT
      final response = await harness.send(
        'POST',
        deviceTokensPath,
        json: harness.signedTokenRequest(
          other.deviceKey,
          otherId,
          issued.value,
        ),
      );

      // ASSERT
      expect(await errorOf(response), const RequestExpired());
    });

    test('expires after 15 minutes', () async {
      final token = await harness.deviceToken(phone, deviceId);
      harness.advance(const Duration(minutes: 15));

      final response = await me(token);

      expect(response.statusCode, 401);
      expect(await errorOf(response), const NotAuthenticated());
    });

    test('stops working at once when the device is revoked', () async {
      final token = await harness.deviceToken(phone, deviceId);
      await DeviceRepository(
        harness.database,
      ).revoke(deviceId, now: harness.now);

      final response = await me(token);

      expect(response.statusCode, 403);
      expect(await errorOf(response), const DeviceRevoked());
    });
  });

  group('device challenge', () {
    test('is refused for a revoked or unknown device', () async {
      await DeviceRepository(
        harness.database,
      ).revoke(deviceId, now: harness.now);

      final revoked = await harness.send(
        'POST',
        deviceChallengesPath,
        json: encodeDeviceChallengeRequest(deviceId),
      );
      final unknown = await harness.send(
        'POST',
        deviceChallengesPath,
        json: encodeDeviceChallengeRequest('nincs-ilyen'),
      );

      expect(await errorOf(revoked), const DeviceRevoked());
      expect(await errorOf(unknown), const DeviceRevoked());
    });
  });

  group('GET $mePath', () {
    test('needs a token or a session', () async {
      final response = await harness.send('GET', mePath);

      expect(response.statusCode, 401);
    });

    test('lets a malformed Authorization header decide', () async {
      final response = await harness.send(
        'GET',
        mePath,
        headers: {'authorization': 'Basic YTpi'},
      );

      expect(response.statusCode, 401);
    });
  });
}
