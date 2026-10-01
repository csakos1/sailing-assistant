import 'dart:convert';

import 'package:foretack_web/api/api_failure.dart';
import 'package:http/http.dart' as http;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A web_server REST API-jának kliense (ADR 0048 D6 + Addendum 4 K2).
///
/// Csak fordít: a HTTP-választ a szerződés dekódereivel olvassa, és
/// `Result`-ot ad, kivételt nem. A hívások relatív útvonalai a bázis-címhez
/// képest oldódnak fel; a böngészőben ez az oldal saját címe, így az API
/// mindig ugyanarról az originről jön, mint a web (K5).
class ArchiveApiClient {
  /// Kliens a [_client] HTTP-kliens fölött, a `baseUri` címhez képest.
  ArchiveApiClient(this._client, {required Uri baseUri}) : _baseUri = baseUri;

  final http.Client _client;
  final Uri _baseUri;

  /// A versenynapló sorai: `GET /api/races`.
  Future<Result<List<RaceSummary>, ApiFailure>> fetchRaceSummaries() =>
      _getJson(racesPath, decodeRaceSummaries);

  /// Egy verseny részletezője: `GET /api/races/{id}`.
  ///
  /// Egy nem létező versenyre a szerver `RaceNotFound`-ot ad; ez
  /// `ServerFailure`-ként jön vissza.
  Future<Result<RaceDetail, ApiFailure>> fetchRaceDetail(String raceId) =>
      _getJson(racePath(raceId), decodeRaceDetail);

  Future<Result<T, ApiFailure>> _getJson<T>(
    String path,
    Result<T, DecodeError> Function(Object? json) decode,
  ) async {
    final http.Response response;
    try {
      response = await _client.get(_baseUri.resolve(path));
    } on http.ClientException catch (error) {
      return Err(NetworkFailure(error.message));
    }
    return _decodeResponse(response, decode);
  }

  static Result<T, ApiFailure> _decodeResponse<T>(
    http.Response response,
    Result<T, DecodeError> Function(Object? json) decode,
  ) {
    final status = response.statusCode;
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return Err(UnreadableResponse(status));
    }
    if (status >= 400) {
      return switch (decodeApiError(json)) {
        Ok(:final value) => Err(ServerFailure(value)),
        Err(:final error) => Err(
          UnreadableResponse(status, decodeError: error),
        ),
      };
    }
    return switch (decode(json)) {
      Ok(:final value) => Ok(value),
      Err(:final error) => Err(UnreadableResponse(status, decodeError: error)),
    };
  }
}
