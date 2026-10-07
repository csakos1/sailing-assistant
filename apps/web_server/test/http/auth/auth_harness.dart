import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/owner_enrollment.dart';
import 'package:web_server/src/auth/random_bytes.dart';
import 'package:web_server/src/auth/rate_limiter.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/device_repository.dart';
import 'package:web_server/src/auth_db/enrollment_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';
import 'package:web_server/src/http/auth/auth_api.dart';
import 'package:web_server/src/http/auth/auth_cookies.dart';
import 'package:web_server/src/http/auth/auth_rate_limits.dart';

import 'test_phone.dart';

// A hitelesítés HTTP-tesztjeinek közös alapja: memóriabeli auth.sqlite,
// állítható óra, a valódi AuthApi-összekötés, és a telefon meg a böngésző
// lépései. A kérések socket nélkül mennek, a kliens IP-je a shelf
// kapcsolat-adataiból jön, mint élesben.

const String testOrigin = 'https://archivum.example.hu';
const String browserIp = '198.51.100.20';
const String phoneIp = '203.0.113.7';
const String chromeOnLinux =
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36';
const Map<String, String> phoneClient = {
  clientHeaderName: clientHeaderPhoneValue,
};
const Map<String, String> webClient = {
  clientHeaderName: clientHeaderWebValue,
  'user-agent': chromeOnLinux,
};

/// A tesztben a helyreállító kód „hash-e": jól olvasható, és a titok-fájl
/// nélkül is determinisztikus.
Uint8List fakeRecoveryDigest(String code) =>
    Uint8List.fromList(utf8.encode('digest:$code'));

/// Egy belépett böngésző: a session cookie értéke.
typedef BrowserSession = String;

/// A hitelesítés tesztkörnyezete.
final class AuthHarness {
  /// Új környezet; a [rateLimit] a végpontonkénti korlát (alapból laza),
  /// a [joinRateLimit] a csatlakozási kérelemé (alapból a [rateLimit]).
  AuthHarness({int rateLimit = 1000, int? joinRateLimit}) {
    database = AuthDatabase(NativeDatabase.memory());
    RateLimiter limiter([int? limit]) => RateLimiter(
      limit: limit ?? rateLimit,
      window: const Duration(minutes: 1),
      now: () => now,
    );
    api = AuthApi.over(
      database: database,
      origin: testOrigin,
      digestRecoveryCode: fakeRecoveryDigest,
      rateLimits: AuthRateLimits(
        loginRequests: limiter(),
        openings: limiter(),
        approvals: limiter(),
        enrollments: limiter(),
        deviceChallenges: limiter(),
        actionChallenges: limiter(),
        joinRequests: limiter(joinRateLimit),
      ),
      now: () => now,
    );
  }

  /// A memóriabeli `auth.sqlite`.
  late final AuthDatabase database;

  /// A vizsgált összekötés.
  late final AuthApi api;

  /// A szolgáltatások órája; a [advance] lépteti.
  DateTime now = DateTime.utc(2026, 10, 7, 9);

  /// Az óra léptetése.
  void advance(Duration duration) => now = now.add(duration);

  /// Az archívum az őr mögött; a csonk `200`-at ad.
  Handler get archive => api.requireAccess((request) => Response.ok('ok'));

  /// A környezet lezárása.
  Future<void> close() => database.close();

  /// Egy kérés a `/api/auth/*` routerre.
  Future<Response> send(
    String method,
    String path, {
    Object? json,
    String ip = phoneIp,
    Map<String, String> headers = phoneClient,
    Map<String, String> cookies = const {},
    Handler? handler,
  }) async {
    final request = Request(
      method,
      Uri.parse('$testOrigin$path'),
      body: json == null ? null : jsonEncode(json),
      headers: {
        ...headers,
        if (cookies.isNotEmpty)
          'cookie': [
            for (final MapEntry(:key, :value) in cookies.entries) '$key=$value',
          ].join('; '),
      },
      context: {'shelf.io.connection_info': FakeConnectionInfo(ip)},
    );
    return (handler ?? api.router)(request);
  }

  /// Egy regisztrációs token, ahogy a CLI adja.
  Future<String> issueEnrollmentToken({String? ownerName = 'Ákos'}) async {
    final result = await issueOwnerEnrollment(
      users: UserRepository(database),
      enrollments: EnrollmentRepository(database),
      origin: testOrigin,
      name: ownerName,
      now: now,
      randomBytes: secureRandomBytes,
    );
    final qrText = switch (result) {
      Ok(:final value) => value.qrText,
      Err(:final error) => throw StateError('Ok-t vartunk: $error'),
    };
    return switch (decodeQrPayload(qrText)) {
      Ok(value: EnrollQrPayload(:final token)) => token,
      final other => throw StateError('regisztracios QR-t vartunk: $other'),
    };
  }

  /// A regisztráció törzse a [phone] kulcsaival és aláírásával.
  Map<String, Object?> enrollmentBody(
    TestPhone phone,
    String token, {
    TestKey? signer,
  }) {
    final publicKey = phone.signingKey.spki;
    final deviceKey = phone.deviceKey.spki;
    final message = enrollmentMessage(
      origin: testOrigin,
      token: token,
      publicKey: publicKey,
      deviceKey: deviceKey,
    );
    return encodeEnrollmentRequest(
      EnrollmentRequest(
        token: token,
        publicKey: publicKey,
        deviceKey: deviceKey,
        deviceName: 'Ákos Pixel 8',
        model: 'Pixel 8',
        signature: (signer ?? phone.signingKey).sign(message),
      ),
    );
  }

  /// A [phone] regisztrációja egy friss tokennel; a sikeres eredmény.
  Future<EnrollmentResult> enroll(TestPhone phone) async {
    final token = await issueEnrollmentToken(
      ownerName: await UserRepository(database).owner() == null ? 'Ákos' : null,
    );
    final response = await send(
      'POST',
      enrollmentsPath,
      json: enrollmentBody(phone, token),
    );
    return decodeOk(response, decodeEnrollmentResult, status: 201);
  }

  /// Egy eszköz közvetlenül a DB-be, a [phone] kulcsaival.
  Future<void> addDevice(
    TestPhone phone, {
    required String id,
    required String userId,
  }) async {
    await DeviceRepository(database).insert(
      id: id,
      userId: userId,
      publicKey: phone.signingKey.spki,
      deviceKey: phone.deviceKey.spki,
      name: 'Telefon $id',
      model: 'Pixel 7a',
      now: now,
    );
  }

  /// Kihívás és eszköz-token a [phone] eszközkulcsával.
  Future<String> deviceToken(TestPhone phone, String deviceId) async {
    final challenge = await decodeOk(
      await send(
        'POST',
        deviceChallengesPath,
        json: encodeDeviceChallengeRequest(deviceId),
      ),
      decodeIssuedSecret,
      status: 201,
    );
    final token = await decodeOk(
      await send(
        'POST',
        deviceTokensPath,
        json: signedTokenRequest(phone.deviceKey, deviceId, challenge.value),
      ),
      decodeIssuedSecret,
      status: 201,
    );
    return token.value;
  }

  /// Az eszköz-token kérés törzse, a [key] aláírásával.
  Map<String, Object?> signedTokenRequest(
    TestKey key,
    String deviceId,
    String challenge,
  ) => encodeSignedDeviceRequest(
    SignedDeviceRequest(
      deviceId: deviceId,
      challenge: challenge,
      signature: key.sign(
        deviceTokenMessage(
          origin: testOrigin,
          deviceId: deviceId,
          challenge: challenge,
        ),
      ),
    ),
  );

  /// A böngésző új belépési kérése: a QR tartalma és a kötő-cookie.
  Future<({LoginQrPayload qr, String binding})> openLoginRequest() async {
    final response = await send(
      'POST',
      loginRequestsPath,
      ip: browserIp,
      headers: webClient,
    );
    final ticket = await decodeOk(
      response,
      decodeLoginRequestTicket,
      status: 201,
    );
    final qr = switch (decodeQrPayload(ticket.qrText)) {
      Ok(value: final LoginQrPayload payload) => payload,
      final other => throw StateError('belepesi QR-t vartunk: $other'),
    };
    final binding = cookiesOf(response)[loginCookieName];
    if (binding == null) throw StateError('kötő-cookie-t vartunk');
    return (qr: qr, binding: binding);
  }

  /// A böngésző lekérdezése a [binding] kötő-cookie-val.
  Future<Response> poll(String requestId, {String? binding}) => send(
    'POST',
    loginRequestPollPath(requestId),
    ip: browserIp,
    headers: webClient,
    cookies: {if (binding != null) loginCookieName: binding},
  );

  /// A telefon megnyitja a kérést a [deviceToken]-nel.
  Future<Response> open(LoginQrPayload qr, String deviceToken) => send(
    'POST',
    loginRequestOpenPath(qr.requestId),
    json: encodeLoginRequestOpening(qr.challenge),
    headers: {...phoneClient, 'authorization': 'Bearer $deviceToken'},
  );

  /// A telefon jóváhagyja a kérést; alapból az aláíró kulccsal.
  Future<Response> approve(
    LoginQrPayload qr,
    TestPhone phone,
    String deviceId, {
    TestKey? signer,
  }) => send(
    'POST',
    loginRequestApprovalPath(qr.requestId),
    json: encodeSignedDeviceRequest(
      SignedDeviceRequest(
        deviceId: deviceId,
        signature: (signer ?? phone.signingKey).sign(
          loginApprovalMessage(
            origin: testOrigin,
            requestId: qr.requestId,
            challenge: qr.challenge,
            deviceId: deviceId,
          ),
        ),
      ),
    ),
  );

  /// Az eszköz-tokent hordozó telefonos fejlécek.
  Map<String, String> withToken(String deviceToken) => {
    ...phoneClient,
    'authorization': 'Bearer $deviceToken',
  };

  /// Egy ujjlenyomatos művelet aláírva: kihívás a [token] eszköz-tokennel,
  /// és aláírás a [phone] aláíró kulcsával (vagy a [signer]-rel).
  Future<SignedAction> signedAction(
    TestPhone phone,
    String deviceId,
    String token, {
    required DeviceAction kind,
    required String target,
    TestKey? signer,
  }) async {
    final challenge = await decodeOk(
      await send(
        'POST',
        actionChallengesPath,
        headers: withToken(token),
      ),
      decodeIssuedSecret,
      status: 201,
    );
    return SignedAction(
      challenge: challenge.value,
      signature: (signer ?? phone.signingKey).sign(
        deviceActionMessage(
          origin: testOrigin,
          deviceId: deviceId,
          challenge: challenge.value,
          action: kind,
          target: target,
        ),
      ),
    );
  }

  /// A csatlakozási kérelem törzse a [phone] kulcsaival a [qr] kérésre.
  Map<String, Object?> joinBody(
    TestPhone phone,
    LoginQrPayload qr, {
    String name = 'Dóri',
    TestKey? signer,
  }) {
    final publicKey = phone.signingKey.spki;
    final deviceKey = phone.deviceKey.spki;
    final message = joinRequestMessage(
      origin: testOrigin,
      requestId: qr.requestId,
      challenge: qr.challenge,
      name: name,
      publicKey: publicKey,
      deviceKey: deviceKey,
    );
    return encodeJoinRequest(
      JoinRequest(
        requestId: qr.requestId,
        challenge: qr.challenge,
        name: name,
        deviceName: '$name telefonja',
        model: 'SM-S921B',
        publicKey: publicKey,
        deviceKey: deviceKey,
        signature: (signer ?? phone.signingKey).sign(message),
      ),
    );
  }

  /// A [phone] csatlakozási kérelme a [qr] kérésre a [ip] címről.
  Future<Response> submitJoin(
    TestPhone phone,
    LoginQrPayload qr, {
    String name = 'Dóri',
    String ip = phoneIp,
  }) => send(
    'POST',
    joinRequestsPath,
    json: joinBody(phone, qr, name: name),
    ip: ip,
  );

  /// Az `owner` jóváhagyása a [joinRequestId] kérelemre, a [owner]
  /// telefon aláírásával; [memberId] nélkül új tagként.
  Future<Response> approveJoin(
    TestPhone owner,
    String ownerDeviceId,
    String joinRequestId, {
    String? memberId,
    String? signedMemberId,
  }) async {
    final token = await deviceToken(owner, ownerDeviceId);
    final action = await signedAction(
      owner,
      ownerDeviceId,
      token,
      kind: DeviceAction.approveJoin,
      target: joinApprovalTarget(
        joinRequestId: joinRequestId,
        memberId: signedMemberId ?? memberId,
      ),
    );
    return send(
      'POST',
      joinRequestApprovalPath(joinRequestId),
      json: encodeJoinApproval(
        JoinApproval(action: action, memberId: memberId),
      ),
      headers: withToken(token),
    );
  }

  /// A kérelem állapota a [ticket] lekérdező tokenjével.
  Future<JoinRequestStatus> joinStatus(JoinTicket ticket) async => decodeOk(
    await send(
      'POST',
      joinRequestStatusPath(ticket.joinRequestId),
      json: encodeJoinStatusQuery(ticket.statusToken),
    ),
    decodeJoinRequestStatus,
  );

  /// A [joiner] csatlakozik, és az `owner` ([owner], [ownerDeviceId])
  /// jóváhagyja; a tag fiókja és az új eszköze.
  Future<({String userId, String deviceId})> admitMember(
    TestPhone owner,
    String ownerDeviceId,
    TestPhone joiner, {
    String name = 'Dóri',
    String? memberId,
  }) async {
    final (:qr, binding: _) = await openLoginRequest();
    final ticket = await decodeOk(
      await submitJoin(joiner, qr, name: name),
      decodeJoinTicket,
      status: 201,
    );
    final member = await decodeOk(
      await approveJoin(
        owner,
        ownerDeviceId,
        ticket.joinRequestId,
        memberId: memberId,
      ),
      decodeMemberInfo,
    );
    final deviceId = (await joinStatus(ticket)).deviceId;
    if (deviceId == null) throw StateError('jovahagyott kerelmet vartunk');
    return (userId: member.account.userId, deviceId: deviceId);
  }

  /// A teljes QR-belépés a [phone]-nal; a böngésző session cookie-ja.
  Future<BrowserSession> signIn(TestPhone phone, String deviceId) async {
    final (:qr, :binding) = await openLoginRequest();
    final token = await deviceToken(phone, deviceId);
    expect200(await open(qr, token));
    final approval = await approve(qr, phone, deviceId);
    if (approval.statusCode != 204) {
      throw StateError('204-et vartunk: ${approval.statusCode}');
    }
    final response = await poll(qr.requestId, binding: binding);
    final session = cookiesOf(response)[sessionCookieName];
    if (session == null) throw StateError('session cookie-t vartunk');
    return session;
  }
}

/// A kérés kapcsolat-adatai a megadott IP-vel.
final class FakeConnectionInfo implements HttpConnectionInfo {
  /// Kapcsolat a [ip] címről.
  FakeConnectionInfo(String ip) : remoteAddress = InternetAddress(ip);

  @override
  final InternetAddress remoteAddress;

  @override
  int get remotePort => 40000;

  @override
  int get localPort => 8087;
}

/// A válasz `Set-Cookie` fejléceiből a nevek és az értékek.
Map<String, String> cookiesOf(Response response) => {
  for (final header in response.headersAll['set-cookie'] ?? const <String>[])
    header.substring(0, header.indexOf('=')): header.substring(
      header.indexOf('=') + 1,
      header.indexOf(';'),
    ),
};

/// A válasz törzse a [decode] dekóderrel, a [status] ellenőrzésével.
Future<T> decodeOk<T>(
  Response response,
  Result<T, DecodeError> Function(Object? json) decode, {
  int status = 200,
}) async {
  final body = await response.readAsString();
  if (response.statusCode != status) {
    throw StateError('$status-t vartunk: ${response.statusCode} $body');
  }
  return switch (decode(jsonDecode(body))) {
    Ok(:final value) => value,
    Err(:final error) => throw StateError('dekodolhatot vartunk: $error'),
  };
}

/// A hibaválasz `ApiError`-ja.
Future<ApiError> errorOf(Response response) async =>
    switch (decodeApiError(jsonDecode(await response.readAsString()))) {
      Ok(:final value) => value,
      Err(:final error) => throw StateError('hibaboritekot vartunk: $error'),
    };

/// Hibát dob, ha a válasz nem `200`.
void expect200(Response response) {
  if (response.statusCode != 200) {
    throw StateError('200-at vartunk: ${response.statusCode}');
  }
}
