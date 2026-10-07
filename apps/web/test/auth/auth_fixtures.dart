import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:race_archive_api/race_archive_api.dart';

// Kozos mintak a bejelentkezes tesztjeihez: a szerver valaszai a
// szerzodes kodoloival.

/// JSON-valasz a [body] torzzsel.
http.Response jsonResponse(Object? body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// A szerzodes hibaboritekja az [error] statuszaval.
http.Response errorResponse(ApiError error) =>
    jsonResponse(encodeApiError(error), status: error.httpStatus);

/// Az [n]. belepesi keres jegye; a QR-szoveg is egyedi.
http.Response ticketResponse(int n) => jsonResponse(
  encodeLoginRequestTicket(
    LoginRequestTicket(
      requestId: requestIdOf(n),
      qrText: 'foretack-login:v1:teszt-$n',
      expiresAt: DateTime.utc(2026, 10, 7, 12),
    ),
  ),
  status: 201,
);

/// Az [n]. keres azonositoja: 16 bajt base64url-ben, ahogy a dekoder varja.
String requestIdOf(int n) =>
    encodeBase64UrlUnpadded(List<int>.filled(16, n % 256));

/// A `poll` valasza a [state] allapottal; `signedIn`-nel az [account]-tal.
http.Response statusResponse(LoginRequestState state, {AccountInfo? account}) =>
    jsonResponse(
      encodeLoginRequestStatus(
        LoginRequestStatus(state: state, account: account),
      ),
    );
