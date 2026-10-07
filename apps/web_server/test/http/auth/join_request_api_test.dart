import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/auth/join_request_service.dart';
import 'package:web_server/src/http/auth/auth_cookies.dart';

import 'auth_harness.dart';
import 'test_phone.dart';

// A csatlakozási kérelem teljes útja (ADR 0051 D3, Addendum 5 M1-M6): a
// fiók nélküli telefon kérelme, a böngésző várakozása, az owner döntése.

void main() {
  late AuthHarness harness;
  late TestPhone owner;
  late String ownerDeviceId;
  late TestPhone joiner;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    harness = AuthHarness();
    owner = TestPhone.first();
    ownerDeviceId = (await harness.enroll(owner)).deviceId;
    joiner = TestPhone.third();
  });

  tearDown(() => harness.close());

  Future<LoginRequestStatus> browserStatus(
    String requestId,
    String binding,
  ) async => decodeOk(
    await harness.poll(requestId, binding: binding),
    decodeLoginRequestStatus,
  );

  Future<JoinTicket> submit(LoginQrPayload qr, {TestPhone? phone}) async =>
      decodeOk(
        await harness.submitJoin(phone ?? joiner, qr),
        decodeJoinTicket,
        status: 201,
      );

  test('admits a new member and signs the waiting browser in', () async {
    // ARRANGE
    final (:qr, :binding) = await harness.openLoginRequest();

    // ACT
    final ticket = await submit(qr);
    final waiting = await browserStatus(qr.requestId, binding);
    final pending = await harness.joinStatus(ticket);
    final ownerToken = await harness.deviceToken(owner, ownerDeviceId);
    final listed = await decodeOk(
      await harness.send(
        'GET',
        joinRequestsPath,
        headers: harness.withToken(ownerToken),
      ),
      decodePendingJoinRequests,
    );
    final member = await decodeOk(
      await harness.approveJoin(owner, ownerDeviceId, ticket.joinRequestId),
      decodeMemberInfo,
    );
    final redeemed = await harness.poll(qr.requestId, binding: binding);
    final signedIn = await decodeOk(redeemed, decodeLoginRequestStatus);
    final approved = await harness.joinStatus(ticket);

    // ASSERT
    expect(waiting.state, LoginRequestState.joinPending);
    expect(pending.state, JoinRequestState.pending);
    expect(listed, hasLength(1));
    expect(listed.single.name, 'Dóri');
    expect(listed.single.ip, phoneIp);
    expect(listed.single.model, 'SM-S921B');
    expect(member.account.name, 'Dóri');
    expect(member.account.role, UserRole.crew);
    expect(member.devices, hasLength(1));
    expect(signedIn.state, LoginRequestState.signedIn);
    expect(signedIn.account, member.account);
    expect(cookiesOf(redeemed)[sessionCookieName], isNotEmpty);
    expect(approved.state, JoinRequestState.approved);
    expect(approved.account, member.account);
    expect(approved.deviceId, member.devices.single.id);
  });

  test('lets the admitted phone ask for a device token', () async {
    final (:userId, :deviceId) = await harness.admitMember(
      owner,
      ownerDeviceId,
      joiner,
    );

    final token = await harness.deviceToken(joiner, deviceId);
    final me = await decodeOk(
      await harness.send('GET', mePath, headers: harness.withToken(token)),
      decodeAccountInfo,
    );

    expect(me.userId, userId);
    expect(me.role, UserRole.crew);
  });

  test('gives an existing member a new phone under the same name', () async {
    // ARRANGE
    final dori = await harness.admitMember(owner, ownerDeviceId, joiner);
    harness.advance(const Duration(minutes: 1));
    final (:qr, binding: _) = await harness.openLoginRequest();
    final ticket = await decodeOk(
      await harness.submitJoin(TestPhone.second(), qr, name: 'Dóri új'),
      decodeJoinTicket,
      status: 201,
    );

    // ACT
    final member = await decodeOk(
      await harness.approveJoin(
        owner,
        ownerDeviceId,
        ticket.joinRequestId,
        memberId: dori.userId,
      ),
      decodeMemberInfo,
    );

    // ASSERT
    expect(member.account.userId, dori.userId);
    expect(member.account.name, 'Dóri');
    expect(member.devices, hasLength(2));
    expect(member.devices.first.id, dori.deviceId);
  });

  test('shows a rejected request as expired to browser and phone', () async {
    // ARRANGE
    final (:qr, :binding) = await harness.openLoginRequest();
    final ticket = await submit(qr);
    final ownerToken = await harness.deviceToken(owner, ownerDeviceId);
    final rejection = joinRequestRejectionPath(ticket.joinRequestId);

    // ACT
    final rejected = await harness.send(
      'POST',
      rejection,
      headers: harness.withToken(ownerToken),
    );
    final again = await harness.send(
      'POST',
      rejection,
      headers: harness.withToken(ownerToken),
    );
    final browser = await browserStatus(qr.requestId, binding);
    final phone = await harness.joinStatus(ticket);
    final tooLate = await harness.approveJoin(
      owner,
      ownerDeviceId,
      ticket.joinRequestId,
    );

    // ASSERT
    expect(rejected.statusCode, 204);
    expect(await errorOf(again), const RequestExpired());
    expect(browser.state, LoginRequestState.expired);
    expect(phone.state, JoinRequestState.notApproved);
    expect(await errorOf(tooLate), const RequestExpired());
  });

  test('keeps a waiting login request from registered phones', () async {
    final (:qr, binding: _) = await harness.openLoginRequest();
    await submit(qr);
    final ownerToken = await harness.deviceToken(owner, ownerDeviceId);

    final opened = await harness.open(qr, ownerToken);
    final approved = await harness.approve(qr, owner, ownerDeviceId);

    expect(await errorOf(opened), const RequestExpired());
    expect(await errorOf(approved), const RequestExpired());
  });

  test('drops an undecided request after a day', () async {
    final (:qr, binding: _) = await harness.openLoginRequest();
    final ticket = await submit(qr);
    harness.advance(const Duration(hours: 24, seconds: 1));
    final ownerToken = await harness.deviceToken(owner, ownerDeviceId);

    final listed = await decodeOk(
      await harness.send(
        'GET',
        joinRequestsPath,
        headers: harness.withToken(ownerToken),
      ),
      decodePendingJoinRequests,
    );
    final status = await harness.joinStatus(ticket);

    expect(listed, isEmpty);
    expect(status.state, JoinRequestState.notApproved);
  });

  test('answers not approved once the new phone is revoked', () async {
    // ARRANGE
    final (:qr, binding: _) = await harness.openLoginRequest();
    final ticket = await submit(qr);
    final member = await decodeOk(
      await harness.approveJoin(owner, ownerDeviceId, ticket.joinRequestId),
      decodeMemberInfo,
    );
    final deviceId = member.devices.single.id;
    final ownerToken = await harness.deviceToken(owner, ownerDeviceId);
    final action = await harness.signedAction(
      owner,
      ownerDeviceId,
      ownerToken,
      kind: DeviceAction.revokeDevice,
      target: deviceId,
    );

    // ACT
    final revoked = await harness.send(
      'POST',
      deviceRevocationPath(deviceId),
      json: encodeSignedAction(action),
      headers: harness.withToken(ownerToken),
    );
    final status = await harness.joinStatus(ticket);

    // ASSERT
    expect(revoked.statusCode, 204);
    expect(status.state, JoinRequestState.notApproved);
  });

  test('refuses an unknown member or an unknown request', () async {
    final (:qr, binding: _) = await harness.openLoginRequest();
    final ticket = await submit(qr);

    final unknownMember = await harness.approveJoin(
      owner,
      ownerDeviceId,
      ticket.joinRequestId,
      memberId: 'u-nobody',
    );
    final unknownRequest = await harness.approveJoin(
      owner,
      ownerDeviceId,
      'AAECAwQFBgcICQoLDA0ODw',
    );

    expect(await errorOf(unknownMember), const NotAllowed());
    expect(await errorOf(unknownRequest), const RequestExpired());
  });

  test('approves only once', () async {
    final (:qr, binding: _) = await harness.openLoginRequest();
    final ticket = await submit(qr);

    final first = await harness.approveJoin(
      owner,
      ownerDeviceId,
      ticket.joinRequestId,
    );
    final second = await harness.approveJoin(
      owner,
      ownerDeviceId,
      ticket.joinRequestId,
    );

    expect(first.statusCode, 200);
    expect(await errorOf(second), const RequestExpired());
  });

  test('keeps the approval for the phone after the browser gave up', () async {
    final (:qr, :binding) = await harness.openLoginRequest();
    final ticket = await submit(qr);
    harness.advance(const Duration(minutes: 11));

    final approval = await harness.approveJoin(
      owner,
      ownerDeviceId,
      ticket.joinRequestId,
    );
    final browser = await browserStatus(qr.requestId, binding);
    final phone = await harness.joinStatus(ticket);

    expect(approval.statusCode, 200);
    expect(browser.state, LoginRequestState.expired);
    expect(phone.state, JoinRequestState.approved);
  });

  test('answers not approved for an unknown request', () async {
    final ticket = JoinTicket(
      joinRequestId: 'AAECAwQFBgcICQoLDA0ODw',
      statusToken: 'ICEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj8',
      expiresAt: DateTime.utc(2026, 10, 8),
    );

    expect(
      await harness.joinStatus(ticket),
      const JoinRequestStatus(state: JoinRequestState.notApproved),
    );
  });

  test('refuses a second request on the same login request', () async {
    final (:qr, binding: _) = await harness.openLoginRequest();
    await submit(qr);

    final second = await harness.submitJoin(TestPhone.second(), qr);

    expect(await errorOf(second), const RequestExpired());
  });

  test('refuses a forged signature and registered keys', () async {
    final (:qr, binding: _) = await harness.openLoginRequest();

    final forged = await harness.send(
      'POST',
      joinRequestsPath,
      json: harness.joinBody(joiner, qr, signer: joiner.deviceKey),
    );
    final registered = await harness.submitJoin(owner, qr);
    final waiting = await submit(qr);

    expect(await errorOf(forged), const NotAuthenticated());
    expect(await errorOf(registered), isA<MalformedRequest>());
    expect(waiting.joinRequestId, isNotEmpty);
  });

  test('refuses keys that already wait in another request', () async {
    final first = await harness.openLoginRequest();
    final second = await harness.openLoginRequest();
    await submit(first.qr);

    final repeated = await harness.submitJoin(joiner, second.qr);

    expect(await errorOf(repeated), isA<MalformedRequest>());
  });

  test('keeps at most five undecided requests', () async {
    // ARRANGE
    for (var i = 1; i <= maximumPendingJoinRequests; i++) {
      final (:qr, binding: _) = await harness.openLoginRequest();
      await submit(qr, phone: _numberedPhone(i));
      harness.advance(const Duration(minutes: 1));
    }
    final (:qr, binding: _) = await harness.openLoginRequest();

    // ACT
    final sixth = await harness.submitJoin(_numberedPhone(6), qr);

    // ASSERT
    // A legelső kérelem 24 óra mínusz 5 perc múlva jár le.
    const wait = 24 * 60 * 60 - 5 * 60;
    expect(await errorOf(sixth), const TooManyAttempts(wait));
    expect(sixth.headers['retry-after'], '$wait');
  });

  test('lets only the owner list and decide', () async {
    // ARRANGE
    final dori = await harness.admitMember(owner, ownerDeviceId, joiner);
    final (:qr, binding: _) = await harness.openLoginRequest();
    final ticket = await submit(qr, phone: TestPhone.second());
    final crewToken = await harness.deviceToken(joiner, dori.deviceId);
    final crew = harness.withToken(crewToken);

    // ACT
    final list = await harness.send('GET', joinRequestsPath, headers: crew);
    final reject = await harness.send(
      'POST',
      joinRequestRejectionPath(ticket.joinRequestId),
      headers: crew,
    );
    final approve = await harness.approveJoin(
      joiner,
      dori.deviceId,
      ticket.joinRequestId,
    );

    // ASSERT
    expect(await errorOf(list), const NotAllowed());
    expect(await errorOf(reject), const NotAllowed());
    expect(await errorOf(approve), const NotAllowed());
  });

  test('refuses the owner as the member for a new phone', () async {
    final (:qr, binding: _) = await harness.openLoginRequest();
    final ticket = await submit(qr);
    final ownerId = (await harness.enroll(TestPhone.second())).account.userId;

    final response = await harness.approveJoin(
      owner,
      ownerDeviceId,
      ticket.joinRequestId,
      memberId: ownerId,
    );

    expect(await errorOf(response), const NotAllowed());
  });

  test('refuses an approval signed for another target', () async {
    final dori = await harness.admitMember(owner, ownerDeviceId, joiner);
    final (:qr, binding: _) = await harness.openLoginRequest();
    final ticket = await submit(qr, phone: TestPhone.second());

    // Az aláírás új tagra szól, a kérés egy meglévő tagot nevez meg.
    final response = await harness.approveJoin(
      owner,
      ownerDeviceId,
      ticket.joinRequestId,
      memberId: dori.userId,
      signedMemberId: 'new-member',
    );

    expect(await errorOf(response), const NotAuthenticated());
  });

  test('refuses a device token challenge as an action challenge', () async {
    // ARRANGE
    final (:qr, binding: _) = await harness.openLoginRequest();
    final ticket = await submit(qr);
    final ownerToken = await harness.deviceToken(owner, ownerDeviceId);
    final deviceChallenge = await decodeOk(
      await harness.send(
        'POST',
        deviceChallengesPath,
        json: encodeDeviceChallengeRequest(ownerDeviceId),
      ),
      decodeIssuedSecret,
      status: 201,
    );
    final target = joinApprovalTarget(
      joinRequestId: ticket.joinRequestId,
      memberId: null,
    );
    final action = SignedAction(
      challenge: deviceChallenge.value,
      signature: owner.signingKey.sign(
        deviceActionMessage(
          origin: testOrigin,
          deviceId: ownerDeviceId,
          challenge: deviceChallenge.value,
          action: DeviceAction.approveJoin,
          target: target,
        ),
      ),
    );

    // ACT
    final response = await harness.send(
      'POST',
      joinRequestApprovalPath(ticket.joinRequestId),
      json: encodeJoinApproval(JoinApproval(action: action)),
      headers: harness.withToken(ownerToken),
    );

    // ASSERT
    expect(await errorOf(response), const RequestExpired());
  });

  test('limits the join requests per address', () async {
    final limited = AuthHarness(joinRateLimit: 1);
    addTearDown(limited.close);
    await limited.enroll(owner);
    final first = await limited.openLoginRequest();
    final second = await limited.openLoginRequest();

    final allowed = await limited.submitJoin(joiner, first.qr);
    final refused = await limited.submitJoin(TestPhone.second(), second.qr);

    expect(allowed.statusCode, 201);
    expect(refused.statusCode, 429);
    expect(refused.headers['retry-after'], isNotNull);
  });
}

// Egy-egy külön kulcspárú telefon a korlát-teszthez; a skalárok kicsik, de
// érvényesek (1 <= d < n).
TestPhone _numberedPhone(int index) => TestPhone(
  signingKeyHex: (1000 + index).toRadixString(16).padLeft(64, '0'),
  deviceKeyHex: (2000 + index).toRadixString(16).padLeft(64, '0'),
);
