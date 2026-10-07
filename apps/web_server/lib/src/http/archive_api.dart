import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:web_server/src/http/client_header_guard.dart';
import 'package:web_server/src/http/error_boundary.dart';
import 'package:web_server/src/http/export_handler.dart';
import 'package:web_server/src/http/import_handler.dart';
import 'package:web_server/src/http/manual_race_handler.dart';
import 'package:web_server/src/http/polar_handler.dart';
import 'package:web_server/src/http/race_detail_handler.dart';
import 'package:web_server/src/http/race_list_handler.dart';
import 'package:web_server/src/http/race_result_handler.dart';
import 'package:web_server/src/server_log.dart';

/// A webes archívum teljes HTTP-handlere (ADR 0047 Addendum 3 C8, ADR 0048
/// D6 + Addendum 3 I7, ADR 0049 D12, ADR 0050 D8, ADR 0051 Addendum 3 K7).
///
/// A middleware-lánc sorrendje számít: a naplózás kívül van, hogy a
/// kivételfogó által adott 500-as válasz is naplóba kerüljön; a
/// kliensfejléc-őr a routereken kívül, hogy egy ismeretlen útvonalra
/// küldött POST se jusson tovább a fejléc nélkül. Utána az [auth] kapja a
/// `/api/auth/` alatti kéréseket (ezek maguk hitelesítenek), minden más a
/// [requireAccess] őrön (session és szerep) át az archívum routerére megy.
Handler buildArchiveApiHandler({
  required Handler auth,
  required Middleware requireAccess,
  required RaceListHandler raceList,
  required RaceDetailHandler raceDetail,
  required RaceResultHandler raceResult,
  required ManualRaceHandler manualRaces,
  required ImportHandler imports,
  required PolarHandler polar,
  required ExportHandler export,
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
    ..get('$polarSeasonsPath/<year>', polar.season)
    ..get(exportPath, export.call);

  final archive = requireAccess(router.call);

  return const Pipeline()
      .addMiddleware(logRequests(logger: (message, isError) => log(message)))
      .addMiddleware(catchUnexpectedErrors(log))
      .addMiddleware(requireClientHeader())
      .addHandler(
        (request) => request.requestedUri.path.startsWith(authPathPrefix)
            ? auth(request)
            : archive(request),
      );
}
