import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/http/auth/auth_cookies.dart';

import 'auth_harness.dart';
import 'test_phone.dart';

// A tartalék belépés a weben (ADR 0051 D6, D8, Addendum 6 N2, N3):
// jelszó vagy kód egy mezőben, egyforma hibaválasz, fiók- és IP-korlát.

const String _password = 'hajo-lola-balaton-2026';

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

  Future<void> setPassword() async {
    final response = await harness.setPassword(
      owner,
      enrollment.deviceId,
      _password,
    );
    expect(response.statusCode, 204);
  }

  Future<LoginBanner> ownerBanner() async {
    final token = await harness.deviceToken(owner, enrollment.deviceId);
    return decodeOk(
      await harness.send('GET', bannerPath, headers: harness.withToken(token)),
      decodeLoginBanner,
    );
  }

  test('signs in with the password and flags the sign-in', () async {
    // ARRANGE
    await setPassword();

    // ACT
    final response = await harness.fallbackLogin(_password);

    // ASSERT
    final account = await decodeOk(response, decodeAccountInfo);
    expect(account, enrollment.account);
    final session = cookiesOf(response)[sessionCookieName];
    expect(session, isNotEmpty);
    final archive = await harness.send(
      'GET',
      racesPath,
      cookies: {sessionCookieName: session ?? ''},
      headers: webClient,
      handler: harness.archive,
    );
    expect(archive.statusCode, 200);
    final banner = await ownerBanner();
    expect(banner.suspicious.single.method, LoginMethod.password);
    expect(banner.suspicious.single.ip, browserIp);
  });

  test('takes a recovery code as typed on paper, but only once', () async {
    final code = enrollment.recoveryCodes.first;
    final typed = ' ${code.toLowerCase().replaceAll('-', ' ')} ';

    final first = await harness.fallbackLogin(typed);
    final second = await harness.fallbackLogin(code);

    expect(first.statusCode, 200);
    expect(await errorOf(second), const NotAuthenticated());
    expect(
      (await ownerBanner()).suspicious.single.method,
      LoginMethod.recoveryCode,
    );
  });

  test('answers every wrong secret the same way', () async {
    await setPassword();
    final secrets = [
      'rossz-jelszo-de-hosszu',
      'ABCDE-FGHIJ',
      '',
      'a' * 200,
      '${_password}x',
    ];

    final bodies = <String>{};
    for (final secret in secrets) {
      final response = await harness.fallbackLogin(secret);
      expect(response.statusCode, 401, reason: secret);
      bodies.add(await response.readAsString());
    }

    expect(bodies, hasLength(1));
  });

  test('lets nobody in without an owner', () async {
    final empty = AuthHarness();
    addTearDown(empty.close);

    final response = await empty.fallbackLogin('ABCDE-FGHIJ');

    expect(await errorOf(response), const NotAuthenticated());
  });

  test('backs off after five failures, even for the right password', () async {
    // ARRANGE
    await setPassword();
    for (var i = 0; i < 5; i++) {
      expect((await harness.fallbackLogin('rossz-jelszo-$i')).statusCode, 401);
    }

    // ACT + ASSERT
    final blocked = await harness.fallbackLogin(_password);
    expect(await errorOf(blocked), const TooManyAttempts(60));
    expect(blocked.headers['retry-after'], '60');

    harness.advance(const Duration(minutes: 1));
    expect((await harness.fallbackLogin('rossz-jelszo-6')).statusCode, 401);
    final doubled = await harness.fallbackLogin(_password);
    expect(await errorOf(doubled), const TooManyAttempts(120));

    harness.advance(const Duration(minutes: 2));
    expect((await harness.fallbackLogin(_password)).statusCode, 200);
    expect((await harness.fallbackLogin('rossz-jelszo-7')).statusCode, 401);
    expect((await harness.fallbackLogin(_password)).statusCode, 200);
  });

  test('lets no parallel burst past the five failures', () async {
    await setPassword();

    final responses = await Future.wait([
      for (var i = 0; i < 6; i++) harness.fallbackLogin('rossz-jelszo-$i'),
    ]);
    final blocked = await harness.fallbackLogin(_password);

    final statuses = responses.map((response) => response.statusCode);
    expect(statuses.where((status) => status == 401), hasLength(5));
    expect(statuses.where((status) => status == 429), hasLength(1));
    expect(blocked.statusCode, 429);
  });

  test('limits the attempts per address', () async {
    final limited = AuthHarness(rateLimit: 2);
    addTearDown(limited.close);
    await limited.enroll(owner);

    await limited.fallbackLogin('rossz-jelszo-1');
    await limited.fallbackLogin('rossz-jelszo-2');
    final third = await limited.fallbackLogin('rossz-jelszo-3');
    final elsewhere = await limited.fallbackLogin(
      'rossz-jelszo-4',
      ip: '192.0.2.44',
    );

    expect(third.statusCode, 429);
    expect(elsewhere.statusCode, 401);
  });

  test('refuses a body that is not a fallback login', () async {
    final response = await harness.send(
      'POST',
      fallbackLoginPath,
      json: {'password': _password},
      ip: browserIp,
      headers: webClient,
    );

    final body = await response.readAsString();
    expect(response.statusCode, 400);
    expect(body, isNot(contains(_password)));
  });
}
