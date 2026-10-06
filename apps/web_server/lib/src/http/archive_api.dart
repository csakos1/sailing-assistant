import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:web_server/src/http/client_header_guard.dart';
import 'package:web_server/src/http/error_boundary.dart';
import 'package:web_server/src/http/import_handler.dart';
import 'package:web_server/src/http/manual_race_handler.dart';
import 'package:web_server/src/http/polar_handler.dart';
import 'package:web_server/src/http/race_detail_handler.dart';
import 'package:web_server/src/http/race_list_handler.dart';
import 'package:web_server/src/http/race_result_handler.dart';
import 'package:web_server/src/server_log.dart';

/// A webes archívum teljes HTTP-handlere (ADR 0047 Addendum 3 C8, ADR 0048
/// D6 + Addendum 3 I7, ADR 0049 D12).
///
/// A middleware-lánc sorrendje számít: a naplózás kívül van, hogy a
/// kivételfogó által adott 500-as válasz is naplóba kerüljön; a
/// kliensfejléc-őr a routeren kívül, hogy egy ismeretlen útvonalra küldött
/// POST se jusson tovább a fejléc nélkül.
Handler buildArchiveApiHandler({
  required RaceListHandler raceList,
  required RaceDetailHandler raceDetail,
  required RaceResultHandler raceResult,
  required ManualRaceHandler manualRaces,
  required ImportHandler imports,
  required PolarHandler polar,
  ServerLog log = ignoreServerLog,
}) {
  final router = Router()
    ..get(racesPath, raceList.call)
    ..get('$racesPath/<raceId>', raceDetail.call)
    ..get('$racesPath/<raceId>/polar', polar.race)
    ..put('$racesPath/<raceId>/result', raceResult.call)
    ..post(manualRacesPath, manualRaces.create)
    ..put('$manualRacesPath/<raceId>', manualRaces.update)
    ..delete('$manualRacesPath/<raceId>', manualRaces.delete)
    ..post(importsPath, imports.call)
    ..get(polarSeasonsPath, polar.seasons)
    ..get('$polarSeasonsPath/<year>', polar.season);

  return const Pipeline()
      .addMiddleware(logRequests(logger: (message, isError) => log(message)))
      .addMiddleware(catchUnexpectedErrors(log))
      .addMiddleware(requireClientHeader())
      .addHandler(router.call);
}
