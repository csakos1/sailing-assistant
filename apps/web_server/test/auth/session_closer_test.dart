import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/auth/session_closer.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/login_event_repository.dart';
import 'package:web_server/src/auth_db/session_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';

// A VPS-es lezaras (ADR 0052 D10) egy memoriabeli auth.sqlite-on: Akosnak
// ket munkamenete van (az egyik gyanus tartalek-belepes), Bencenek egy.

final DateTime _now = DateTime.utc(2026, 10, 9, 8);
const SessionOrigin _browser = (ip: '198.51.100.20', browser: null, os: null);

Uint8List _digest(int value) => Uint8List.fromList(List.filled(32, value));

void main() {
  late AuthDatabase database;
  late SessionRepository sessions;
  late LoginEventRepository events;
  late SessionCloser closer;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    database = AuthDatabase(NativeDatabase.memory());
    sessions = SessionRepository(database);
    events = LoginEventRepository(database);
    closer = SessionCloser(database, now: () => _now);
    final users = UserRepository(database);
    await users.insert(
      id: 'u-akos',
      name: 'Ákos',
      role: UserRole.owner,
      now: _now,
    );
    await users.insert(
      id: 'u-bence',
      name: 'Bence',
      role: UserRole.crew,
      now: _now,
    );
    await users.insert(
      id: 'u-dori',
      name: 'Dóri',
      role: UserRole.crew,
      now: _now,
    );
    for (final (id, userId, method, digest) in [
      ('s-1', 'u-akos', LoginMethod.recoveryCode, 1),
      ('s-2', 'u-akos', LoginMethod.qr, 2),
      ('s-3', 'u-bence', LoginMethod.qr, 3),
    ]) {
      await sessions.insert(
        id: id,
        tokenDigest: _digest(digest),
        userId: userId,
        method: method,
        origin: _browser,
        now: _now,
      );
    }
    await events.insert((
      id: 'e-1',
      userId: 'u-akos',
      sessionId: 's-1',
      method: LoginMethod.recoveryCode,
      ip: _browser.ip,
      browser: null,
      os: null,
      country: null,
      city: null,
      phoneCountry: null,
      isSuspicious: true,
    ), now: _now);
  });

  tearDown(() => database.close());

  Future<Set<String>> liveIds() async => {
    for (final session in await sessions.listLive(
      idleCutoff: _now.subtract(const Duration(days: 1)),
      createdCutoff: _now.subtract(const Duration(days: 1)),
    ))
      session.id,
  };

  Future<int> unacknowledged() async =>
      (await events.listUnacknowledgedSuspicious(
        since: _now.subtract(const Duration(days: 1)),
      )).length;

  group('closeSession', () {
    test('closes one session and acknowledges its suspicious event', () async {
      final isClosed = await closer.closeSession('s-1');

      expect(isClosed, isTrue);
      expect(await liveIds(), {'s-2', 's-3'});
      expect(await unacknowledged(), 0);
    });

    test('reports an unknown session and changes nothing', () async {
      final isClosed = await closer.closeSession('s-9');

      expect(isClosed, isFalse);
      expect(await liveIds(), {'s-1', 's-2', 's-3'});
      expect(await unacknowledged(), 1);
    });
  });

  group('closeUserSessions', () {
    test('closes every session of one user only', () async {
      final count = await closer.closeUserSessions('u-akos');

      expect(count, 2);
      expect(await liveIds(), {'s-3'});
      expect(await unacknowledged(), 0);
    });

    test('closes nothing for a user without sessions', () async {
      final count = await closer.closeUserSessions('u-dori');

      expect(count, 0);
      expect(await liveIds(), {'s-1', 's-2', 's-3'});
    });

    test('reports an unknown user', () async {
      final count = await closer.closeUserSessions('u-nobody');

      expect(count, isNull);
      expect(await liveIds(), {'s-1', 's-2', 's-3'});
    });
  });
}
