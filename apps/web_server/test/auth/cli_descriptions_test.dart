import 'dart:typed_data';

import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/auth/cli/describe_devices.dart';
import 'package:web_server/src/auth/cli/describe_owner_enrollment.dart';
import 'package:web_server/src/auth/cli/describe_sessions.dart';
import 'package:web_server/src/auth/owner_enrollment.dart';
import 'package:web_server/src/auth_db/auth_device.dart';
import 'package:web_server/src/auth_db/auth_user.dart';

void main() {
  group('describeOwnerEnrollment', () {
    test('names the new owner and shows the expiry in Budapest time', () {
      final lines = describeOwnerEnrollment(
        IssuedOwnerEnrollment(
          qrText: 'foretack-enroll:v1:x',
          // Nyari ido: UTC+2.
          expiresAt: DateTime.utc(2026, 10, 6, 19, 45),
          ownerName: 'Ákos',
          isFirstOwner: true,
        ),
      );

      expect(lines.first, 'Új tulajdonos: Ákos.');
      expect(lines[1], contains('2026-10-06 21:45'));
      expect(lines.join('\n'), isNot(contains('foretack-enroll')));
    });

    test('says when the code adds a phone to the existing owner', () {
      final lines = describeOwnerEnrollment(
        IssuedOwnerEnrollment(
          qrText: 'foretack-enroll:v1:x',
          // Teli ido: UTC+1.
          expiresAt: DateTime.utc(2026, 12, 1, 8, 5),
          ownerName: 'Ákos',
          isFirstOwner: false,
        ),
      );

      expect(lines.first, 'A tulajdonos (Ákos) új telefonja.');
      expect(lines[1], contains('2026-12-01 09:05'));
    });

    test('explains every error in one line', () {
      const errors = <OwnerEnrollmentError>[
        InvalidEnrollmentOrigin(),
        InvalidOwnerName(),
        OwnerNameRequired(),
        OwnerAlreadyExists('Ákos'),
      ];

      for (final error in errors) {
        expect(describeOwnerEnrollmentError(error), isNot(contains('\n')));
      }
      expect(
        describeOwnerEnrollmentError(const OwnerAlreadyExists('Ákos')),
        contains('Ákos'),
      );
    });
  });

  group('describeDevices', () {
    final owner = AuthUser(
      id: 'u-akos',
      name: 'Ákos',
      role: UserRole.owner,
      createdAt: DateTime.utc(2026, 10),
    );

    test('lists one device per line with its id first', () {
      final lines = describeDevices([
        (
          device: AuthDevice(
            id: 'd-1',
            userId: 'u-akos',
            publicKey: Uint8List(0),
            deviceKey: Uint8List(0),
            name: 'Ákos Pixel 8',
            model: 'Pixel 8',
            createdAt: DateTime.utc(2026, 10, 6, 18),
            lastUsedAt: DateTime.utc(2026, 10, 6, 19),
            revokedAt: DateTime.utc(2026, 10, 7, 6),
          ),
          user: owner,
        ),
      ]);

      expect(
        lines.single,
        'd-1  Ákos (tulajdonos)  Ákos Pixel 8 · Pixel 8  '
        'regisztrálva 2026-10-06 20:00  utoljára 2026-10-06 21:00  '
        'VISSZAVONVA 2026-10-07 08:00',
      );
    });

    test('says so when there is no device', () {
      expect(describeDevices(const []), ['Nincs regisztrált eszköz.']);
    });
  });

  group('describeSessions', () {
    test('lists one live session per line with its id first', () {
      final lines = describeSessions([
        WebSession(
          id: 's-1',
          userId: 'u-akos',
          userName: 'Ákos',
          method: LoginMethod.recoveryCode,
          ip: '198.51.100.20',
          browser: 'Firefox',
          os: 'Linux',
          country: 'AT',
          city: 'Wien',
          // Nyari ido: UTC+2.
          createdAt: DateTime.utc(2026, 10, 6, 18),
          lastSeenAt: DateTime.utc(2026, 10, 6, 19, 30),
          isSuspicious: true,
        ),
        WebSession(
          id: 's-2',
          userId: 'u-bence',
          userName: 'Bence',
          method: LoginMethod.qr,
          ip: '127.0.0.1',
          createdAt: DateTime.utc(2026, 10, 7, 6),
          lastSeenAt: DateTime.utc(2026, 10, 7, 6, 5),
        ),
      ]);

      expect(lines, hasLength(2));
      expect(
        lines.first,
        's-1  Ákos (u-akos)  kód  198.51.100.20 Wien, AT  Firefox · Linux  '
        'belépett 2026-10-06 20:00  utoljára 2026-10-06 21:30  GYANÚS',
      );
      expect(
        lines.last,
        's-2  Bence (u-bence)  QR  127.0.0.1  '
        'belépett 2026-10-07 08:00  utoljára 2026-10-07 08:05',
      );
    });

    test('says so when there is no live session', () {
      expect(describeSessions(const []), ['Nincs élő webes munkamenet.']);
    });
  });
}
