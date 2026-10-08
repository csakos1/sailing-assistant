import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:phone/features/web_access/data/decode_web_response.dart';
import 'package:phone/features/web_access/data/web_api_failure.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A telefon hívásai a webes archívum hitelesítési végpontjaira (ADR 0051
/// Addendum 3 K6, Addendum 8 V6–V9, Addendum 10 Z15).
///
/// Csak fordít: a `race_archive_api` kodekjeivel kódol és dekódol,
/// `Result`-ot ad, kivételt nem. Minden kérés a telefon kliensfejlécét
/// kapja (D9, L4), és [timeout] után hálózati hibának számít: a hajón egy
/// internet nélküli Wi-Fi mellett a kérés különben sokáig lógna.
class WebAccessApiClient {
  /// Kliens a [_client] fölött, az [origin] szerverhez.
  WebAccessApiClient(
    this._client, {
    required String origin,
    this.timeout = defaultTimeout,
  }) : _origin = Uri.parse(origin);

  /// Az alapértelmezett időkorlát egy kérésre (V6).
  static const Duration defaultTimeout = Duration(seconds: 10);

  final http.Client _client;
  final Uri _origin;

  /// Egy kérés időkorlátja a kéréstől a teljes válasz megérkezéséig.
  final Duration timeout;

  /// Az `owner` telefonjának regisztrációja (`POST /api/auth/enrollments`).
  Future<Result<EnrollmentResult, WebApiFailure>> enroll(
    EnrollmentRequest request,
  ) => _post(
    enrollmentsPath,
    encodeEnrollmentRequest(request),
    decodeEnrollmentResult,
  );

  /// Kihívás az eszköz-tokenhez (`POST /api/auth/device-challenges`).
  Future<Result<IssuedSecret, WebApiFailure>> issueDeviceChallenge(
    String deviceId,
  ) => _post(
    deviceChallengesPath,
    encodeDeviceChallengeRequest(deviceId),
    decodeIssuedSecret,
  );

  /// Eszköz-token az eszközkulccsal aláírt kihívásért (`POST
  /// /api/auth/device-tokens`).
  Future<Result<IssuedSecret, WebApiFailure>> issueDeviceToken(
    SignedDeviceRequest request,
  ) => _post(
    deviceTokensPath,
    encodeSignedDeviceRequest(request),
    decodeIssuedSecret,
  );

  /// Egy belépési kérés megnyitása a QR kihívásával (`POST
  /// /api/auth/login-requests/{id}/open`, eszköz-tokennel).
  Future<Result<BrowserLoginDetails, WebApiFailure>> openLoginRequest(
    String requestId, {
    required String challenge,
    required String deviceToken,
  }) => _post(
    loginRequestOpenPath(requestId),
    encodeLoginRequestOpening(challenge),
    decodeBrowserLoginDetails,
    bearerToken: deviceToken,
  );

  /// Egy belépési kérés jóváhagyása az aláíró kulcs aláírásával (`POST
  /// /api/auth/login-requests/{id}/approval`); a siker `204`.
  Future<Result<void, WebApiFailure>> approveLoginRequest(
    String requestId,
    SignedDeviceRequest approval,
  ) async {
    final sent = await _send(
      'POST',
      loginRequestApprovalPath(requestId),
      body: encodeSignedDeviceRequest(approval),
    );
    return switch (sent) {
      Ok(value: final response) => decodeWebNoContent(
        response.statusCode,
        response.bodyBytes,
      ),
      Err(:final error) => Err(error),
    };
  }

  /// Egy fiók nélküli telefon csatlakozási kérelme (`POST
  /// /api/auth/join-requests`, ADR 0051 Addendum 5 M3); a siker `201`.
  Future<Result<JoinTicket, WebApiFailure>> submitJoinRequest(
    JoinRequest request,
  ) => _post(joinRequestsPath, encodeJoinRequest(request), decodeJoinTicket);

  /// Egy csatlakozási kérelem állapota a lekérdező tokennel (`POST
  /// /api/auth/join-requests/{id}/status`, M4).
  Future<Result<JoinRequestStatus, WebApiFailure>> joinRequestStatus(
    String joinRequestId, {
    required String statusToken,
  }) => _post(
    joinRequestStatusPath(joinRequestId),
    encodeJoinStatusQuery(statusToken),
    decodeJoinRequestStatus,
  );

  /// A telefon fiókja a szerver szerint (`GET /api/auth/me`, eszköz-
  /// tokennel; Z4).
  Future<Result<AccountInfo, WebApiFailure>> fetchAccount({
    required String deviceToken,
  }) => _get(mePath, decodeAccountInfo, bearerToken: deviceToken);

  /// A szalag: gyanús belépések és a függő kérelmek száma (`GET
  /// /api/auth/banner`, N6).
  Future<Result<LoginBanner, WebApiFailure>> fetchBanner({
    required String deviceToken,
  }) => _get(bannerPath, decodeLoginBanner, bearerToken: deviceToken);

  /// Egy gyanús belépés nyugtázása (`POST
  /// /api/auth/login-events/{id}/acknowledgement`); a siker `204`.
  Future<Result<void, WebApiFailure>> acknowledgeLoginEvent(
    String eventId, {
    required String deviceToken,
  }) => _noContent(
    'POST',
    loginEventAcknowledgementPath(eventId),
    bearerToken: deviceToken,
  );

  /// A webes munkamenetek: az `owner`-nél mindenkié, a `crew`-nál a
  /// sajátjai (`GET /api/auth/sessions`, M8).
  Future<Result<List<WebSession>, WebApiFailure>> listSessions({
    required String deviceToken,
  }) => _get(sessionsPath, decodeWebSessions, bearerToken: deviceToken);

  /// Egy munkamenet kiléptetése (`DELETE /api/auth/sessions/{id}`); a
  /// siker `204`, egy már lezárt munkamenetre is (M8).
  Future<Result<void, WebApiFailure>> endSession(
    String sessionId, {
    required String deviceToken,
  }) => _noContent('DELETE', sessionPath(sessionId), bearerToken: deviceToken);

  /// Kihívás egy ujjlenyomatos művelethez (`POST
  /// /api/auth/action-challenges`, M2).
  Future<Result<IssuedSecret, WebApiFailure>> issueActionChallenge({
    required String deviceToken,
  }) => _post(
    actionChallengesPath,
    const <String, Object?>{},
    decodeIssuedSecret,
    bearerToken: deviceToken,
  );

  Future<Result<T, WebApiFailure>> _post<T>(
    String path,
    Map<String, Object?> body,
    Result<T, DecodeError> Function(Object? json) decode, {
    String? bearerToken,
  }) => _decoded(
    _send('POST', path, body: body, bearerToken: bearerToken),
    decode,
  );

  Future<Result<T, WebApiFailure>> _get<T>(
    String path,
    Result<T, DecodeError> Function(Object? json) decode, {
    required String bearerToken,
  }) => _decoded(_send('GET', path, bearerToken: bearerToken), decode);

  Future<Result<void, WebApiFailure>> _noContent(
    String method,
    String path, {
    required String bearerToken,
  }) async {
    final sent = await _send(method, path, bearerToken: bearerToken);
    return switch (sent) {
      Ok(value: final response) => decodeWebNoContent(
        response.statusCode,
        response.bodyBytes,
      ),
      Err(:final error) => Err(error),
    };
  }

  Future<Result<T, WebApiFailure>> _decoded<T>(
    Future<Result<http.Response, WebApiFailure>> sending,
    Result<T, DecodeError> Function(Object? json) decode,
  ) async => switch (await sending) {
    Ok(value: final response) => decodeWebResponse(
      response.statusCode,
      response.bodyBytes,
      decode,
    ),
    Err(:final error) => Err(error),
  };

  // Törzs nélkül (GET, DELETE, nyugtázás) nincs `content-type` sem.
  Future<Result<http.Response, WebApiFailure>> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
    String? bearerToken,
  }) async {
    final request = http.Request(method, _origin.resolve(path))
      ..headers[clientHeaderName] = clientHeaderPhoneValue;
    if (body != null) {
      request
        ..headers['content-type'] = 'application/json; charset=utf-8'
        ..bodyBytes = utf8.encode(jsonEncode(body));
    }
    if (bearerToken != null) {
      request.headers['authorization'] = 'Bearer $bearerToken';
    }
    try {
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
      return Ok(response);
    } on http.ClientException catch (error) {
      return Err(WebNetworkFailure(error.message));
    } on TimeoutException {
      return const Err(WebNetworkFailure('timeout'));
    } on IOException catch (error) {
      // A TLS-hiba (`HandshakeException`) nem `ClientException`-ként jön.
      return Err(WebNetworkFailure('$error'));
    }
  }
}
