import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/annotation/annotation_repository.dart';
import 'package:web_server/src/http/bounded_body_reader.dart';
import 'package:web_server/src/http/json_response.dart';

/// `PUT /api/races/{id}/annotation` (ADR 0047 Addendum 1 A5–A6).
///
/// Sorrend: méret → dekódolás → létező verseny → validáció → mentés. A
/// validáció a web űrlapjával közös `ValidateRaceAnnotationInput`, így a
/// szerver ugyanazt a hibalistát adja, amit az űrlap helyben már mutatott.
///
/// A normalizálás után csupa üres bemenet **törli** az annotációt. A
/// szerződés válasza ekkor is `RaceAnnotation`: üres tartalommal és a
/// törlés idejével, hogy a web ugyanazzal a dekóderrel kezelje.
class AnnotationHandler {
  /// Handler az archívum [races] olvasójával és az [annotations] tárral.
  AnnotationHandler({
    required RaceRepository races,
    required AnnotationRepository annotations,
    required int bodyLimitBytes,
    DateTime Function() now = DateTime.now,
  }) : _races = races,
       _annotations = annotations,
       _bodyLimitBytes = bodyLimitBytes,
       _now = now;

  final RaceRepository _races;
  final AnnotationRepository _annotations;
  final int _bodyLimitBytes;
  final DateTime Function() _now;

  static const _validate = ValidateRaceAnnotationInput();

  static const _notJson = DecodeError(
    path: r'$',
    expected: 'UTF-8 JSON document',
  );

  /// A [raceId] verseny annotációjának mentése vagy törlése.
  Future<Response> call(Request request, String raceId) async {
    final List<int> body;
    switch (await readBoundedBody(
      request.read(),
      limitBytes: _bodyLimitBytes,
      declaredLength: request.contentLength,
    )) {
      case Err(:final error):
        return apiErrorResponse(error);
      case Ok(:final value):
        body = value;
    }

    final RaceAnnotationInput input;
    switch (_decodeInput(body)) {
      case Err(:final error):
        return apiErrorResponse(MalformedRequest(error));
      case Ok(:final value):
        input = value;
    }

    if (!await _isArchived(raceId)) {
      return apiErrorResponse(RaceNotFound(raceId));
    }

    final RaceAnnotationInput normalized;
    switch (_validate(input)) {
      case Err(:final error):
        return apiErrorResponse(ValidationFailed(error));
      case Ok(:final value):
        normalized = value;
    }

    final now = _now().toUtc();
    if (normalized.isEmpty) {
      await _annotations.delete(raceId);
      return jsonResponse(
        encodeRaceAnnotation(
          RaceAnnotation(raceId: raceId, content: normalized, updatedAt: now),
        ),
      );
    }
    final saved = await _annotations.upsert(raceId, normalized, updatedAt: now);
    return jsonResponse(encodeRaceAnnotation(saved));
  }

  Future<bool> _isArchived(String raceId) async {
    final race = await _races.getRace(raceId);
    return race != null && race.status == RaceStatus.finished;
  }

  static Result<RaceAnnotationInput, DecodeError> _decodeInput(List<int> body) {
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(body));
    } on FormatException {
      return const Err(_notJson);
    }
    return decodeRaceAnnotationInput(json);
  }
}
