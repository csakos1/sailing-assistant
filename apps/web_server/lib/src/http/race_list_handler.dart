import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/http/json_response.dart';
import 'package:web_server/src/race/race_summary_service.dart';

/// `GET /api/races` (ADR 0048 D6).
class RaceListHandler {
  /// Handler a [_raceSummaries] fölött.
  const RaceListHandler(this._raceSummaries);

  final RaceSummaryService _raceSummaries;

  /// A napló sorai.
  Future<Response> call(Request request) async =>
      jsonResponse(encodeRaceSummaries(await _raceSummaries()));
}
