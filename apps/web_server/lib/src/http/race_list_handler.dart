import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/http/json_response.dart';
import 'package:web_server/src/race/race_list_service.dart';

/// `GET /api/races` (ADR 0047 Addendum 1 A5).
class RaceListHandler {
  /// Handler a [_raceList] fölött.
  const RaceListHandler(this._raceList);

  final RaceListService _raceList;

  /// A napló elemei.
  Future<Response> call(Request request) async =>
      jsonResponse(encodeRaceList(await _raceList()));
}
