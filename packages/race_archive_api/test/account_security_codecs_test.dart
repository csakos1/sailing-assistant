import 'dart:convert';
import 'dart:typed_data';

import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

const String _secretA = 'ICEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj8';

T _unwrap<T>(Result<T, DecodeError> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError('Ok-t vartunk: $error'),
};

DecodeError _errorOf<T>(Result<T, DecodeError> result) => switch (result) {
  Ok(:final value) => throw StateError('Err-t vartunk: $value'),
  Err(:final error) => error,
};

Object? _overTheWire(Map<String, Object?> json) => jsonDecode(jsonEncode(json));

void main() {
  group('round trips', () {
    test('keep the fallback secret exactly as typed', () {
      const login = FallbackLogin('  Jelszó 12 karakter  ');

      final decoded = _unwrap(
        decodeFallbackLogin(_overTheWire(encodeFallbackLogin(login))),
      );

      expect(decoded, login);
    });

    test('keep the password change with its signed action', () {
      final change = PasswordChange(
        password: 'helyes-lo-elem-tuzkő',
        action: SignedAction(
          challenge: _secretA,
          signature: Uint8List.fromList([1, 2, 3]),
        ),
      );

      final decoded = _unwrap(
        decodePasswordChange(_overTheWire(encodePasswordChange(change))),
      );

      expect(decoded, change);
    });

    test('keep the codes, the security state and the banner', () {
      const codes = IssuedRecoveryCodes(['ABCDE-FGHIJ', 'KLMNO-PQRST']);
      final security = AccountSecurity(
        passwordSetAt: DateTime.utc(2026, 10, 7, 9, 15),
        recoveryCodesLeft: 7,
      );
      final banner = LoginBanner(
        suspicious: [
          SuspiciousLogin(
            id: 'e-1',
            userId: 'u-dori',
            userName: 'Dóri',
            method: LoginMethod.qr,
            ip: '203.0.113.7',
            browser: 'Firefox',
            country: 'DE',
            createdAt: DateTime.utc(2026, 10, 7, 8),
            sessionId: 's-1',
          ),
        ],
        pendingJoinRequests: 2,
      );

      expect(
        _unwrap(
          decodeIssuedRecoveryCodes(
            _overTheWire(encodeIssuedRecoveryCodes(codes)),
          ),
        ),
        codes,
      );
      expect(
        _unwrap(
          decodeAccountSecurity(_overTheWire(encodeAccountSecurity(security))),
        ),
        security,
      );
      expect(
        _unwrap(decodeLoginBanner(_overTheWire(encodeLoginBanner(banner)))),
        banner,
      );
    });

    test('keep the suspicious flag of a session', () {
      final session = WebSession(
        id: 's-1',
        userId: 'u-akos',
        userName: 'Ákos',
        method: LoginMethod.password,
        ip: '203.0.113.7',
        createdAt: DateTime.utc(2026, 10, 7, 8),
        lastSeenAt: DateTime.utc(2026, 10, 7, 9),
        isSuspicious: true,
      );

      final decoded = _unwrap(
        decodeWebSessions(_overTheWire(encodeWebSessions([session]))),
      );

      expect(decoded.single, session);
    });
  });

  group('decoding', () {
    test('reads a missing suspicious flag as false', () {
      final sessions = _unwrap(
        decodeWebSessions({
          'sessions': [
            {
              'id': 's-1',
              'userId': 'u-akos',
              'userName': 'Ákos',
              'method': 'qr',
              'ip': '203.0.113.7',
              'createdAt': 0,
              'lastSeenAt': 0,
            },
          ],
        }),
      );

      expect(sessions.single.isSuspicious, isFalse);
    });

    test('rejects a negative code count', () {
      final error = _errorOf(
        decodeAccountSecurity({
          'passwordSetAt': null,
          'recoveryCodesLeft': -1,
        }),
      );

      expect(error.path, r'$.recoveryCodesLeft');
    });

    test('rejects a short challenge in the password change', () {
      final error = _errorOf(
        decodePasswordChange({
          'password': 'helyes-lo-elem-tuzkő',
          'challenge': 'AAECAwQFBgcICQoLDA0ODw',
          'signature': 'AQID',
        }),
      );

      expect(error.path, r'$.challenge');
    });
  });

  test('keeps the secrets out of the string forms', () {
    const login = FallbackLogin('titkos-jelszo-123');
    final change = PasswordChange(
      password: 'titkos-jelszo-123',
      action: SignedAction(
        challenge: _secretA,
        signature: Uint8List.fromList([1]),
      ),
    );
    const codes = IssuedRecoveryCodes(['ABCDE-FGHIJ']);

    expect(login.toString(), isNot(contains('titkos')));
    expect(change.toString(), isNot(contains('titkos')));
    expect(codes.toString(), isNot(contains('ABCDE')));
  });

  test('builds the acknowledgement path with an encoded id', () {
    expect(
      loginEventAcknowledgementPath('a/b'),
      '/api/auth/login-events/a%2Fb/acknowledgement',
    );
  });
}
