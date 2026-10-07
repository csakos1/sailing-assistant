import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/auth_db/device_repository.dart';
import 'package:web_server/src/http/auth/auth_cookies.dart';

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

  Future<LoginRequestStatus> statusOf(
    String requestId, {
    String? binding,
  }) async => decodeOk(
    await harness.poll(requestId, binding: binding),
    decodeLoginRequestStatus,
  );

  test('signs the browser in through the whole QR flow', () async {
    // ARRANGE
    final (:qr, :binding) = await harness.openLoginRequest();
    final token = await harness.deviceToken(phone, deviceId);

    // ACT
    final pending = await statusOf(qr.requestId, binding: binding);
    final details = await decodeOk(
      await harness.open(qr, token),
      decodeBrowserLoginDetails,
    );
    final opened = await statusOf(qr.requestId, binding: binding);
    final approval = await harness.approve(qr, phone, deviceId);
    final redeemed = await harness.poll(qr.requestId, binding: binding);
    final signedIn = await decodeOk(redeemed, decodeLoginRequestStatus);

    // ASSERT
    expect(qr.origin, testOrigin);
    expect(pending.state, LoginRequestState.pending);
    expect(
      details,
      const BrowserLoginDetails(ip: browserIp, browser: 'Chrome', os: 'Linux'),
    );
    expect(opened.state, LoginRequestState.opened);
    expect(approval.statusCode, 204);
    expect(signedIn.state, LoginRequestState.signedIn);
    expect(signedIn.account?.name, 'Ákos');
    final cookies = cookiesOf(redeemed);
    expect(cookies[sessionCookieName], isNotEmpty);
    expect(cookies[loginCookieName], isEmpty);
    expect(
      redeemed.headersAll['set-cookie']?.first,
      allOf(
        contains('HttpOnly'),
        contains('Secure'),
        contains('SameSite=Strict'),
        contains('Path=/'),
        contains('Max-Age=7776000'),
      ),
    );
  });

  test('sets an HttpOnly binding cookie for the new request', () async {
    final response = await harness.send(
      'POST',
      loginRequestsPath,
      ip: browserIp,
      headers: webClient,
    );

    expect(response.statusCode, 201);
    expect(
      response.headersAll['set-cookie']?.single,
      allOf(
        startsWith('$loginCookieName='),
        contains('HttpOnly'),
        contains('Max-Age=600'),
      ),
    );
  });

  test('redeems an approved request only once', () async {
    final (:qr, :binding) = await harness.openLoginRequest();
    await harness.approve(qr, phone, deviceId);
    await harness.poll(qr.requestId, binding: binding);

    final second = await statusOf(qr.requestId, binding: binding);

    expect(second.state, LoginRequestState.expired);
  });

  test('tells nothing to a browser without the binding cookie', () async {
    // ARRANGE
    final (:qr, binding: _) = await harness.openLoginRequest();
    final other = await harness.openLoginRequest();
    await harness.approve(qr, phone, deviceId);

    // ACT
    final withoutCookie = await statusOf(qr.requestId);
    final withOtherCookie = await statusOf(
      qr.requestId,
      binding: other.binding,
    );

    // ASSERT
    expect(withoutCookie.state, LoginRequestState.expired);
    expect(withOtherCookie.state, LoginRequestState.expired);
  });

  test('lets an unopened request expire after 60 seconds', () async {
    final (:qr, :binding) = await harness.openLoginRequest();
    final token = await harness.deviceToken(phone, deviceId);
    harness.advance(const Duration(seconds: 60));

    final status = await statusOf(qr.requestId, binding: binding);
    final opening = await harness.open(qr, token);

    expect(status.state, LoginRequestState.expired);
    expect(opening.statusCode, 410);
    expect(await errorOf(opening), const RequestExpired());
  });

  test('keeps an opened request for 60 seconds after the opening', () async {
    final (:qr, :binding) = await harness.openLoginRequest();
    final token = await harness.deviceToken(phone, deviceId);
    harness.advance(const Duration(seconds: 50));
    await harness.open(qr, token);
    harness.advance(const Duration(seconds: 50));

    final approval = await harness.approve(qr, phone, deviceId);

    expect(approval.statusCode, 204);
    final status = await statusOf(qr.requestId, binding: binding);
    expect(status.state, LoginRequestState.signedIn);
  });

  test('drops an approval that is not redeemed in 60 seconds', () async {
    final (:qr, :binding) = await harness.openLoginRequest();
    await harness.approve(qr, phone, deviceId);
    harness.advance(const Duration(seconds: 60));

    final status = await statusOf(qr.requestId, binding: binding);

    expect(status.state, LoginRequestState.expired);
  });

  test('gives no session if the device is revoked before redeeming', () async {
    final (:qr, :binding) = await harness.openLoginRequest();
    await harness.approve(qr, phone, deviceId);
    await DeviceRepository(
      harness.database,
    ).revoke(deviceId, now: harness.now);

    final response = await harness.poll(qr.requestId, binding: binding);
    final status = await decodeOk(response, decodeLoginRequestStatus);

    expect(status.state, LoginRequestState.expired);
    expect(cookiesOf(response), isNot(contains(sessionCookieName)));
  });

  test('refuses to open with a challenge other than the QR one', () async {
    final (:qr, binding: _) = await harness.openLoginRequest();
    final other = await harness.openLoginRequest();
    final token = await harness.deviceToken(phone, deviceId);
    final forged = LoginQrPayload(
      origin: qr.origin,
      requestId: qr.requestId,
      challenge: other.qr.challenge,
    );

    final response = await harness.open(forged, token);

    expect(await errorOf(response), const RequestExpired());
  });

  test('refuses to open without a device token', () async {
    final (:qr, binding: _) = await harness.openLoginRequest();

    final response = await harness.send(
      'POST',
      loginRequestOpenPath(qr.requestId),
      json: encodeLoginRequestOpening(qr.challenge),
    );

    expect(response.statusCode, 401);
  });

  test('refuses an approval signed with the device key', () async {
    final (:qr, :binding) = await harness.openLoginRequest();

    final response = await harness.approve(
      qr,
      phone,
      deviceId,
      signer: phone.deviceKey,
    );

    expect(response.statusCode, 401);
    expect(await errorOf(response), const NotAuthenticated());
    final status = await statusOf(qr.requestId, binding: binding);
    expect(status.state, LoginRequestState.pending);
  });

  test('refuses an approval signed for another request', () async {
    final first = await harness.openLoginRequest();
    final second = await harness.openLoginRequest();
    final signedForFirst = LoginQrPayload(
      origin: testOrigin,
      requestId: second.qr.requestId,
      challenge: first.qr.challenge,
    );

    final response = await harness.approve(signedForFirst, phone, deviceId);

    expect(await errorOf(response), const NotAuthenticated());
  });

  test('accepts only the first of two approvals', () async {
    final (:qr, binding: _) = await harness.openLoginRequest();
    await harness.approve(qr, phone, deviceId);

    final again = await harness.approve(qr, phone, deviceId);

    expect(again.statusCode, 410);
  });

  test('refuses an approval from a revoked device', () async {
    final (:qr, binding: _) = await harness.openLoginRequest();
    await DeviceRepository(
      harness.database,
    ).revoke(deviceId, now: harness.now);

    final response = await harness.approve(qr, phone, deviceId);

    expect(response.statusCode, 403);
    expect(await errorOf(response), const DeviceRevoked());
  });

  test('limits the new requests per IP', () async {
    final limited = AuthHarness(rateLimit: 2);
    addTearDown(limited.close);
    await limited.openLoginRequest();
    await limited.openLoginRequest();

    final response = await limited.send(
      'POST',
      loginRequestsPath,
      ip: browserIp,
      headers: webClient,
    );
    final otherBrowser = await limited.send(
      'POST',
      loginRequestsPath,
      ip: '198.51.100.21',
      headers: webClient,
    );

    expect(response.statusCode, 429);
    expect(otherBrowser.statusCode, 201);
  });
}
