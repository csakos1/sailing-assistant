import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/export/history_exporter.dart';
import 'package:web_server/src/http/json_response.dart';

/// `GET /api/export` (ADR 0050 D8 + Addendum 3 G2, G4, G7).
///
/// A tar.gz előbb teljesen elkészül, és csak utána indul a `200`-as
/// válasz, `Content-Length`-gel; egy építés közbeni hiba így a
/// kivételfogón át `500`. Foglalt exportnál `409`.
///
/// A `HEAD` `405`: a shelf_router a `GET` útvonalra a `HEAD`-et is ide
/// irányítja, és a törzset eldobja. Az export így felépülne, de senki nem
/// olvasná ki, és foglalt maradna.
class ExportHandler {
  /// Handler az [_exporter] fölött.
  const ExportHandler(this._exporter);

  final HistoryExporter _exporter;

  /// A teljes export letöltése.
  Future<Response> call(Request request) async {
    if (request.method == 'HEAD') {
      return Response(405, headers: {'allow': 'GET'});
    }
    switch (await _exporter()) {
      case Err(:final error):
        return apiErrorResponse(error);
      case Ok(:final value):
        return Response.ok(
          value.read(),
          headers: {
            'content-type': 'application/gzip',
            'content-length': '${value.length}',
            'content-disposition': 'attachment; filename="${value.fileName}"',
            'cache-control': 'no-store',
          },
        );
    }
  }
}
