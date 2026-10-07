import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/challenge_repository.dart';
import 'package:web_server/src/auth_db/device_repository.dart';
import 'package:web_server/src/auth_db/login_request_phase.dart';
import 'package:web_server/src/auth_db/login_request_repository.dart';
import 'package:web_server/src/auth_db/recovery_code_repository.dart';
import 'package:web_server/src/auth_db/session_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';

final DateTime _now = DateTime.utc(2026, 10, 7, 9, 0, 0, 500);
const SessionOrigin _browser = (ip: '198.51.100.20', browser: null, os: null);

Uint8List _bytes(int value) => Uint8List.fromList(List.filled(32, value));

void main() {
  late AuthDatabase database;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    database = AuthDatabase(NativeDatabase.memory());
    await UserRepository(
      database,
    ).insert(id: 'u-akos', name: 'Ákos', role: UserRole.owner, now: _now);
    for (final (id, key) in [('d-1', 1), ('d-2', 3)]) {
      await DeviceRepository(database).insert(
        id: id,
        userId: 'u-akos',
        publicKey: _bytes(key),
        deviceKey: _bytes(key + 1),
        name: id,
        model: 'Pixel 8',
        now: _now,
      );
    }
  });

  tearDown(() => database.close());

  group('ChallengeRepository', () {
    late ChallengeRepository challenges;
    final expiresAt = _now.add(const Duration(seconds: 60));

    setUp(() async {
      challenges = ChallengeRepository(database);
      await challenges.insert(
        digest: _bytes(9),
        deviceId: 'd-1',
        expiresAt: expiresAt,
      );
    });

    test('hands a challenge out once, only to its device', () async {
      expect(
        await challenges.consume(_bytes(9), deviceId: 'd-2', now: _now),
        isFalse,
      );
      expect(
        await challenges.consume(_bytes(9), deviceId: 'd-1', now: _now),
        isTrue,
      );
      expect(
        await challenges.consume(_bytes(9), deviceId: 'd-1', now: _now),
        isFalse,
      );
    });

    test('refuses a challenge at its expiry', () async {
      expect(
        await challenges.consume(_bytes(9), deviceId: 'd-1', now: expiresAt),
        isFalse,
      );
    });
  });

  group('LoginRequestRepository', () {
    late LoginRequestRepository requests;
    final expiresAt = _now.add(const Duration(seconds: 60));
    final later = _now.add(const Duration(seconds: 30));

    setUp(() async {
      requests = LoginRequestRepository(database);
      await requests.insert(
        id: 'req-1',
        challenge: 'kihivas',
        bindingDigest: _bytes(7),
        browser: _browser,
        now: _now,
        expiresAt: expiresAt,
      );
    });

    Future<bool> approve() => requests.approve(
      'req-1',
      userId: 'u-akos',
      deviceId: 'd-1',
      phoneIp: '203.0.113.7',
      now: later,
      expiresAt: later.add(const Duration(seconds: 60)),
    );

    test('reads back a live request with its browser', () async {
      final request = await requests.findLive('req-1', now: _now);

      expect(request?.phase, LoginRequestPhase.pending);
      expect(request?.challenge, 'kihivas');
      expect(request?.browser, _browser);
      expect(request?.expiresAt, expiresAt);
      expect(await requests.findLive('req-1', now: expiresAt), isNull);
    });

    test('moves the deadline on opening', () async {
      final deadline = later.add(const Duration(seconds: 60));

      expect(
        await requests.open('req-1', now: later, expiresAt: deadline),
        isTrue,
      );
      final request = await requests.findLive('req-1', now: later);
      expect(request?.phase, LoginRequestPhase.opened);
      expect(request?.expiresAt, deadline);
    });

    test('approves once and is redeemed once', () async {
      expect(await approve(), isTrue);
      expect(await approve(), isFalse);
      expect(
        await requests.open('req-1', now: later, expiresAt: expiresAt),
        isFalse,
      );

      final redeemed = await requests.redeem('req-1', now: later);

      expect(redeemed?.userId, 'u-akos');
      expect(redeemed?.deviceId, 'd-1');
      expect(redeemed?.phoneIp, '203.0.113.7');
      expect(await requests.redeem('req-1', now: later), isNull);
      expect(await requests.findLive('req-1', now: later), isNull);
    });

    test('does not redeem a request that is not approved', () async {
      expect(await requests.redeem('req-1', now: later), isNull);
      expect(await requests.findLive('req-1', now: later), isNotNull);
    });

    test('deletes only the expired requests', () async {
      await requests.deleteExpired(later);
      expect(await requests.findLive('req-1', now: later), isNotNull);

      await requests.deleteExpired(expiresAt);
      expect(await database.select(database.loginRequests).get(), isEmpty);
    });
  });

  group('SessionRepository', () {
    late SessionRepository sessions;

    setUp(() async {
      sessions = SessionRepository(database);
      await sessions.insert(
        id: 's-1',
        tokenDigest: _bytes(5),
        userId: 'u-akos',
        method: LoginMethod.qr,
        origin: _browser,
        now: _now,
        deviceId: 'd-1',
      );
    });

    test('finds a session by its digest and records its use', () async {
      final later = _now.add(const Duration(hours: 2));

      await sessions.touch('s-1', now: later);

      final session = await sessions.findByDigest(_bytes(5));
      expect(session?.userId, 'u-akos');
      expect(session?.createdAt, _now);
      expect(session?.lastSeenAt, later);
    });

    test('deletes an idle or a too old session', () async {
      await sessions.deleteExpired(
        idleCutoff: _now.subtract(const Duration(milliseconds: 1)),
        createdCutoff: _now.subtract(const Duration(milliseconds: 1)),
      );
      expect(await sessions.findByDigest(_bytes(5)), isNotNull);

      await sessions.deleteExpired(
        idleCutoff: _now.subtract(const Duration(days: 1)),
        createdCutoff: _now,
      );
      expect(await sessions.findByDigest(_bytes(5)), isNull);
    });

    test('keeps the session when its approving device is deleted', () async {
      await database.customStatement("DELETE FROM devices WHERE id = 'd-1'");

      expect(await sessions.findByDigest(_bytes(5)), isNotNull);
    });
  });

  test('replaces all recovery codes of a user', () async {
    final codes = RecoveryCodeRepository(database);
    await codes.replaceAll('u-akos', [_bytes(20), _bytes(21)], now: _now);

    await codes.replaceAll('u-akos', [_bytes(22)], now: _now);

    final rows = await database.select(database.recoveryCodes).get();
    expect(rows.map((row) => row.codeDigest), [_bytes(22)]);
  });
}
