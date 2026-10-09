import 'dart:convert';

import 'package:foretack_web/api/api_failure.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// Egy API-válasz olvasása a [statusCode] és a [body] szövegből (ADR 0048
/// Addendum 4 K2, K19).
///
/// 400 alatt a [decode] olvassa a törzset, fölötte a szerződés
/// hiba-borítéka. A nem JSON törzs és a dekóder elutasítása
/// `UnreadableResponse`. Pure, hogy az `http`-alapú kliens és a böngésző
/// XHR-feltöltője ugyanígy olvasson.
Result<T, ApiFailure> decodeApiResponse<T>(
  int statusCode,
  String body,
  Result<T, DecodeError> Function(Object? json) decode,
) {
  final Object? json;
  try {
    json = jsonDecode(body);
  } on FormatException {
    return Err(UnreadableResponse(statusCode));
  }
  if (statusCode >= 400) {
    return switch (decodeApiError(json)) {
      Ok(:final value) => Err(ServerFailure(value)),
      Err(:final error) => Err(
        UnreadableResponse(statusCode, decodeError: error),
      ),
    };
  }
  return switch (decode(json)) {
    Ok(:final value) => Ok(value),
    Err(:final error) => Err(
      UnreadableResponse(statusCode, decodeError: error),
    ),
  };
}
