import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';

import 'auth_harness.dart';
import 'test_phone.dart';

// A belépési események, a gyanús-jelzés és a szalag (ADR 0051 D7, Addendum
// 3 K9, Addendum 6 N5, N6, N9). A böngésző Budapestről, a jóváhagyó
// telefon (alapból) Berlinből jön, így a QR-belépés gyanús.

const Map<String, ({String? country, String? city})> _apart = {
  browserIp: (country: 'HU', city: 'Budapest'),
  phoneIp: (country: 'DE', city: 'Berlin'),
};

void main() {
  late AuthHarness harness;
  late TestPhone owner;
  late String ownerDeviceId;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  Future<void> start(
    Map<String, ({String? country, String? city})> where,
  ) async {
    harness = AuthHarness(locations: where);
    owner = TestPhone.first();
    ownerDeviceId = (await harness.enroll(owner)).deviceId;
  }

  tearDown(() => harness.close());

  Future<LoginBanner> bannerOf(TestPhone phone, String deviceId) async {
    final token = await harness.deviceToken(phone, deviceId);
    return decodeOk(
      await harness.send('GET', bannerPath, headers: harness.withToken(token)),
      decodeLoginBanner,
    );
  }

  Future<List<WebSession>> ownerSessions() async {
    final token = await harness.deviceToken(owner, ownerDeviceId);
    return decodeOk(
      await harness.send(
        'GET',
        sessionsPath,
        headers: harness.withToken(token),
      ),
      decodeWebSessions,
    );
  }

  test('flags a QR sign-in approved from another country', () async {
    // ARRANGE
    await start(_apart);
    final (:qr, binding: _) = await harness.openLoginRequest();
    final token = await harness.deviceToken(owner, ownerDeviceId);

    // ACT
    final details = await decodeOk(
      await harness.open(qr, token),
      decodeBrowserLoginDetails,
    );
    await harness.signIn(owner, ownerDeviceId);
    final banner = await bannerOf(owner, ownerDeviceId);
    final sessions = await ownerSessions();

    // ASSERT
    expect(details.country, 'HU');
    expect(details.city, 'Budapest');
    final login = banner.suspicious.single;
    expect(login.method, LoginMethod.qr);
    expect(login.country, 'HU');
    expect(login.city, 'Budapest');
    expect(login.sessionId, sessions.single.id);
    expect(sessions.single.isSuspicious, isTrue);
    expect(sessions.single.country, 'HU');
    expect(banner.pendingJoinRequests, 0);
  });

  test('keeps a QR sign-in from the same country quiet', () async {
    await start({
      browserIp: (country: 'HU', city: 'Budapest'),
      phoneIp: (country: 'HU', city: 'Siófok'),
    });

    await harness.signIn(owner, ownerDeviceId);

    expect((await bannerOf(owner, ownerDeviceId)).suspicious, isEmpty);
    expect((await ownerSessions()).single.isSuspicious, isFalse);
  });

  test('keeps a sign-in with an unknown country quiet', () async {
    await start(const {});

    await harness.signIn(owner, ownerDeviceId);

    expect((await bannerOf(owner, ownerDeviceId)).suspicious, isEmpty);
  });

  test('shows the crew their own, the owner all and the requests', () async {
    // ARRANGE
    await start(_apart);
    final crewPhone = TestPhone.third();
    final dori = await harness.admitMember(owner, ownerDeviceId, crewPhone);
    await harness.signIn(owner, ownerDeviceId);
    harness.advance(const Duration(minutes: 1));
    await harness.signIn(crewPhone, dori.deviceId);
    final (:qr, binding: _) = await harness.openLoginRequest();
    await harness.submitJoin(TestPhone.second(), qr, name: 'Gergő');

    // ACT
    final ownerView = await bannerOf(owner, ownerDeviceId);
    final crewView = await bannerOf(crewPhone, dori.deviceId);

    // ASSERT
    expect(ownerView.suspicious.map((login) => login.userName), [
      'Dóri',
      'Ákos',
    ]);
    expect(ownerView.pendingJoinRequests, 1);
    expect(crewView.suspicious.map((login) => login.userId), [dori.userId]);
    expect(crewView.pendingJoinRequests, 0);
  });

  test('records the place of a join request', () async {
    await start(_apart);
    final (:qr, binding: _) = await harness.openLoginRequest();
    await harness.submitJoin(TestPhone.third(), qr);
    final token = await harness.deviceToken(owner, ownerDeviceId);

    final pending = await decodeOk(
      await harness.send(
        'GET',
        joinRequestsPath,
        headers: harness.withToken(token),
      ),
      decodePendingJoinRequests,
    );

    expect(pending.single.country, 'DE');
    expect(pending.single.city, 'Berlin');
  });

  test('acknowledges on the server for every phone', () async {
    // ARRANGE
    await start(_apart);
    await harness.signIn(owner, ownerDeviceId);
    final eventId = (await bannerOf(owner, ownerDeviceId)).suspicious.single.id;
    final token = await harness.deviceToken(owner, ownerDeviceId);

    // ACT
    final first = await harness.send(
      'POST',
      loginEventAcknowledgementPath(eventId),
      headers: harness.withToken(token),
    );
    final unknown = await harness.send(
      'POST',
      loginEventAcknowledgementPath('e-nobody'),
      headers: harness.withToken(token),
    );

    // ASSERT
    expect(first.statusCode, 204);
    expect(unknown.statusCode, 204);
    expect((await bannerOf(owner, ownerDeviceId)).suspicious, isEmpty);
    expect((await ownerSessions()).single.isSuspicious, isTrue);
  });

  test("keeps the crew from acknowledging the owner's sign-in", () async {
    await start(_apart);
    final crewPhone = TestPhone.third();
    final dori = await harness.admitMember(owner, ownerDeviceId, crewPhone);
    await harness.signIn(owner, ownerDeviceId);
    final eventId = (await bannerOf(owner, ownerDeviceId)).suspicious.single.id;
    final crewToken = await harness.deviceToken(crewPhone, dori.deviceId);

    final response = await harness.send(
      'POST',
      loginEventAcknowledgementPath(eventId),
      headers: harness.withToken(crewToken),
    );

    expect(await errorOf(response), const NotAllowed());
    expect((await bannerOf(owner, ownerDeviceId)).suspicious, hasLength(1));
  });

  test('acknowledges a sign-in when its session is signed out', () async {
    await start(_apart);
    await harness.signIn(owner, ownerDeviceId);
    final sessionId = (await ownerSessions()).single.id;
    final token = await harness.deviceToken(owner, ownerDeviceId);

    final response = await harness.send(
      'DELETE',
      sessionPath(sessionId),
      headers: harness.withToken(token),
    );

    expect(response.statusCode, 204);
    expect((await bannerOf(owner, ownerDeviceId)).suspicious, isEmpty);
  });

  test('forgets an unacknowledged sign-in after thirty days', () async {
    await start(_apart);
    await harness.signIn(owner, ownerDeviceId);
    harness.advance(const Duration(days: 30, seconds: 1));

    final banner = await bannerOf(owner, ownerDeviceId);

    expect(banner.suspicious, isEmpty);
  });
}
