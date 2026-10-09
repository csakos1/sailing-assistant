import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/challenge_purpose.dart';
import 'package:web_server/src/auth_db/challenge_repository.dart';
import 'package:web_server/src/auth_db/device_repository.dart';
import 'package:web_server/src/auth_db/device_revocation.dart';
import 'package:web_server/src/auth_db/device_token_repository.dart';
import 'package:web_server/src/auth_db/join_request_phase.dart';
import 'package:web_server/src/auth_db/join_request_repository.dart';
import 'package:web_server/src/auth_db/login_request_phase.dart';
import 'package:web_server/src/auth_db/login_request_repository.dart';
import 'package:web_server/src/auth_db/session_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';

// A csatlakozási kérelmek és a hozzájuk tartozó állapotváltások a DB
// szintjén (ADR 0051 Addendum 5 M3-M7, M10), a külső kulcsok láncával.

final DateTime _now = DateTime.utc(2026, 10, 7, 9, 0, 0, 500);
final DateTime _expiresAt = _now.add(const Duration(hours: 24));
const SessionOrigin _browser = (ip: '198.51.100.20', browser: null, os: null);

Uint8List _bytes(int value) => Uint8List.fromList(List.filled(32, value));

NewJoinRequest _request(String id, int key) => (
  id: id,
  statusDigest: _bytes(key + 100),
  name: 'Dóri',
  deviceName: 'Dóri telefonja',
  model: 'SM-S921B',
  publicKey: _bytes(key),
  deviceKey: _bytes(key + 1),
  ip: '203.0.113.7',
  location: (country: 'HU', city: 'Budapest'),
);

void main() {
  late AuthDatabase database;
  late JoinRequestRepository requests;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    database = AuthDatabase(NativeDatabase.memory());
    requests = JoinRequestRepository(database);
    final users = UserRepository(database);
    await users.insert(
      id: 'u-akos',
      name: 'Ákos',
      role: UserRole.owner,
      now: _now,
    );
    await users.insert(
      id: 'u-dori',
      name: 'Dóri',
      role: UserRole.crew,
      now: _now,
    );
    await DeviceRepository(database).insert(
      id: 'd-dori',
      userId: 'u-dori',
      publicKey: _bytes(1),
      deviceKey: _bytes(2),
      name: 'Dóri telefonja',
      model: 'SM-S921B',
      now: _now,
    );
  });

  tearDown(() => database.close());

  group('JoinRequestRepository', () {
    test('decides a request only once', () async {
      await requests.insert(
        _request('j-1', 10),
        now: _now,
        expiresAt: _expiresAt,
      );

      final approved = await requests.approve(
        'j-1',
        userId: 'u-dori',
        deviceId: 'd-dori',
        now: _now,
      );
      final rejected = await requests.reject('j-1', now: _now);
      final record = await requests.findLive('j-1', now: _now);

      expect(approved, isTrue);
      expect(rejected, isFalse);
      expect(record?.phase, JoinRequestPhase.approved);
      expect(record?.userId, 'u-dori');
      expect(await requests.listPending(now: _now), isEmpty);
    });

    test('sees the keys only of undecided, live requests', () async {
      await requests.insert(
        _request('j-1', 10),
        now: _now,
        expiresAt: _expiresAt,
      );

      final whilePending = await requests.isAnyKeyPending([
        _bytes(11),
      ], now: _now);
      final afterExpiry = await requests.isAnyKeyPending(
        [_bytes(11)],
        now: _expiresAt,
      );
      await requests.reject('j-1', now: _now);
      final afterDecision = await requests.isAnyKeyPending(
        [_bytes(10)],
        now: _now,
      );

      expect(whilePending, isTrue);
      expect(afterExpiry, isFalse);
      expect(afterDecision, isFalse);
    });

    test('lists the newest first and drops expired rows', () async {
      await requests.insert(
        _request('j-1', 10),
        now: _now,
        expiresAt: _expiresAt,
      );
      final later = _now.add(const Duration(minutes: 1));
      await requests.insert(
        _request('j-2', 20),
        now: later,
        expiresAt: later.add(const Duration(hours: 24)),
      );

      final listed = await requests.listPending(now: later);
      await requests.deleteExpired(_expiresAt);

      expect(listed.map((request) => request.id), ['j-2', 'j-1']);
      expect(await requests.findLive('j-1', now: _now), isNull);
      expect(await requests.findLive('j-2', now: _now), isNotNull);
    });
  });

  group('LoginRequestRepository with a join request', () {
    late LoginRequestRepository logins;

    setUp(() async {
      logins = LoginRequestRepository(database);
      await requests.insert(
        _request('j-1', 10),
        now: _now,
        expiresAt: _expiresAt,
      );
      await logins.insert(
        id: 'l-1',
        challenge: 'kihivas',
        bindingDigest: _bytes(50),
        browser: _browser,
        now: _now,
        expiresAt: _now.add(const Duration(seconds: 60)),
      );
    });

    test('waits for the join request and turns approved with it', () async {
      final tenMinutes = _now.add(const Duration(minutes: 10));

      final isMarked = await logins.markJoinPending(
        'l-1',
        joinRequestId: 'j-1',
        now: _now,
        expiresAt: tenMinutes,
      );
      final waiting = await logins.findLive('l-1', now: _now);
      final isApproved = await logins.approveJoined(
        'j-1',
        userId: 'u-dori',
        deviceId: 'd-dori',
        phoneIp: '203.0.113.7',
        now: _now,
        expiresAt: _now.add(const Duration(seconds: 60)),
      );
      final approved = await logins.findLive('l-1', now: _now);

      expect(isMarked, isTrue);
      expect(waiting?.phase, LoginRequestPhase.joinPending);
      expect(waiting?.joinRequestId, 'j-1');
      expect(waiting?.expiresAt, tenMinutes);
      expect(isApproved, isTrue);
      expect(approved?.phase, LoginRequestPhase.approved);
      expect(approved?.deviceId, 'd-dori');
      expect(approved?.phoneIp, '203.0.113.7');
    });

    test('deletes only the request that waits for the join', () async {
      await logins.markJoinPending(
        'l-1',
        joinRequestId: 'j-1',
        now: _now,
        expiresAt: _now.add(const Duration(minutes: 10)),
      );

      await logins.deleteJoinPending('j-1');

      expect(await logins.findLive('l-1', now: _now), isNull);
      expect(
        await logins.approveJoined(
          'j-1',
          userId: 'u-dori',
          deviceId: 'd-dori',
          phoneIp: '203.0.113.7',
          now: _now,
          expiresAt: _now.add(const Duration(seconds: 60)),
        ),
        isFalse,
      );
    });
  });

  group('foreign keys', () {
    test('revocation closes the tokens and sessions of the phone', () async {
      await DeviceTokenRepository(database).insert(
        digest: _bytes(60),
        deviceId: 'd-dori',
        expiresAt: _expiresAt,
      );
      await SessionRepository(database).insert(
        id: 's-1',
        tokenDigest: _bytes(61),
        userId: 'u-dori',
        deviceId: 'd-dori',
        method: LoginMethod.qr,
        origin: _browser,
        now: _now,
      );

      final isRevoked = await deviceRevokerOver(database)('d-dori', now: _now);
      final again = await deviceRevokerOver(database)('d-dori', now: _now);

      expect(isRevoked, isTrue);
      expect(again, isFalse);
      expect(
        await DeviceTokenRepository(database).deviceIdOf(_bytes(60), now: _now),
        isNull,
      );
      expect(await SessionRepository(database).findById('s-1'), isNull);
    });

    test('removing a member takes devices along, keeps the request', () async {
      await requests.insert(
        _request('j-1', 10),
        now: _now,
        expiresAt: _expiresAt,
      );
      await requests.approve(
        'j-1',
        userId: 'u-dori',
        deviceId: 'd-dori',
        now: _now,
      );
      await ChallengeRepository(database).insert(
        digest: _bytes(70),
        deviceId: 'd-dori',
        purpose: ChallengePurpose.action,
        expiresAt: _expiresAt,
      );

      final isDeleted = await UserRepository(database).delete('u-dori');

      final record = await requests.findLive('j-1', now: _now);
      expect(isDeleted, isTrue);
      expect(await DeviceRepository(database).get('d-dori'), isNull);
      expect(
        await ChallengeRepository(database).consume(
          _bytes(70),
          deviceId: 'd-dori',
          purpose: ChallengePurpose.action,
          now: _now,
        ),
        isFalse,
      );
      expect(record?.userId, isNull);
      expect(record?.deviceId, isNull);
      expect(record?.phase, JoinRequestPhase.approved);
    });
  });
}
