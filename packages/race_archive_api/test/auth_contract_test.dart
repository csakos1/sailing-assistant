import 'dart:convert';
import 'dart:typed_data';

import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

// A tesztvektorok Pythonnal keszultek (base64.urlsafe_b64encode, kitoltes
// nelkul; json.dumps tomor elvalasztokkal), igy a Dart-kodolo egy
// fuggetlen implementacioval egyezik, nem onmagaval.
const String _origin = 'https://archivum.example.hu';
const String _requestId = 'AAECAwQFBgcICQoLDA0ODw';
const String _challenge = 'ICEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj8';
const String _token = 'QEFCQ0RFRkdISUpLTE1OT1BRUlNUVVZXWFlaW1xdXl8';
const String _loginQr =
    'foretack-login:v1:eyJvcmlnaW4iOiJodHRwczovL2FyY2hpdnVtLmV4YW1wbGUuaHUi'
    'LCJyZXF1ZXN0SWQiOiJBQUVDQXdRRkJnY0lDUW9MREEwT0R3IiwiY2hhbGxlbmdlIjoi'
    'SUNFaUl5UWxKaWNvS1NvckxDMHVMekF4TWpNME5UWTNPRGs2T3p3OVBqOCJ9';
const String _enrollQr =
    'foretack-enroll:v1:eyJvcmlnaW4iOiJodHRwczovL2FyY2hpdnVtLmV4YW1wbGUuaHUi'
    'LCJ0b2tlbiI6IlFFRkNRMFJGUmtkSVNVcExURTFPVDFCUlVsTlVWVlpYV0ZsYVcxeGRYbDgi'
    'fQ';

const Err<QrPayload, QrPayloadError> _notForetack = Err(
  QrPayloadError.notForetack,
);
const Err<QrPayload, QrPayloadError> _unsupported = Err(
  QrPayloadError.unsupportedVersion,
);
const Err<QrPayload, QrPayloadError> _malformed = Err(
  QrPayloadError.malformed,
);

String _loginWith(Map<String, Object?> json) =>
    'foretack-login:v1:${_base64UrlJson(json)}';

String _enrollWith(Map<String, Object?> json) =>
    'foretack-enroll:v1:${_base64UrlJson(json)}';

String _base64UrlJson(Map<String, Object?> json) =>
    encodeBase64UrlUnpadded(utf8.encode(jsonEncode(json)));

void main() {
  group('base64url', () {
    test('encodes the test bytes without padding', () {
      expect(
        encodeBase64UrlUnpadded([for (var i = 0; i < 16; i++) i]),
        _requestId,
      );
    });

    test('decodes an unpadded value back to its bytes', () {
      expect(decodeBase64UrlUnpadded(_requestId), [
        for (var i = 0; i < 16; i++) i,
      ]);
    });

    test('rejects padding, the standard alphabet and a dangling char', () {
      expect(decodeBase64UrlUnpadded('AAECAw=='), isNull);
      expect(decodeBase64UrlUnpadded('a+b/'), isNull);
      expect(decodeBase64UrlUnpadded('AAECA'), isNull);
    });

    test('rejects a non-canonical value with stray trailing bits', () {
      // A 'AB' es az 'AA' ugyanazt az egy bajtot adna; csak az 'AA' a
      // kanonikus.
      expect(decodeBase64UrlUnpadded('AA'), [0]);
      expect(decodeBase64UrlUnpadded('AB'), isNull);
    });
  });

  group('canonicalWebOrigin', () {
    test('accepts an https origin and a local http origin', () {
      expect(canonicalWebOrigin(_origin), _origin);
      expect(canonicalWebOrigin('https://example.hu:8443'), isNotNull);
      expect(canonicalWebOrigin('http://localhost:8080'), isNotNull);
      expect(canonicalWebOrigin('http://127.0.0.1:8080'), isNotNull);
    });

    test('rejects plain http to a public host', () {
      expect(canonicalWebOrigin('http://archivum.example.hu'), isNull);
    });

    test('rejects non-canonical spellings of a valid origin', () {
      expect(canonicalWebOrigin('https://Archivum.example.hu'), isNull);
      expect(canonicalWebOrigin('https://archivum.example.hu:443'), isNull);
      expect(canonicalWebOrigin('https://archivum.example.hu/'), isNull);
    });

    test('rejects paths, queries, fragments and credentials', () {
      expect(canonicalWebOrigin('https://example.hu/belepes'), isNull);
      expect(canonicalWebOrigin('https://example.hu?x=1'), isNull);
      expect(canonicalWebOrigin('https://example.hu#x'), isNull);
      expect(canonicalWebOrigin('https://ákos@example.hu'), isNull);
      expect(canonicalWebOrigin('ftp://example.hu'), isNull);
      expect(canonicalWebOrigin('example.hu'), isNull);
    });
  });

  group('QR payload', () {
    const login = LoginQrPayload(
      origin: _origin,
      requestId: _requestId,
      challenge: _challenge,
    );
    const enroll = EnrollQrPayload(origin: _origin, token: _token);

    test('encodes the login and enrollment codes to the test vectors', () {
      expect(encodeQrPayload(login), _loginQr);
      expect(encodeQrPayload(enroll), _enrollQr);
    });

    test('decodes both test vectors', () {
      expect(
        decodeQrPayload(_loginQr),
        const Ok<QrPayload, QrPayloadError>(login),
      );
      expect(
        decodeQrPayload(_enrollQr),
        const Ok<QrPayload, QrPayloadError>(enroll),
      );
    });

    test('tells a foreign code from a newer Foretack code', () {
      expect(decodeQrPayload('https://example.hu'), _notForetack);
      expect(decodeQrPayload('foretack-login:v2:e30'), _unsupported);
      expect(decodeQrPayload('foretack-invite:v1:e30'), _unsupported);
    });

    final malformed = <String, String>{
      'a body that is not base64url': 'foretack-login:v1:e30=',
      'a body that is not JSON': 'foretack-login:v1:bm90LWpzb24',
      'a token that is not a string': _enrollWith({
        'origin': _origin,
        'token': 1,
      }),
      'a missing challenge': _loginWith({
        'origin': _origin,
        'requestId': _requestId,
      }),
      'a short request id': _loginWith({
        'origin': _origin,
        'requestId': 'AAECAwQFBgcICQoLDA0O',
        'challenge': _challenge,
      }),
      'a short token': _enrollWith({'origin': _origin, 'token': _requestId}),
      'a non-canonical origin': _enrollWith({
        'origin': '$_origin/',
        'token': _token,
      }),
      'a plain http origin': _enrollWith({
        'origin': 'http://archivum.example.hu',
        'token': _token,
      }),
    };
    for (final MapEntry(key: description, value: text) in malformed.entries) {
      test('rejects $description as malformed', () {
        expect(decodeQrPayload(text), _malformed);
      });
    }
  });

  group('signed messages', () {
    final publicKey = Uint8List.fromList([0x30, 0x59, 0x30, 0x13]);
    final deviceKey = Uint8List.fromList([0x30, 0x59, 0x30, 0x14]);

    test('joins the login approval fields with newlines in UTF-8', () {
      final message = loginApprovalMessage(
        origin: _origin,
        requestId: _requestId,
        challenge: _challenge,
        deviceId: 'device-1',
      );

      expect(
        utf8.decode(message),
        'foretack-login-v1\n$_origin\n$_requestId\n$_challenge\ndevice-1',
      );
    });

    test('binds the enrollment to the token and both public keys', () {
      final message = enrollmentMessage(
        origin: _origin,
        token: _token,
        publicKey: publicKey,
        deviceKey: deviceKey,
      );

      expect(
        utf8.decode(message),
        'foretack-enroll-v1\n$_origin\n$_token\nMFkwEw==\nMFkwFA==',
      );
    });

    test('encodes an accented name in the join request as UTF-8', () {
      final message = joinRequestMessage(
        origin: _origin,
        requestId: _requestId,
        challenge: _challenge,
        name: 'Dóri',
        publicKey: publicKey,
        deviceKey: deviceKey,
      );

      expect(
        message,
        utf8.encode(
          'foretack-join-v1\n$_origin\n$_requestId\n$_challenge\nDóri\n'
          'MFkwEw==\nMFkwFA==',
        ),
      );
      expect(message.contains(0xC3), isTrue);
    });

    test('signs the device token request with the challenge', () {
      final message = deviceTokenMessage(
        origin: _origin,
        deviceId: 'device-1',
        challenge: _challenge,
      );

      expect(
        utf8.decode(message),
        'foretack-device-v1\n$_origin\ndevice-1\n$_challenge',
      );
    });

    test('names the action and its target in the action message', () {
      final message = deviceActionMessage(
        origin: _origin,
        deviceId: 'device-1',
        challenge: _challenge,
        action: DeviceAction.revokeDevice,
        target: 'device-2',
      );

      expect(
        utf8.decode(message),
        'foretack-action-v1\n$_origin\ndevice-1\n$_challenge\n'
        'revokeDevice\ndevice-2',
      );
    });

    test('refuses a field that would add a line', () {
      expect(
        () => joinRequestMessage(
          origin: _origin,
          requestId: _requestId,
          challenge: _challenge,
          name: 'Dori\nadmin',
          publicKey: publicKey,
          deviceKey: deviceKey,
        ),
        throwsArgumentError,
      );
      expect(
        () => loginApprovalMessage(
          origin: _origin,
          requestId: _requestId,
          challenge: _challenge,
          deviceId: '',
        ),
        throwsArgumentError,
      );
    });
  });

  group('normalizeDisplayName', () {
    test('trims the name and keeps accents and inner spaces', () {
      expect(normalizeDisplayName('  Kovács Dóri '), 'Kovács Dóri');
    });

    test('rejects an empty or blank name', () {
      expect(normalizeDisplayName(''), isNull);
      expect(normalizeDisplayName('   '), isNull);
    });

    test('counts code points, not UTF-16 units, against the limit', () {
      final fortyEmoji = '\u{1F6A4}' * maximumDisplayNameLength;

      expect(normalizeDisplayName(fortyEmoji), fortyEmoji);
      expect(normalizeDisplayName('$fortyEmoji!'), isNull);
    });

    test('rejects control characters and line separators', () {
      expect(normalizeDisplayName('Dori\nadmin'), isNull);
      expect(normalizeDisplayName('Dori\tB'), isNull);
      expect(normalizeDisplayName('Dori\u0085B'), isNull);
      expect(normalizeDisplayName('Dori\u2028B'), isNull);
    });

    test('rejects invisible and direction-changing characters', () {
      expect(normalizeDisplayName('Do\u200Bri'), isNull);
      expect(normalizeDisplayName('Dori\u202Eakos'), isNull);
      expect(normalizeDisplayName('Dori\u2066B'), isNull);
      expect(normalizeDisplayName('Do\u00ADri'), isNull);
      expect(normalizeDisplayName('Dori\u{E0041}'), isNull);
      expect(normalizeDisplayName('Do\uFEFFri'), isNull);
    });
  });

  group('isAcceptablePassword', () {
    test('accepts 12 to 128 code points', () {
      expect(isAcceptablePassword('a' * minimumPasswordLength), isTrue);
      expect(isAcceptablePassword('ő' * maximumPasswordLength), isTrue);
    });

    test('rejects a shorter or a longer password', () {
      expect(isAcceptablePassword('a' * (minimumPasswordLength - 1)), isFalse);
      expect(isAcceptablePassword('a' * (maximumPasswordLength + 1)), isFalse);
    });
  });
}
