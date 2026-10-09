import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/auth/session_aware_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  // A [path] kerese a [status] valasszal; a jelzesek szama.
  Future<int> signalsFor(String path, int status) async {
    var signals = 0;
    final client = SessionAwareClient(
      MockClient((request) async => http.Response('{}', status)),
      onUnauthorized: () => signals++,
    );
    final response = await client.get(Uri.parse('http://localhost$path'));
    // A valaszt valtozatlanul kapja a hivo.
    expect(response.statusCode, status);
    return signals;
  }

  test('signals a 401 from the archive', () async {
    // ACT
    final signals = await signalsFor('/api/races', 401);

    // ASSERT
    expect(signals, 1);
  });

  test('leaves the 401 of the auth endpoints to their callers', () async {
    // ACT
    final fromMe = await signalsFor('/api/auth/me', 401);
    final fromFallback = await signalsFor('/api/auth/fallback-login', 401);

    // ASSERT
    expect(fromMe, 0);
    expect(fromFallback, 0);
  });

  test('ignores every other status', () async {
    // ACT
    final fromOk = await signalsFor('/api/races', 200);
    final fromForbidden = await signalsFor('/api/races', 403);

    // ASSERT
    expect(fromOk, 0);
    expect(fromForbidden, 0);
  });
}
