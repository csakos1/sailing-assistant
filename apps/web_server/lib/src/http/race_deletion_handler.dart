import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/http/json_response.dart';
import 'package:web_server/src/race/telemetry_race_deletion_service.dart';

/// `DELETE /api/races/{id}`: egy telemetriás verseny végleges törlése
/// (ADR 0057 D5).
///
/// Egy kézi verseny azonosítója itt `RaceNotFound`: az a saját végpontján
/// törlődik (ADR 0048 D6). A `crew` ide nem jut el: a hozzáférés-őr csak
/// `GET`-et és `HEAD`-et enged neki.
class RaceDeletionHandler {
  /// Handler a [_service] fölött.
  const RaceDeletionHandler(this._service);

  final TelemetryRaceDeletionService _service;

  /// A [raceId] verseny törlése; `204` üres törzzsel, vagy `RaceNotFound`.
  Future<Response> call(Request request, String raceId) async {
    if (!await _service.delete(raceId)) {
      return apiErrorResponse(RaceNotFound(raceId));
    }
    return Response(204);
  }
}
