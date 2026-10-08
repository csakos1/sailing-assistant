import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'auth_harness.dart';
import 'test_phone.dart';

// A tartalék belépés beállításai a telefonról (ADR 0051 Addendum 1 H9,
// Addendum 6 N4): állapot, jelszó, kódok újragenerálása.

void main() {
  late AuthHarness harness;
  late TestPhone owner;
  late EnrollmentResult enrollment;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    harness = AuthHarness();
    owner = TestPhone.first();
    enrollment = await harness.enroll(owner);
  });

  tearDown(() => harness.close());

  Future<Response> securityWith(String token) => harness.send(
    'GET',
    accountSecurityPath,
    headers: harness.withToken(token),
  );

  Future<Response> regenerate(TestPhone phone, String deviceId) async {
    final token = await harness.deviceToken(phone, deviceId);
    final action = await harness.signedAction(
      phone,
      deviceId,
      token,
      kind: DeviceAction.regenerateRecoveryCodes,
      target: '-',
    );
    return harness.send(
      'POST',
      accountRecoveryCodesPath,
      json: encodeSignedAction(action),
      headers: harness.withToken(token),
    );
  }

  test('reports no password and ten codes after enrollment', () async {
    final token = await harness.deviceToken(owner, enrollment.deviceId);

    final security = await decodeOk(
      await securityWith(token),
      decodeAccountSecurity,
    );

    expect(
      security,
      AccountSecurity(
        recoveryCodesLeft: 10,
        recoveryCodesGeneratedAt: harness.now,
      ),
    );
  });

  test('sets the password and reports when', () async {
    final response = await harness.setPassword(
      owner,
      enrollment.deviceId,
      'hajo-lola-balaton-2026',
    );
    final token = await harness.deviceToken(owner, enrollment.deviceId);
    final security = await decodeOk(
      await securityWith(token),
      decodeAccountSecurity,
    );

    expect(response.statusCode, 204);
    expect(security.passwordSetAt, harness.now);
  });

  test('refuses a short password without using up the signature', () async {
    // ARRANGE
    final token = await harness.deviceToken(owner, enrollment.deviceId);
    final action = await harness.signedAction(
      owner,
      enrollment.deviceId,
      token,
      kind: DeviceAction.setPassword,
      target: '-',
    );
    Future<Response> change(String password) => harness.send(
      'POST',
      accountPasswordPath,
      json: encodePasswordChange(
        PasswordChange(password: password, action: action),
      ),
      headers: harness.withToken(token),
    );

    // ACT
    final short = await change('rovid');
    final valid = await change('hajo-lola-balaton-2026');

    // ASSERT
    expect(await errorOf(short), isA<MalformedRequest>());
    expect(valid.statusCode, 204);
  });

  test('refuses a password change signed with the quiet key', () async {
    final token = await harness.deviceToken(owner, enrollment.deviceId);
    final action = await harness.signedAction(
      owner,
      enrollment.deviceId,
      token,
      kind: DeviceAction.setPassword,
      target: '-',
      signer: owner.deviceKey,
    );

    final response = await harness.send(
      'POST',
      accountPasswordPath,
      json: encodePasswordChange(
        PasswordChange(password: 'hajo-lola-balaton-2026', action: action),
      ),
      headers: harness.withToken(token),
    );

    expect(await errorOf(response), const NotAuthenticated());
  });

  test('replaces every recovery code', () async {
    // ARRANGE
    final oldCode = enrollment.recoveryCodes.first;
    final enrolledAt = harness.now;
    harness.advance(const Duration(days: 3));

    // ACT
    final codes = await decodeOk(
      await regenerate(owner, enrollment.deviceId),
      decodeIssuedRecoveryCodes,
      status: 201,
    );

    // ASSERT
    expect(codes.codes, hasLength(10));
    expect(codes.codes, isNot(contains(oldCode)));
    expect(
      await errorOf(await harness.fallbackLogin(oldCode)),
      const NotAuthenticated(),
    );
    expect((await harness.fallbackLogin(codes.codes.first)).statusCode, 200);
    final token = await harness.deviceToken(owner, enrollment.deviceId);
    final security = await decodeOk(
      await securityWith(token),
      decodeAccountSecurity,
    );
    expect(security.recoveryCodesLeft, 9);
    // A felhasznalt kod sem tolja el a keszlet idejet (Z12).
    expect(security.recoveryCodesGeneratedAt, harness.now);
    expect(security.recoveryCodesGeneratedAt, isNot(enrolledAt));
  });

  test('keeps every setting from the crew', () async {
    // ARRANGE
    final crewPhone = TestPhone.third();
    final dori = await harness.admitMember(
      owner,
      enrollment.deviceId,
      crewPhone,
    );
    final token = await harness.deviceToken(crewPhone, dori.deviceId);

    // ACT
    final security = await securityWith(token);
    final password = await harness.setPassword(
      crewPhone,
      dori.deviceId,
      'hajo-lola-balaton-2026',
    );
    final codes = await regenerate(crewPhone, dori.deviceId);

    // ASSERT
    expect(await errorOf(security), const NotAllowed());
    expect(await errorOf(password), const NotAllowed());
    expect(await errorOf(codes), const NotAllowed());
  });
}
