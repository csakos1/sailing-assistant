import 'dart:convert';

import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/http/bounded_body_reader.dart';

/// A kérés JSON-törzse, legfeljebb [limitBytes] bájtig (ADR 0047
/// Addendum 3 C4).
///
/// A túl nagy törzs `PayloadTooLarge`, a nem UTF-8 vagy nem JSON törzs
/// `MalformedRequest` a gyökér útvonalán. Az alak ellenőrzése a hívó
/// dekóderének dolga.
Future<Result<Object?, ApiError>> readJsonBody(
  Request request, {
  required int limitBytes,
}) async {
  switch (await readBoundedBody(
    request.read(),
    limitBytes: limitBytes,
    declaredLength: request.contentLength,
  )) {
    case Err(:final error):
      return Err(error);
    case Ok(:final value):
      try {
        return Ok(jsonDecode(utf8.decode(value)));
      } on FormatException {
        return const Err(MalformedRequest(_notJson));
      }
  }
}

const _notJson = DecodeError(path: r'$', expected: 'UTF-8 JSON document');
