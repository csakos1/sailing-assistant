import 'dart:convert';

import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

/// Sikeres JSON-válasz a [body]-val; alapból `200`, létrehozásnál `201`.
Response jsonResponse(Object? body, {int statusCode = 200}) =>
    Response(statusCode, body: jsonEncode(body), headers: _jsonHeaders);

/// Hibaválasz az [error] borítékával és státuszával (Addendum 1 A7).
Response apiErrorResponse(ApiError error) => Response(
  error.httpStatus,
  body: jsonEncode(encodeApiError(error)),
  headers: _jsonHeaders,
);
