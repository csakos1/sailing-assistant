import 'dart:convert';

import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/api/decode_api_response.dart';
import 'package:http/http.dart' as http;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A web hitelesítési hívásai (ADR 0051 Addendum 3 K6, Addendum 7 P2–P5).
///
/// Mint az `ArchiveApiClient`: csak fordít, `Result`-ot ad, kivételt nem.
/// A cookie-kat (a kötő- és a session-cookie-t) a böngésző kezeli: a
/// `fetch` azonos originnél küldi őket, a web nem lát beléjük
/// (`HttpOnly`). A módosító kérések a kliensfejlécet kapják (D9).
class AuthApiClient {
  /// Kliens a [_client] HTTP-kliens fölött, a `baseUri` címhez képest.
  AuthApiClient(this._client, {required Uri baseUri}) : _baseUri = baseUri;

  final http.Client _client;
  final Uri _baseUri;

  /// A belépett fiók: `GET /api/auth/me`.
  ///
  /// A `401` nem hiba, hanem a kijelentkezett állapot: `Ok(null)`.
  Future<Result<AccountInfo?, ApiFailure>> fetchAccount() async =>
      switch (await _send('GET', mePath)) {
        Ok(value: final response) when response.statusCode == 401 => const Ok(
          null,
        ),
        Ok(value: final response) => _decoded(response, decodeAccountInfo),
        Err(:final error) => Err(error),
      };

  /// Kijelentkezés: `POST /api/auth/logout`. A siker `204`, üres törzzsel.
  Future<Result<void, ApiFailure>> signOut() async => switch (await _send(
    'POST',
    logoutPath,
  )) {
    Ok(value: final response) when response.statusCode < 400 => const Ok(null),
    Ok(value: final response) => Err(_failureOf(response)),
    Err(:final error) => Err(error),
  };

  /// Új belépési kérés: `POST /api/auth/login-requests`. A kötő-cookie-t a
  /// böngésző a válaszból teszi el.
  Future<Result<LoginRequestTicket, ApiFailure>> openLoginRequest() async =>
      switch (await _send('POST', loginRequestsPath)) {
        Ok(value: final response) => _decoded(
          response,
          decodeLoginRequestTicket,
        ),
        Err(:final error) => Err(error),
      };

  /// A kérés állapota: `POST /api/auth/login-requests/{id}/poll`. A
  /// `signedIn` válasz a session-cookie-t is beállítja.
  Future<Result<LoginRequestStatus, ApiFailure>> pollLoginRequest(
    String requestId,
  ) async => switch (await _send('POST', loginRequestPollPath(requestId))) {
    Ok(value: final response) => _decoded(response, decodeLoginRequestStatus),
    Err(:final error) => Err(error),
  };

  /// Tartalék belépés jelszóval vagy helyreállító kóddal: `POST
  /// /api/auth/fallback-login` (ADR 0051 Addendum 6 N2).
  Future<Result<AccountInfo, ApiFailure>> signInWithSecret(
    String secret,
  ) async {
    final sent = await _send(
      'POST',
      fallbackLoginPath,
      body: encodeFallbackLogin(FallbackLogin(secret)),
    );
    return switch (sent) {
      Ok(value: final response) => _decoded(response, decodeAccountInfo),
      Err(:final error) => Err(error),
    };
  }

  // A CSRF-fejléc minden módosító kérésen (ADR 0047 D9, ADR 0051 D9).
  static const Map<String, String> _clientHeader = {
    clientHeaderName: clientHeaderWebValue,
  };

  static Result<Object?, DecodeError> _noBody(Object? json) => Ok(json);

  Future<Result<http.Response, ApiFailure>> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final request = http.Request(method, _baseUri.resolve(path));
    if (method != 'GET') request.headers.addAll(_clientHeader);
    if (body != null) {
      request
        ..headers['content-type'] = 'application/json; charset=utf-8'
        ..bodyBytes = utf8.encode(jsonEncode(body));
    }
    try {
      return Ok(await http.Response.fromStream(await _client.send(request)));
    } on http.ClientException catch (error) {
      return Err(NetworkFailure(error.message));
    }
  }

  static Result<T, ApiFailure> _decoded<T>(
    http.Response response,
    Result<T, DecodeError> Function(Object? json) decode,
  ) {
    final String body;
    try {
      body = utf8.decode(response.bodyBytes);
    } on FormatException {
      return Err(UnreadableResponse(response.statusCode));
    }
    return decodeApiResponse(response.statusCode, body, decode);
  }

  // Egy 400 fölötti válasz hibája: a szerződés borítéka, ha olvasható.
  static ApiFailure _failureOf(http.Response response) =>
      switch (_decoded(response, _noBody)) {
        Err(:final error) => error,
        // A `decodeApiResponse` 400 fölött sosem ad Ok-t.
        Ok() => UnreadableResponse(response.statusCode),
      };
}
