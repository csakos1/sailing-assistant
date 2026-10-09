import 'dart:convert';
import 'dart:typed_data';

import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

const String _secretA = 'ICEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj8';
const String _requestId = 'AAECAwQFBgcICQoLDA0ODw';
const AccountInfo _owner = AccountInfo(
  userId: 'u-akos',
  name: 'Ákos',
  role: UserRole.owner,
);

T _unwrap<T>(Result<T, DecodeError> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError('Ok-t vartunk: $error'),
};

Object? _overTheWire(Map<String, Object?> json) => jsonDecode(jsonEncode(json));

DecodeError _errorOf<T>(Result<T, DecodeError> result) => switch (result) {
  Ok(:final value) => throw StateError('Err-t vartunk: $value'),
  Err(:final error) => error,
};

Map<String, Object?> _enrollmentJson({
  String token = _secretA,
  String deviceName = 'Ákos Pixel 8',
  String publicKey = 'MFkwEw==',
}) => {
  'token': token,
  'publicKey': publicKey,
  'deviceKey': 'MFkwFA==',
  'deviceName': deviceName,
  'model': 'Pixel 8',
  'signature': 'MEQCIA==',
};

void main() {
  group('round trips', () {
    test('keep the account, ticket and issued secret', () {
      final ticket = LoginRequestTicket(
        requestId: _requestId,
        qrText: 'foretack-login:v1:e30',
        expiresAt: DateTime.utc(2026, 10, 7, 8, 30, 15, 250),
      );
      final secret = IssuedSecret(
        value: _secretA,
        expiresAt: DateTime.utc(2026, 10, 7, 8, 45),
      );

      expect(
        _unwrap(decodeAccountInfo(_overTheWire(encodeAccountInfo(_owner)))),
        _owner,
      );
      expect(
        _unwrap(
          decodeLoginRequestTicket(
            _overTheWire(encodeLoginRequestTicket(ticket)),
          ),
        ),
        ticket,
      );
      expect(
        _unwrap(decodeIssuedSecret(_overTheWire(encodeIssuedSecret(secret)))),
        secret,
      );
    });

    test('keep the signed-in status with its account', () {
      const status = LoginRequestStatus(
        state: LoginRequestState.signedIn,
        account: _owner,
      );

      final decoded = _unwrap(
        decodeLoginRequestStatus(
          _overTheWire(encodeLoginRequestStatus(status)),
        ),
      );

      expect(decoded, status);
    });

    test('keep the browser details with unknown fields', () {
      const details = BrowserLoginDetails(ip: '203.0.113.7', browser: 'Chrome');

      final decoded = _unwrap(
        decodeBrowserLoginDetails(
          _overTheWire(encodeBrowserLoginDetails(details)),
        ),
      );

      expect(decoded, details);
    });

    test('keep the enrollment request and its bytes', () {
      final request = EnrollmentRequest(
        token: _secretA,
        publicKey: Uint8List.fromList([0x30, 0x59, 0x30, 0x13]),
        deviceKey: Uint8List.fromList([0x30, 0x59, 0x30, 0x14]),
        deviceName: 'Ákos Pixel 8',
        model: 'Pixel 8',
        signature: Uint8List.fromList([0x30, 0x44, 0x02, 0x20]),
      );

      final json = encodeEnrollmentRequest(request);

      expect(json['publicKey'], 'MFkwEw==');
      expect(_unwrap(decodeEnrollmentRequest(_overTheWire(json))), request);
    });

    test('keep the enrollment result with all codes', () {
      const result = EnrollmentResult(
        account: _owner,
        deviceId: 'd-1',
        recoveryCodes: ['ABCDE-FGHIJ', 'KLMNO-PQRST'],
      );

      final decoded = _unwrap(
        decodeEnrollmentResult(_overTheWire(encodeEnrollmentResult(result))),
      );

      expect(decoded, result);
    });

    test('keep a signed request with and without a challenge', () {
      final withChallenge = SignedDeviceRequest(
        deviceId: 'd-1',
        challenge: _secretA,
        signature: Uint8List.fromList([1, 2, 3]),
      );
      final withoutChallenge = SignedDeviceRequest(
        deviceId: 'd-1',
        signature: Uint8List.fromList([1, 2, 3]),
      );

      for (final request in [withChallenge, withoutChallenge]) {
        final decoded = _unwrap(
          decodeSignedDeviceRequest(
            _overTheWire(encodeSignedDeviceRequest(request)),
          ),
        );
        expect(decoded, request);
      }
    });

    test('keep the device id and the opening challenge', () {
      expect(
        _unwrap(
          decodeDeviceChallengeRequest(
            _overTheWire(encodeDeviceChallengeRequest('d-1')),
          ),
        ),
        'd-1',
      );
      expect(
        _unwrap(
          decodeLoginRequestOpening(
            _overTheWire(encodeLoginRequestOpening(_secretA)),
          ),
        ),
        _secretA,
      );
    });
  });

  group('decoding rejects', () {
    test('an account only on a status that is not signed in', () {
      final error = _errorOf(
        decodeLoginRequestStatus({
          'state': 'pending',
          'account': encodeAccountInfo(_owner),
        }),
      );

      expect(error.path, r'$.account');
    });

    test('a signed-in status without an account', () {
      final error = _errorOf(
        decodeLoginRequestStatus({'state': 'signedIn', 'account': null}),
      );

      expect(error.path, r'$.account');
    });

    test('a token that is not 256 bits of base64url', () {
      final error = _errorOf(
        decodeEnrollmentRequest(_enrollmentJson(token: _requestId)),
      );

      expect(
        error,
        const DecodeError(
          path: r'$.token',
          expected: 'base64url of 32 bytes',
        ),
      );
    });

    test('bytes in a non-canonical or url-safe base64 form', () {
      for (final publicKey in ['MFkwEx==', 'MFkwEw', '-_8=']) {
        final error = _errorOf(
          decodeEnrollmentRequest(_enrollmentJson(publicKey: publicKey)),
        );
        expect(error.path, r'$.publicKey', reason: publicKey);
      }
    });

    test('a device name that would add a line to the signed message', () {
      final error = _errorOf(
        decodeEnrollmentRequest(_enrollmentJson(deviceName: 'Pixel\nadmin')),
      );

      expect(
        error,
        const DecodeError(path: r'$.deviceName', expected: 'display name'),
      );
    });

    test('a short challenge in the opening', () {
      final error = _errorOf(
        decodeLoginRequestOpening({'challenge': _requestId}),
      );

      expect(error.path, r'$.challenge');
    });
  });

  test('trims the device name like the display name rule', () {
    final request = _unwrap(
      decodeEnrollmentRequest(_enrollmentJson(deviceName: '  Pixel  ')),
    );

    expect(request.deviceName, 'Pixel');
  });

  test('keeps the secrets out of the string forms', () {
    final request = _unwrap(decodeEnrollmentRequest(_enrollmentJson()));
    const result = EnrollmentResult(
      account: _owner,
      deviceId: 'd-1',
      recoveryCodes: ['ABCDE-FGHIJ'],
    );

    expect(request.toString(), isNot(contains(_secretA)));
    expect(result.toString(), isNot(contains('ABCDE')));
  });
}
