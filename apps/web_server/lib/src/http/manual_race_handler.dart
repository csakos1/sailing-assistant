import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/http/json_body.dart';
import 'package:web_server/src/http/json_response.dart';
import 'package:web_server/src/race/manual_race_service.dart';

/// A kézi verseny végpontjai (ADR 0048 D6 + Addendum 3 I7):
/// `POST /api/manual-races`, `PUT` és `DELETE /api/manual-races/{id}`.
///
/// Egy telemetriás verseny azonosítója itt `RaceNotFound` (D6). A
/// validáció a web űrlapjával közös `ValidateManualRaceRequest`.
class ManualRaceHandler {
  /// Handler a [service] fölött; a törzs legfeljebb [bodyLimitBytes].
  const ManualRaceHandler({
    required ManualRaceService service,
    required int bodyLimitBytes,
  }) : _service = service,
       _bodyLimitBytes = bodyLimitBytes;

  final ManualRaceService _service;
  final int _bodyLimitBytes;

  static const _validate = ValidateManualRaceRequest();

  /// Új kézi verseny; `201` és a napló-sora.
  Future<Response> create(Request request) async {
    switch (await _validatedRequest(request)) {
      case Err(:final error):
        return apiErrorResponse(error);
      case Ok(:final value):
        final summary = await _service.create(value);
        return jsonResponse(encodeRaceSummary(summary), statusCode: 201);
    }
  }

  /// Az [id] kézi verseny mentése; `200` és a napló-sora.
  Future<Response> update(Request request, String id) async {
    // A létezés a validáció előtt: egy ismeretlen versenyre a 404 a
    // válasz, nem a törzs hibái (a v1 annotáció sorrendje).
    final ManualRaceRequest decoded;
    switch (await _decodedRequest(request)) {
      case Err(:final error):
        return apiErrorResponse(error);
      case Ok(:final value):
        decoded = value;
    }
    if (!await _service.exists(id)) return apiErrorResponse(RaceNotFound(id));

    switch (_validate(decoded)) {
      case Err(:final error):
        return apiErrorResponse(ValidationFailed(error));
      case Ok(:final value):
        final summary = await _service.update(id, value);
        if (summary == null) return apiErrorResponse(RaceNotFound(id));
        return jsonResponse(encodeRaceSummary(summary));
    }
  }

  /// Az [id] kézi verseny törlése az eredményével; `204`, üres törzzsel.
  Future<Response> delete(Request request, String id) async {
    if (!await _service.delete(id)) return apiErrorResponse(RaceNotFound(id));
    return Response(204);
  }

  Future<Result<ManualRaceRequest, ApiError>> _validatedRequest(
    Request request,
  ) async => switch (await _decodedRequest(request)) {
    Err(:final error) => Err(error),
    Ok(value: final decoded) => switch (_validate(decoded)) {
      Ok(value: final validated) => Ok(validated),
      Err(:final error) => Err(ValidationFailed(error)),
    },
  };

  Future<Result<ManualRaceRequest, ApiError>> _decodedRequest(
    Request request,
  ) async => switch (await readJsonBody(request, limitBytes: _bodyLimitBytes)) {
    Err(:final error) => Err(error),
    Ok(value: final json) => switch (decodeManualRaceRequest(json)) {
      Ok(value: final decoded) => Ok(decoded),
      Err(:final error) => Err(MalformedRequest(error)),
    },
  };
}
