import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phone/features/web_access/data/web_account.dart';
import 'package:phone/features/web_access/data/web_account_store.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

// Kozos tesztsegedek a webes hozzaferes tesztjeihez (ADR 0051 Addendum 8
// V13). A szerver egy utvonal szerint valaszolo MockClient, a Keystore egy
// rogzitett bajtokat ado hamis alairo.

const String testOrigin = 'http://localhost:8080';
const String otherOrigin = 'https://archivum.example.hu';
const String testDeviceId = 'device-1';

/// A 32 bajtos titkok base64url alakja (43 jel), a QR-dekoder ezt varja.
final String testChallenge = encodeBase64UrlUnpadded(
  List<int>.filled(secretTokenLength, 7),
);
final String testRequestId = encodeBase64UrlUnpadded(
  List<int>.filled(loginRequestIdLength, 3),
);
final String testToken = encodeBase64UrlUnpadded(
  List<int>.filled(secretTokenLength, 9),
);
final String testDeviceToken = encodeBase64UrlUnpadded(
  List<int>.filled(secretTokenLength, 5),
);

WebAccount testAccount({
  String origin = testOrigin,
  UserRole role = UserRole.owner,
}) => WebAccount(
  origin: origin,
  account: AccountInfo(userId: 'user-1', name: 'Ákos', role: role),
  deviceId: testDeviceId,
);

LoginQrPayload loginPayload({String origin = testOrigin}) => LoginQrPayload(
  origin: origin,
  requestId: testRequestId,
  challenge: testChallenge,
);

EnrollQrPayload enrollPayload({String origin = testOrigin}) =>
    EnrollQrPayload(origin: origin, token: testToken);

const BrowserLoginDetails sampleDetails = BrowserLoginDetails(
  browser: 'Chrome',
  os: 'Linux',
  ip: '203.0.113.7',
  country: 'HU',
  city: 'Budapest',
);

/// Egy JSON-valasz a [status] statusszal.
http.Response jsonResponse(Object? body, {int status = 200}) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

/// A szerzodes hiba-boritekja.
http.Response errorResponse(ApiError error) =>
    jsonResponse(encodeApiError(error), status: error.httpStatus);

/// Egy kiadott titok (kihivas vagy token) JSON-ja.
Map<String, Object?> issuedJson(String value) => encodeIssuedSecret(
  IssuedSecret(value: value, expiresAt: DateTime.utc(2026, 10, 7, 12)),
);

/// Utvonal szerint valaszolo szerver; a kereseket a [requests] gyujti.
class FakeWebServer {
  final List<http.Request> requests = [];
  final Map<String, http.Response Function(http.Request request)> routes = {};

  MockClient get client => MockClient((request) async {
    requests.add(request);
    final route = routes[request.url.path];
    if (route == null) return http.Response('not found', 404);
    return route(request);
  });

  /// Egy kereses torzse JSON-kent.
  static Map<String, Object?> bodyOf(http.Request request) =>
      jsonDecode(request.body) as Map<String, Object?>;

  /// A [path] utvonalra jott keresek.
  List<http.Request> requestsTo(String path) =>
      requests.where((request) => request.url.path == path).toList();
}

/// Memoriabeli fiok-tar.
class MemoryWebAccountStore implements WebAccountStore {
  MemoryWebAccountStore([this.account]);

  WebAccount? account;
  int deletes = 0;

  @override
  Future<WebAccount?> read() async => account;

  @override
  Future<void> write(WebAccount account) async {
    this.account = account;
  }

  @override
  Future<void> delete() async {
    deletes++;
    account = null;
  }
}

/// Hamis kulcsmuveletek: rogzitett kulcsok es alairasok, a hivasok
/// naplozva.
class FakeKeys {
  final List<String> calls = [];
  final List<BiometricPromptText> prompts = [];
  final List<Uint8List> signedMessages = [];
  KeyOperationFailure? biometricFailure;
  KeyOperationFailure? silentFailure;
  KeyOperationFailure? createFailure;

  static final Uint8List signingKey = Uint8List.fromList([1, 1, 1]);
  static final Uint8List deviceKey = Uint8List.fromList([2, 2, 2]);
  static final Uint8List biometricSignature = Uint8List.fromList([3, 3]);
  static final Uint8List silentSignature = Uint8List.fromList([4, 4]);

  WebKeyOperations get operations => WebKeyOperations(
    createKey: (role) async {
      calls.add('create:${role.name}');
      final failure = createFailure;
      if (failure != null) return Err(failure);
      return Ok(role == WebKeyRole.signing ? signingKey : deviceKey);
    },
    signWithBiometrics: (message, prompt) async {
      calls.add('sign:biometric');
      prompts.add(prompt);
      signedMessages.add(message);
      final failure = biometricFailure;
      if (failure != null) return Err(failure);
      return Ok(biometricSignature);
    },
    signSilently: (message) async {
      calls.add('sign:silent');
      signedMessages.add(message);
      final failure = silentFailure;
      if (failure != null) return Err(failure);
      return Ok(silentSignature);
    },
    deleteKeys: () async => calls.add('delete'),
  );
}
