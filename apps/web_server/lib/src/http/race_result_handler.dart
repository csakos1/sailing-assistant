import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/http/json_body.dart';
import 'package:web_server/src/http/json_response.dart';
import 'package:web_server/src/race/race_result_service.dart';

/// `PUT /api/races/{id}/result` (ADR 0048 D3, D6 + Addendum 3 I7).
///
/// Sorrend: méret → dekódolás → létező telemetriás verseny → validáció →
/// mentés. A validáció a web űrlapjával közös `ValidateRaceResultInput`,
/// így a szerver ugyanazt a hibalistát adja, amit az űrlap helyben már
/// mutatott. Egy kézi verseny azonosítója itt `RaceNotFound` (D6).
class RaceResultHandler {
  /// Handler a [service] fölött; a törzs legfeljebb [bodyLimitBytes].
  const RaceResultHandler({
    required RaceResultService service,
    required int bodyLimitBytes,
  }) : _service = service,
       _bodyLimitBytes = bodyLimitBytes;

  final RaceResultService _service;
  final int _bodyLimitBytes;

  static const _validate = ValidateRaceResultInput();

  /// A [raceId] verseny eredményének mentése vagy törlése.
  Future<Response> call(Request request, String raceId) async {
    final Object? json;
    switch (await readJsonBody(request, limitBytes: _bodyLimitBytes)) {
      case Err(:final error):
        return apiErrorResponse(error);
      case Ok(:final value):
        json = value;
    }

    final RaceResultInput input;
    switch (decodeRaceResultInput(json)) {
      case Err(:final error):
        return apiErrorResponse(MalformedRequest(error));
      case Ok(:final value):
        input = value;
    }

    if (!await _service.isTelemetryRace(raceId)) {
      return apiErrorResponse(RaceNotFound(raceId));
    }

    final RaceResultInput normalized;
    switch (_validate(input)) {
      case Err(:final error):
        return apiErrorResponse(ValidationFailed(error));
      case Ok(:final value):
        normalized = value;
    }

    final saved = await _service.save(raceId, normalized);
    if (saved == null) return apiErrorResponse(RaceNotFound(raceId));
    return jsonResponse(encodeRaceResult(saved));
  }
}
