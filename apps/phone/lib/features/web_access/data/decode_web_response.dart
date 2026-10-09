import 'dart:convert';

import 'package:phone/features/web_access/data/web_api_failure.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// Egy webes válasz olvasása a [statusCode] és a [body] bájtjaiból.
///
/// 400 alatt a [decode] olvassa a törzset, fölötte a szerződés
/// hiba-borítéka (ADR 0047 Addendum 1). A nem UTF-8, nem JSON törzs és a
/// dekóder elutasítása `WebUnreadableResponse`. Pure, hogy tesztelhető
/// legyen hálózat nélkül.
Result<T, WebApiFailure> decodeWebResponse<T>(
  int statusCode,
  List<int> body,
  Result<T, DecodeError> Function(Object? json) decode,
) {
  final Object? json;
  try {
    json = jsonDecode(utf8.decode(body));
  } on FormatException {
    return Err(WebUnreadableResponse(statusCode));
  }
  if (statusCode >= 400) {
    return switch (decodeApiError(json)) {
      Ok(:final value) => Err(WebServerFailure(value)),
      Err() => Err(WebUnreadableResponse(statusCode)),
    };
  }
  return switch (decode(json)) {
    Ok(:final value) => Ok(value),
    Err() => Err(WebUnreadableResponse(statusCode)),
  };
}

/// Egy törzs nélküli siker (pl. `204`) olvasása: 400 alatt `Ok`, fölötte a
/// [decodeWebResponse] szerinti hiba.
Result<void, WebApiFailure> decodeWebNoContent(
  int statusCode,
  List<int> body,
) {
  if (statusCode < 400) return const Ok(null);
  return switch (decodeWebResponse(statusCode, body, _anyJson)) {
    Err(:final error) => Err(error),
    // A `decodeWebResponse` 400 fölött sosem ad Ok-t.
    Ok() => Err(WebUnreadableResponse(statusCode)),
  };
}

Result<Object?, DecodeError> _anyJson(Object? json) => Ok(json);
