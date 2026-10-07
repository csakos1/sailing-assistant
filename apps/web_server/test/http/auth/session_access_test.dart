import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:web_server/src/auth_db/user_repository.dart';
import 'package:web_server/src/http/auth/auth_cookies.dart';

import 'auth_harness.dart';
import 'test_phone.dart';

void main() {
  late AuthHarness harness;
  late String ownerDevice;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    harness = AuthHarness();
    ownerDevice = (await harness.enroll(TestPhone.first())).deviceId;
  });

  tearDown(() => harness.close());

  Future<Response> archive(
    String method,
    String path,
    BrowserSession? session,
  ) => harness.send(
    method,
    path,
    ip: browserIp,
    headers: webClient,
    cookies: {if (session != null) sessionCookieName: session},
    handler: harness.archive,
  );

  Future<Response> me(BrowserSession session) => harness.send(
    'GET',
    mePath,
    ip: browserIp,
    headers: webClient,
    cookies: {sessionCookieName: session},
  );

  Future<int> sessionCount() async =>
      (await harness.database.select(harness.database.sessions).get()).length;

  group('archive guard', () {
    test('refuses the archive without a session', () async {
      final response = await archive('GET', racesPath, null);

      expect(response.statusCode, 401);
      expect(await errorOf(response), const NotAuthenticated());
    });

    test('refuses an unknown session token', () async {
      final response = await archive('GET', racesPath, 'ismeretlen');

      expect(response.statusCode, 401);
    });

    test('lets the owner read, write and export', () async {
      final session = await harness.signIn(TestPhone.first(), ownerDevice);

      for (final (method, path) in [
        ('GET', racesPath),
        ('PUT', raceResultPath('r1')),
        ('GET', exportPath),
      ]) {
        final response = await archive(method, path, session);
        expect(response.statusCode, 200, reason: '$method $path');
      }
    });

    test('lets the crew only read, without the export', () async {
      // ARRANGE
      final crewPhone = TestPhone.second();
      await UserRepository(harness.database).insert(
        id: 'u-dori',
        name: 'Dóri',
        role: UserRole.crew,
        now: harness.now,
      );
      await harness.addDevice(crewPhone, id: 'd-dori', userId: 'u-dori');
      final session = await harness.signIn(crewPhone, 'd-dori');

      // ACT
      final read = await archive('GET', racesPath, session);
      final write = await archive('PUT', raceResultPath('r1'), session);
      final export = await archive('GET', exportPath, session);

      // ASSERT
      expect(read.statusCode, 200);
      expect(write.statusCode, 403);
      expect(await errorOf(write), const NotAllowed());
      expect(export.statusCode, 403);
    });
  });

  group('session lifetime', () {
    test('ends after seven idle days', () async {
      final session = await harness.signIn(TestPhone.first(), ownerDevice);
      harness.advance(const Duration(days: 7));

      final response = await me(session);

      expect(response.statusCode, 401);
      expect(await sessionCount(), 0);
    });

    test('is renewed by use, up to 90 days', () async {
      // ARRANGE
      final session = await harness.signIn(TestPhone.first(), ownerDevice);

      // ACT: hatnaponta használva a 7 nap tétlenség soha nem telik le.
      final statuses = <int>[];
      for (var elapsedDays = 6; elapsedDays < 90; elapsedDays += 6) {
        harness.advance(const Duration(days: 6));
        statuses.add((await me(session)).statusCode);
      }
      harness.advance(const Duration(days: 6));
      final afterCap = await me(session);

      // ASSERT
      expect(statuses, everyElement(200));
      expect(afterCap.statusCode, 401);
    });

    test('is deleted on logout, with its cookie', () async {
      final session = await harness.signIn(TestPhone.first(), ownerDevice);

      final logout = await harness.send(
        'POST',
        logoutPath,
        ip: browserIp,
        headers: webClient,
        cookies: {sessionCookieName: session},
      );

      expect(logout.statusCode, 204);
      expect(cookiesOf(logout)[sessionCookieName], isEmpty);
      expect((await me(session)).statusCode, 401);
    });

    test('ends the old session when the browser signs in again', () async {
      // ARRANGE
      final phone = TestPhone.first();
      final old = await harness.signIn(phone, ownerDevice);
      final (:qr, :binding) = await harness.openLoginRequest();
      await harness.approve(qr, phone, ownerDevice);

      // ACT
      final response = await harness.send(
        'POST',
        loginRequestPollPath(qr.requestId),
        ip: browserIp,
        headers: webClient,
        cookies: {loginCookieName: binding, sessionCookieName: old},
      );

      // ASSERT
      final fresh = cookiesOf(response)[sessionCookieName];
      expect(fresh, isNotNull);
      expect((await me(old)).statusCode, 401);
      expect((await me(fresh ?? '')).statusCode, 200);
      expect(await sessionCount(), 1);
    });

    test('answers a logout without a session with 204 too', () async {
      final logout = await harness.send(
        'POST',
        logoutPath,
        ip: browserIp,
        headers: webClient,
      );

      expect(logout.statusCode, 204);
    });

    test('names the signed-in account', () async {
      final session = await harness.signIn(TestPhone.first(), ownerDevice);

      final account = await decodeOk(await me(session), decodeAccountInfo);

      expect(account.name, 'Ákos');
      expect(account.role, UserRole.owner);
    });
  });

  test('cleans up the expired rows', () async {
    // ARRANGE
    final session = await harness.signIn(TestPhone.first(), ownerDevice);
    await harness.openLoginRequest();
    harness.advance(const Duration(days: 8));

    // ACT
    await harness.api.deleteExpired();

    // ASSERT
    final database = harness.database;
    expect(await database.select(database.loginRequests).get(), isEmpty);
    expect(await database.select(database.challenges).get(), isEmpty);
    expect(await database.select(database.deviceTokens).get(), isEmpty);
    expect(await sessionCount(), 0);
    expect((await me(session)).statusCode, 401);
  });
}
