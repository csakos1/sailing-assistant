import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/http/auth/auth_cookies.dart';

import 'auth_harness.dart';
import 'test_phone.dart';

// A webes munkamenetek listája, a kiléptetés és a saját név átírása (ADR
// 0051 D7, Addendum 5 M8, M9).

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

  Future<String> ownerToken() => harness.deviceToken(owner, ownerDeviceId);

  Future<String> crewToken() => harness.deviceToken(crewPhone, dori.deviceId);

  Future<List<WebSession>> sessionsSeenWith(String token) async => decodeOk(
    await harness.send('GET', sessionsPath, headers: harness.withToken(token)),
    decodeWebSessions,
  );

  test('shows the owner every session, the latest first', () async {
    // ARRANGE
    await harness.signIn(owner, ownerDeviceId);
    harness.advance(const Duration(minutes: 5));
    await harness.signIn(crewPhone, dori.deviceId);

    // ACT
    final sessions = await sessionsSeenWith(await ownerToken());

    // ASSERT
    expect(sessions.map((session) => session.userName), ['Dóri', 'Ákos']);
    final latest = sessions.first;
    expect(latest.userId, dori.userId);
    expect(latest.method, LoginMethod.qr);
    expect(latest.ip, browserIp);
    expect(latest.browser, 'Chrome');
    expect(latest.os, 'Linux');
  });

  test('shows the crew only their own sessions', () async {
    await harness.signIn(owner, ownerDeviceId);
    await harness.signIn(crewPhone, dori.deviceId);

    final sessions = await sessionsSeenWith(await crewToken());

    expect(sessions.map((session) => session.userId), [dori.userId]);
  });

  test('hides an expired session before the cleanup', () async {
    await harness.signIn(crewPhone, dori.deviceId);
    harness.advance(const Duration(days: 8));

    final sessions = await sessionsSeenWith(await ownerToken());

    expect(sessions, isEmpty);
  });

  test('signs a session out from the owner phone', () async {
    // ARRANGE
    final browser = await harness.signIn(crewPhone, dori.deviceId);
    final token = await ownerToken();
    final sessionId = (await sessionsSeenWith(token)).single.id;

    // ACT
    final response = await harness.send(
      'DELETE',
      sessionPath(sessionId),
      headers: harness.withToken(token),
    );
    final again = await harness.send(
      'DELETE',
      sessionPath(sessionId),
      headers: harness.withToken(token),
    );

    // ASSERT
    expect(response.statusCode, 204);
    expect(again.statusCode, 204);
    final archive = await harness.send(
      'GET',
      racesPath,
      cookies: {sessionCookieName: browser},
      headers: webClient,
      handler: harness.archive,
    );
    expect(archive.statusCode, 401);
  });

  test("keeps the crew from signing out someone else's session", () async {
    await harness.signIn(owner, ownerDeviceId);
    final sessionId = (await sessionsSeenWith(await ownerToken())).single.id;

    final response = await harness.send(
      'DELETE',
      sessionPath(sessionId),
      headers: harness.withToken(await crewToken()),
    );

    expect(await errorOf(response), const NotAllowed());
    expect(await sessionsSeenWith(await ownerToken()), hasLength(1));
  });

  test('lets the crew sign out their own session', () async {
    await harness.signIn(crewPhone, dori.deviceId);
    final token = await crewToken();
    final sessionId = (await sessionsSeenWith(token)).single.id;

    final response = await harness.send(
      'DELETE',
      sessionPath(sessionId),
      headers: harness.withToken(token),
    );

    expect(response.statusCode, 204);
    expect(await sessionsSeenWith(token), isEmpty);
  });

  test('renames only the asking account', () async {
    final token = await crewToken();

    final renamed = await decodeOk(
      await harness.send(
        'POST',
        accountNamePath,
        json: encodeDisplayNameChange('  Dorottya '),
        headers: harness.withToken(token),
      ),
      decodeAccountInfo,
    );
    final me = await decodeOk(
      await harness.send('GET', mePath, headers: harness.withToken(token)),
      decodeAccountInfo,
    );

    expect(renamed.name, 'Dorottya');
    expect(me, renamed);
    expect(me.userId, dori.userId);
  });

  test('refuses an empty or too long name', () async {
    final token = await crewToken();

    for (final name in ['   ', 'a' * 41]) {
      final response = await harness.send(
        'POST',
        accountNamePath,
        json: encodeDisplayNameChange(name),
        headers: harness.withToken(token),
      );
      expect(await errorOf(response), isA<MalformedRequest>(), reason: name);
    }
  });
}
