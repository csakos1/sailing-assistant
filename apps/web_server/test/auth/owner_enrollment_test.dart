import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:web_server/src/auth/owner_enrollment.dart';
import 'package:web_server/src/auth/token_digest.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/enrollment_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';

const String _origin = 'https://archivum.example.hu';
final DateTime _now = DateTime.utc(2026, 10, 6, 19, 30);

Uint8List _bytes(int length) =>
    Uint8List.fromList([for (var i = 0; i < length; i++) 0x40 + i]);

void main() {
  late AuthDatabase database;
  late UserRepository users;
  late EnrollmentRepository enrollments;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    database = AuthDatabase(NativeDatabase.memory());
    users = UserRepository(database);
    enrollments = EnrollmentRepository(database);
  });

  tearDown(() => database.close());

  Future<Result<IssuedOwnerEnrollment, OwnerEnrollmentError>> issue({
    String origin = _origin,
    String? name,
  }) => issueOwnerEnrollment(
    users: users,
    enrollments: enrollments,
    origin: origin,
    name: name,
    now: _now,
    randomBytes: _bytes,
  );

  IssuedOwnerEnrollment issued(
    Result<IssuedOwnerEnrollment, OwnerEnrollmentError> result,
  ) => switch (result) {
    Ok(:final value) => value,
    Err(:final error) => throw StateError('Ok-t vartunk: $error'),
  };

  group('issueOwnerEnrollment', () {
    test('issues a QR for the first owner with the trimmed name', () async {
      final enrollment = issued(await issue(name: '  Ákos '));

      expect(enrollment.isFirstOwner, isTrue);
      expect(enrollment.ownerName, 'Ákos');
      expect(enrollment.expiresAt, _now.add(const Duration(minutes: 15)));
      expect(
        decodeQrPayload(enrollment.qrText),
        Ok<QrPayload, QrPayloadError>(
          EnrollQrPayload(
            origin: _origin,
            token: encodeBase64UrlUnpadded(_bytes(32)),
          ),
        ),
      );
    });

    test('stores only the digest of the token, with the name', () async {
      issued(await issue(name: 'Ákos'));
      final token = encodeBase64UrlUnpadded(_bytes(32));

      final stored = await enrollments.consume(digestToken(token), now: _now);

      expect(stored?.ownerName, 'Ákos');
      expect(stored?.origin, _origin);
    });

    test('issues a new device for an existing owner without a name', () async {
      await users.insert(
        id: 'u-akos',
        name: 'Ákos',
        role: UserRole.owner,
        now: _now,
      );

      final enrollment = issued(await issue());
      final stored = await enrollments.consume(
        digestToken(encodeBase64UrlUnpadded(_bytes(32))),
        now: _now,
      );

      expect(enrollment.isFirstOwner, isFalse);
      expect(enrollment.ownerName, 'Ákos');
      expect(stored?.ownerName, isNull);
    });

    test('refuses a name when the owner already exists', () async {
      await users.insert(
        id: 'u-akos',
        name: 'Ákos',
        role: UserRole.owner,
        now: _now,
      );

      expect(
        await issue(name: 'Valaki'),
        const Err<IssuedOwnerEnrollment, OwnerEnrollmentError>(
          OwnerAlreadyExists('Ákos'),
        ),
      );
    });

    test('needs a valid name for the first owner', () async {
      expect(
        await issue(),
        const Err<IssuedOwnerEnrollment, OwnerEnrollmentError>(
          OwnerNameRequired(),
        ),
      );
      expect(
        await issue(name: '   '),
        const Err<IssuedOwnerEnrollment, OwnerEnrollmentError>(
          InvalidOwnerName(),
        ),
      );
    });

    test('refuses a non-canonical origin before writing anything', () async {
      expect(
        await issue(origin: '$_origin/', name: 'Ákos'),
        const Err<IssuedOwnerEnrollment, OwnerEnrollmentError>(
          InvalidEnrollmentOrigin(),
        ),
      );
      final token = encodeBase64UrlUnpadded(_bytes(32));
      expect(await enrollments.consume(digestToken(token), now: _now), isNull);
    });
  });
}
