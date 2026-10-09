import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/http/json_response.dart';
import 'package:web_server/src/polar/polar_table_service.dart';

/// A polár-végpontok (ADR 0049 D12, Addendum 4 U7).
///
/// Ha a szervernek nincs érvényes polárja (U1), a [_service] `null`, és
/// minden végpont `PolarUnavailable`-t ad; a többi végpont ettől
/// működik.
class PolarHandler {
  /// Handler a [_service] fölött; `null` a nem elérhető polár.
  const PolarHandler(this._service);

  final PolarTableService? _service;

  /// `GET /api/polar/seasons`: évenként az időre súlyozott sor.
  Future<Response> seasons(Request request) async {
    final service = _service;
    if (service == null) return apiErrorResponse(const PolarUnavailable());
    return jsonResponse(encodeSeasonPolarSummaries(await service.seasons()));
  }

  /// `GET /api/polar/seasons/{year}`: egy szezon táblázata.
  Future<Response> season(Request request, String year) async {
    final service = _service;
    if (service == null) return apiErrorResponse(const PolarUnavailable());
    final parsedYear = int.tryParse(year);
    if (parsedYear == null || parsedYear < 1 || parsedYear > 9999) {
      return apiErrorResponse(
        const MalformedRequest(
          DecodeError(path: 'year', expected: 'year between 1 and 9999'),
        ),
      );
    }
    return jsonResponse(
      encodeSeasonPolarTable(await service.season(parsedYear)),
    );
  }

  /// `GET /api/races/{id}/polar`: egy verseny polár-blokkja, vagy
  /// `RaceNotFound`, ha nincs polár-forrása.
  Future<Response> race(Request request, String raceId) async {
    final service = _service;
    if (service == null) return apiErrorResponse(const PolarUnavailable());
    final detail = await service.race(raceId);
    if (detail == null) return apiErrorResponse(RaceNotFound(raceId));
    return jsonResponse(encodeRacePolarDetail(detail));
  }
}
