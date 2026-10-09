import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/device_repository.dart';
import 'package:web_server/src/auth_db/enrollment_record.dart';
import 'package:web_server/src/auth_db/enrollment_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';

final Uint8List _keyA = base64.decode(
  'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEYP7UuiVanTHJYet0xjVtaMBJuJI7Yfps'
  '5mliLmDyn7Z5A/4QCLi8maQa6elWKLxk8vGyDC1+n1F3o8KU1EYimQ==',
);
final Uint8List _keyB = base64.decode(
  'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEJu/OvQ7p40pmkYfhizqRIrL3M5RbZJzJ'
  '+fkh6fna2BKQI4venMe7Mw0VDGdwTdJa5wVSBXRLbzG/QHB0WHLQ5g==',
);
final DateTime _now = DateTime.utc(2026, 10, 6, 19, 30, 15, 123);

// A repository nem ellenőrzi a kulcsok alakját; az eszközkulcs itt csak
// egy, az aláíró kulcstól különböző, egyedi bájtsor.
Uint8List _deviceKeyFor(Uint8List publicKey) =>
    Uint8List.fromList([0xD0, ...publicKey]);

void main() {
  late AuthDatabase database;
  late UserRepository users;
  late DeviceRepository devices;
  late EnrollmentRepository enrollments;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    database = AuthDatabase(NativeDatabase.memory());
    users = UserRepository(database);
    devices = DeviceRepository(database);
    enrollments = EnrollmentRepository(database);
  });

  tearDown(() => database.close());

  Future<void> addOwnerAndCrew() async {
    for (final (id, name, role) in [
      ('u-akos', 'Ákos', UserRole.owner),
      ('u-dori', 'Dóri', UserRole.crew),
    ]) {
      await users.insert(id: id, name: name, role: role, now: _now);
    }
  }

  group('UserRepository', () {
    test('round-trips a user with millisecond precision in UTC', () async {
      final user = await users.insert(
        id: 'u-akos',
        name: 'Ákos',
        role: UserRole.owner,
        now: _now,
      );

      expect(user.createdAt, _now);
      expect(user.createdAt.isUtc, isTrue);
      expect(user.passwordSetAt, isNull);
      expect(await users.get('u-akos'), user);
    });

    test('finds the owner among the users', () async {
      expect(await users.owner(), isNull);

      await addOwnerAndCrew();

      expect((await users.owner())?.name, 'Ákos');
    });

    test('allows only one owner in the database', () async {
      await addOwnerAndCrew();

      expect(
        users.insert(id: 'u-2', name: 'Masik', role: UserRole.owner, now: _now),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('DeviceRepository', () {
    test('round-trips a device and lists it with its user', () async {
      await addOwnerAndCrew();

      final device = await devices.insert(
        id: 'd-1',
        userId: 'u-akos',
        publicKey: _keyA,
        deviceKey: _deviceKeyFor(_keyA),
        name: 'Ákos Pixel 8',
        model: 'Pixel 8',
        now: _now,
      );
      final listed = await devices.listAll();

      expect(await devices.get('d-1'), device);
      expect(device.isRevoked, isFalse);
      expect(listed.single.device, device);
      expect(listed.single.user.name, 'Ákos');
    });

    test('refuses the same public key for a second device', () async {
      await addOwnerAndCrew();
      await devices.insert(
        id: 'd-1',
        userId: 'u-akos',
        publicKey: _keyA,
        deviceKey: _deviceKeyFor(_keyA),
        name: 'A',
        model: 'Pixel 8',
        now: _now,
      );

      expect(
        devices.insert(
          id: 'd-2',
          userId: 'u-dori',
          publicKey: _keyA,
          deviceKey: _deviceKeyFor(_keyB),
          name: 'B',
          model: 'Pixel 7a',
          now: _now,
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('refuses a device key that another device already uses', () async {
      await addOwnerAndCrew();
      await devices.insert(
        id: 'd-1',
        userId: 'u-akos',
        publicKey: _keyA,
        deviceKey: _keyB,
        name: 'A',
        model: 'Pixel 8',
        now: _now,
      );

      expect(await devices.isAnyKeyInUse([_keyB]), isTrue);
      expect(await devices.isAnyKeyInUse([_keyA]), isTrue);
      expect(await devices.isAnyKeyInUse([_deviceKeyFor(_keyA)]), isFalse);
      expect(
        devices.insert(
          id: 'd-2',
          userId: 'u-dori',
          publicKey: _deviceKeyFor(_keyA),
          deviceKey: _keyB,
          name: 'B',
          model: 'Pixel 7a',
          now: _now,
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('records the last use of a device', () async {
      await addOwnerAndCrew();
      await devices.insert(
        id: 'd-1',
        userId: 'u-akos',
        publicKey: _keyA,
        deviceKey: _keyB,
        name: 'A',
        model: 'Pixel 8',
        now: _now,
      );
      final later = _now.add(const Duration(minutes: 5));

      await devices.markUsed('d-1', now: later);

      expect((await devices.get('d-1'))?.lastUsedAt, later);
    });

    test('revokes an active device once and keeps the first time', () async {
      await addOwnerAndCrew();
      await devices.insert(
        id: 'd-1',
        userId: 'u-dori',
        publicKey: _keyB,
        deviceKey: _deviceKeyFor(_keyB),
        name: 'Dóri',
        model: 'Galaxy S23',
        now: _now,
      );
      final later = _now.add(const Duration(days: 1));

      expect(await devices.revoke('d-1', now: _now), isTrue);
      expect(await devices.revoke('d-1', now: later), isFalse);
      expect(await devices.revoke('nincs', now: later), isFalse);
      expect((await devices.get('d-1'))?.revokedAt, _now);
    });

    test('deletes the devices with their user', () async {
      await addOwnerAndCrew();
      await devices.insert(
        id: 'd-1',
        userId: 'u-dori',
        publicKey: _keyB,
        deviceKey: _deviceKeyFor(_keyB),
        name: 'Dóri',
        model: 'Galaxy S23',
        now: _now,
      );

      await database.customStatement("DELETE FROM users WHERE id = 'u-dori'");

      expect(await devices.get('d-1'), isNull);
    });
  });

  group('EnrollmentRepository', () {
    final digest = Uint8List.fromList(List.filled(32, 9));
    final expiresAt = _now.add(const Duration(minutes: 15));

    Future<void> issue() => enrollments.insert(
      tokenDigest: digest,
      origin: 'https://archivum.example.hu',
      ownerName: 'Ákos',
      now: _now,
      expiresAt: expiresAt,
    );

    test('hands the token out exactly once', () async {
      await issue();
      final later = _now.add(const Duration(minutes: 1));

      expect(
        await enrollments.consume(digest, now: later),
        EnrollmentRecord(
          origin: 'https://archivum.example.hu',
          ownerName: 'Ákos',
          createdAt: _now,
          expiresAt: expiresAt,
        ),
      );
      expect(await enrollments.consume(digest, now: later), isNull);
    });

    test('refuses an expired token, also at the exact expiry', () async {
      await issue();

      expect(await enrollments.consume(digest, now: expiresAt), isNull);
    });

    test('refuses an unknown token', () async {
      await issue();

      final other = Uint8List.fromList(List.filled(32, 8));

      expect(await enrollments.consume(other, now: _now), isNull);
    });
  });
}
