import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:web_server/src/http/auth/auth_cookies.dart';

import 'auth_harness.dart';
import 'test_phone.dart';

// A tagok és az eszközeik kezelése (ADR 0051 Addendum 1 H9, Addendum 5
// M7): lista, eszköz visszavonása, tag eltávolítása, és az önkizárás elleni
// védelem.

void main() {
  late AuthHarness harness;
  late TestPhone owner;
  late String ownerDeviceId;
  late TestPhone crewPhone;
  late ({String userId, String deviceId}) dori;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    harness = AuthHarness();
    owner = TestPhone.first();
    ownerDeviceId = (await harness.enroll(owner)).deviceId;
    crewPhone = TestPhone.third();
    dori = await harness.admitMember(owner, ownerDeviceId, crewPhone);
  });

  tearDown(() => harness.close());

  Future<Response> signedPost(
    String path, {
    required DeviceAction kind,
    required String target,
    TestPhone? phone,
    String? deviceId,
    TestKey? signer,
  }) async {
    final actor = phone ?? owner;
    final actorDeviceId = deviceId ?? ownerDeviceId;
    final token = await harness.deviceToken(actor, actorDeviceId);
    final action = await harness.signedAction(
      actor,
      actorDeviceId,
      token,
      kind: kind,
      target: target,
      signer: signer,
    );
    return harness.send(
      'POST',
      path,
      json: encodeSignedAction(action),
      headers: harness.withToken(token),
    );
  }

  Future<Response> revoke(String deviceId, {TestKey? signer}) => signedPost(
    deviceRevocationPath(deviceId),
    kind: DeviceAction.revokeDevice,
    target: deviceId,
    signer: signer,
  );

  Future<Response> remove(String userId) => signedPost(
    memberRemovalPath(userId),
    kind: DeviceAction.removeUser,
    target: userId,
  );

  Future<List<MemberInfo>> members() async {
    final token = await harness.deviceToken(owner, ownerDeviceId);
    return decodeOk(
      await harness.send('GET', membersPath, headers: harness.withToken(token)),
      decodeMembers,
    );
  }

  test('lists the owner first, then the crew with active devices', () async {
    final list = await members();

    expect(list.map((member) => member.account.name), ['Ákos', 'Dóri']);
    expect(list.first.account.role, UserRole.owner);
    expect(list.first.devices.single.id, ownerDeviceId);
    expect(list.last.devices.single.id, dori.deviceId);
  });

  test('keeps the member list from the crew', () async {
    final token = await harness.deviceToken(crewPhone, dori.deviceId);

    final response = await harness.send(
      'GET',
      membersPath,
      headers: harness.withToken(token),
    );

    expect(await errorOf(response), const NotAllowed());
  });

  test('revokes a phone with its tokens and sessions', () async {
    // ARRANGE
    final crewToken = await harness.deviceToken(crewPhone, dori.deviceId);
    final session = await harness.signIn(crewPhone, dori.deviceId);

    // ACT
    final response = await revoke(dori.deviceId);

    // ASSERT
    expect(response.statusCode, 204);
    final me = await harness.send(
      'GET',
      mePath,
      headers: harness.withToken(crewToken),
    );
    expect(await errorOf(me), const NotAuthenticated());
    final archive = await harness.send(
      'GET',
      racesPath,
      cookies: {sessionCookieName: session},
      headers: webClient,
      handler: harness.archive,
    );
    expect(archive.statusCode, 401);
    expect((await members()).last.devices, isEmpty);
    expect(await errorOf(await revoke(dori.deviceId)), const RequestExpired());
  });

  test('answers expired for an unknown phone', () async {
    final response = await revoke('d-nobody');

    expect(await errorOf(response), const RequestExpired());
  });

  test('refuses to revoke the asking phone', () async {
    final response = await revoke(ownerDeviceId);

    expect(await errorOf(response), const NotAllowed());
    expect((await members()).first.devices, hasLength(1));
  });

  test("lets the owner revoke another of the owner's phones", () async {
    final second = await harness.enroll(TestPhone.second());

    final response = await revoke(second.deviceId);

    expect(response.statusCode, 204);
    expect((await members()).first.devices.single.id, ownerDeviceId);
  });

  test('refuses an action signed with the quiet device key', () async {
    final response = await revoke(dori.deviceId, signer: owner.deviceKey);

    expect(await errorOf(response), const NotAuthenticated());
    expect((await members()).last.devices, hasLength(1));
  });

  test('lets no crew member revoke or remove', () async {
    final revoked = await signedPost(
      deviceRevocationPath(ownerDeviceId),
      kind: DeviceAction.revokeDevice,
      target: ownerDeviceId,
      phone: crewPhone,
      deviceId: dori.deviceId,
    );
    final removed = await signedPost(
      memberRemovalPath(dori.userId),
      kind: DeviceAction.removeUser,
      target: dori.userId,
      phone: crewPhone,
      deviceId: dori.deviceId,
    );

    expect(await errorOf(revoked), const NotAllowed());
    expect(await errorOf(removed), const NotAllowed());
  });

  test('removes a member with phones and sessions', () async {
    // ARRANGE
    final session = await harness.signIn(crewPhone, dori.deviceId);

    // ACT
    final response = await remove(dori.userId);

    // ASSERT
    expect(response.statusCode, 204);
    expect((await members()).map((member) => member.account.name), ['Ákos']);
    final archive = await harness.send(
      'GET',
      racesPath,
      cookies: {sessionCookieName: session},
      headers: webClient,
      handler: harness.archive,
    );
    expect(archive.statusCode, 401);
    final challenge = await harness.send(
      'POST',
      deviceChallengesPath,
      json: encodeDeviceChallengeRequest(dori.deviceId),
    );
    expect(await errorOf(challenge), const DeviceRevoked());
    expect(await errorOf(await remove(dori.userId)), const RequestExpired());
  });

  test('refuses to remove the owner', () async {
    final ownerId = (await members()).first.account.userId;

    final response = await remove(ownerId);

    expect(await errorOf(response), const NotAllowed());
  });
}
