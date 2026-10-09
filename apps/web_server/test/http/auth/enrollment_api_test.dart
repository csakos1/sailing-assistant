import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/auth_db/device_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';

import 'auth_harness.dart';
import 'test_phone.dart';

void main() {
  late AuthHarness harness;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() => harness = AuthHarness());

  tearDown(() => harness.close());

  Future<List<String>> storedCodeDigests() async => [
    for (final row
        in await harness.database.select(harness.database.recoveryCodes).get())
      String.fromCharCodes(row.codeDigest),
  ];

  group('POST $enrollmentsPath', () {
    test('creates the owner, the device and ten recovery codes', () async {
      // ARRANGE
      final phone = TestPhone.first();
      final token = await harness.issueEnrollmentToken();

      // ACT
      final response = await harness.send(
        'POST',
        enrollmentsPath,
        json: harness.enrollmentBody(phone, token),
      );
      final result = await decodeOk(
        response,
        decodeEnrollmentResult,
        status: 201,
      );

      // ASSERT
      expect(result.account.name, 'Ákos');
      expect(result.account.role, UserRole.owner);
      expect(result.recoveryCodes, hasLength(10));
      expect(response.headers['cache-control'], 'no-store');
      final device = await DeviceRepository(
        harness.database,
      ).get(result.deviceId);
      expect(device?.publicKey, phone.signingKey.spki);
      expect(device?.deviceKey, phone.deviceKey.spki);
      expect(device?.name, 'Ákos Pixel 8');
      expect(
        await storedCodeDigests(),
        unorderedEquals([
          for (final code in result.recoveryCodes)
            'digest:${code.replaceAll('-', '')}',
        ]),
      );
    });

    test('accepts a token only once', () async {
      final token = await harness.issueEnrollmentToken();
      await harness.send(
        'POST',
        enrollmentsPath,
        json: harness.enrollmentBody(TestPhone.first(), token),
      );

      final response = await harness.send(
        'POST',
        enrollmentsPath,
        json: harness.enrollmentBody(TestPhone.second(), token),
      );

      expect(response.statusCode, 410);
      expect(await errorOf(response), const RequestExpired());
    });

    test('refuses an expired token', () async {
      final token = await harness.issueEnrollmentToken();
      harness.advance(const Duration(minutes: 15));

      final response = await harness.send(
        'POST',
        enrollmentsPath,
        json: harness.enrollmentBody(TestPhone.first(), token),
      );

      expect(await errorOf(response), const RequestExpired());
    });

    test('does not burn the token on a wrong signature', () async {
      // ARRANGE
      final phone = TestPhone.first();
      final token = await harness.issueEnrollmentToken();

      // ACT
      final forged = await harness.send(
        'POST',
        enrollmentsPath,
        json: harness.enrollmentBody(phone, token, signer: phone.deviceKey),
      );
      final genuine = await harness.send(
        'POST',
        enrollmentsPath,
        json: harness.enrollmentBody(phone, token),
      );

      // ASSERT
      expect(forged.statusCode, 401);
      expect(await errorOf(forged), const NotAuthenticated());
      expect(genuine.statusCode, 201);
    });

    test('refuses the same key as both signing and device key', () async {
      final phone = TestPhone.first();
      final token = await harness.issueEnrollmentToken();
      final body = harness.enrollmentBody(phone, token);
      body['deviceKey'] = body['publicKey'];

      final response = await harness.send('POST', enrollmentsPath, json: body);

      expect(response.statusCode, 400);
      final error = await errorOf(response);
      expect(error, isA<MalformedRequest>());
      expect((error as MalformedRequest).decodeError.path, r'$.deviceKey');
    });

    test('refuses a key that is not a P-256 public key', () async {
      final token = await harness.issueEnrollmentToken();
      final body = harness.enrollmentBody(TestPhone.first(), token)
        ..['publicKey'] = 'MFkwEw==';

      final response = await harness.send('POST', enrollmentsPath, json: body);

      final error = await errorOf(response);
      expect((error as MalformedRequest).decodeError.path, r'$.publicKey');
    });

    test('refuses keys already registered, keeping the token', () async {
      // ARRANGE
      final phone = TestPhone.first();
      await harness.enroll(phone);
      final token = await harness.issueEnrollmentToken(ownerName: null);

      // ACT
      final reused = await harness.send(
        'POST',
        enrollmentsPath,
        json: harness.enrollmentBody(phone, token),
      );
      final fresh = await harness.send(
        'POST',
        enrollmentsPath,
        json: harness.enrollmentBody(TestPhone.second(), token),
      );

      // ASSERT
      expect(reused.statusCode, 400);
      expect(fresh.statusCode, 201);
    });

    test('adds a new phone to the owner and replaces the codes', () async {
      // ARRANGE
      final first = await harness.enroll(TestPhone.first());

      // ACT
      final second = await harness.enroll(TestPhone.second());

      // ASSERT
      expect(second.account, first.account);
      expect(second.deviceId, isNot(first.deviceId));
      expect(await UserRepository(harness.database).owner(), isNotNull);
      expect(
        await storedCodeDigests(),
        unorderedEquals([
          for (final code in second.recoveryCodes)
            'digest:${code.replaceAll('-', '')}',
        ]),
      );
    });

    test('refuses a malformed body before touching the token', () async {
      final response = await harness.send(
        'POST',
        enrollmentsPath,
        json: {'token': 'rovid'},
      );

      expect(response.statusCode, 400);
      expect(await errorOf(response), isA<MalformedRequest>());
    });
  });

  test('limits the enrollments per IP', () async {
    final limited = AuthHarness(rateLimit: 1);
    addTearDown(limited.close);
    await limited.send('POST', enrollmentsPath, json: const {});

    final response = await limited.send(
      'POST',
      enrollmentsPath,
      json: const {},
    );

    expect(response.statusCode, 429);
    expect(response.headers['retry-after'], '60');
    expect(await errorOf(response), const TooManyAttempts(60));
  });
}
