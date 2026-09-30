import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/http/json_response.dart';
import 'package:web_server/src/race/race_detail_service.dart';

/// `GET /api/races/{id}` (ADR 0047 Addendum 1 A5).
class RaceDetailHandler {
  /// Handler a [_raceDetail] fölött.
  const RaceDetailHandler(this._raceDetail);

  final RaceDetailService _raceDetail;

  /// A [raceId] verseny részletezője, vagy `RaceNotFound`.
  Future<Response> call(Request request, String raceId) async {
    final detail = await _raceDetail(raceId);
    if (detail == null) return apiErrorResponse(RaceNotFound(raceId));
    return jsonResponse(encodeRaceDetail(detail));
  }
}
