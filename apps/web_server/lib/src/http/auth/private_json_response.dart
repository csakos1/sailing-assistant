import 'package:shelf/shelf.dart';
import 'package:web_server/src/http/json_response.dart';

/// JSON-válasz, amelyet semmilyen gyorsítótár nem tárolhat (tokenek,
/// kihívások, fiókadat), opcionálisan [cookies] beállításával.
Response privateJsonResponse(
  Object? body, {
  int statusCode = 200,
  List<String> cookies = const [],
}) => jsonResponse(body, statusCode: statusCode).change(
  headers: {
    'cache-control': 'no-store',
    if (cookies.isNotEmpty) 'set-cookie': cookies,
  },
);
