import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/annotation/annotation_codecs.dart';
import 'package:race_archive_api/src/annotation/annotation_violation.dart';
import 'package:race_archive_api/src/import/import_rejection.dart';
import 'package:race_archive_api/src/json/decode_error.dart';
import 'package:race_archive_api/src/json/json_reader.dart';
import 'package:shared/shared.dart';

/// A szerver hibaválaszai (ADR 0047 Addendum 1 A7).
///
/// Sealed: a web kimerítő `switch`-csel fordítja üzenetté, a szerver
/// ebből választja a HTTP státuszt ([httpStatus]), így a kettő egy helyen
/// él. Dróton: `{"error": {"code": ..., ...}}`.
sealed class ApiError extends Equatable {
  const ApiError();

  /// A hibához tartozó HTTP státuszkód.
  int get httpStatus;

  @override
  List<Object?> get props => const [];
}

/// A kérés-törzs nem dekódolható.
final class MalformedRequest extends ApiError {
  /// A törzs a [decodeError] miatt hibás.
  const MalformedRequest(this.decodeError);

  /// Hol és mit vártunk.
  final DecodeError decodeError;

  @override
  int get httpStatus => 400;

  @override
  List<Object?> get props => [decodeError];
}

/// Az eredmény-adatok validációja elbukott.
final class ValidationFailed extends ApiError {
  /// Az összes szabálysértés.
  const ValidationFailed(this.violations);

  /// A szabálysértések, mezőnként.
  final List<AnnotationViolation> violations;

  @override
  int get httpStatus => 422;

  @override
  List<Object?> get props => [violations];
}

/// Nincs ilyen azonosítójú verseny az archívumban.
final class RaceNotFound extends ApiError {
  /// A keresett [raceId].
  const RaceNotFound(this.raceId);

  /// A keresett verseny UUID-je.
  final String raceId;

  @override
  int get httpStatus => 404;

  @override
  List<Object?> get props => [raceId];
}

/// Az importot a szerver elutasította.
final class ImportRejected extends ApiError {
  /// Elutasítás a [rejection] okkal.
  const ImportRejected(this.rejection);

  /// Az elutasítás oka.
  final ImportRejection rejection;

  @override
  int get httpStatus => 422;

  @override
  List<Object?> get props => [rejection];
}

/// Módosító kérésből hiányzik az `X-Foretack-Client` fejléc (D9, CSRF).
final class MissingClientHeader extends ApiError {
  /// Hiányzó kliens-fejléc.
  const MissingClientHeader();

  @override
  int get httpStatus => 403;
}

/// A kérés-törzs meghaladja a [limitBytes] korlátot.
final class PayloadTooLarge extends ApiError {
  /// Túl nagy törzs; a korlát [limitBytes].
  const PayloadTooLarge(this.limitBytes);

  /// A megengedett legnagyobb törzs bájtban.
  final int limitBytes;

  @override
  int get httpStatus => 413;

  @override
  List<Object?> get props => [limitBytes];
}

/// Váratlan szerverhiba. Részletet szándékosan nem hordoz: az a szerver
/// naplójába tartozik.
final class InternalError extends ApiError {
  /// Belső hiba.
  const InternalError();

  @override
  int get httpStatus => 500;
}

/// [ApiError] → a hiba-boríték JSON-ja.
Map<String, Object?> encodeApiError(ApiError error) => <String, Object?>{
  'error': switch (error) {
    MalformedRequest(:final decodeError) => <String, Object?>{
      'code': _malformedRequest,
      'path': decodeError.path,
      'expected': decodeError.expected,
    },
    ValidationFailed(:final violations) => <String, Object?>{
      'code': _validationFailed,
      'violations': [
        for (final violation in violations)
          encodeAnnotationViolation(violation),
      ],
    },
    RaceNotFound(:final raceId) => <String, Object?>{
      'code': _raceNotFound,
      'raceId': raceId,
    },
    ImportRejected(:final rejection) => <String, Object?>{
      'code': _importRejected,
      'rejection': encodeImportRejection(rejection),
    },
    MissingClientHeader() => <String, Object?>{'code': _missingClientHeader},
    PayloadTooLarge(:final limitBytes) => <String, Object?>{
      'code': _payloadTooLarge,
      'limitBytes': limitBytes,
    },
    InternalError() => <String, Object?>{'code': _internalError},
  },
};

/// A hiba-boríték JSON-ja → [ApiError].
Result<ApiError, DecodeError> decodeApiError(Object? json) => runDecode(() {
  final reader = JsonReader.root(json).object('error');
  return switch (reader.string('code')) {
    _malformedRequest => MalformedRequest(
      DecodeError(
        path: reader.string('path'),
        expected: reader.string('expected'),
      ),
    ),
    _validationFailed => ValidationFailed(
      reader.list('violations', readAnnotationViolation),
    ),
    _raceNotFound => RaceNotFound(reader.string('raceId')),
    _importRejected => ImportRejected(
      readImportRejection(reader.object('rejection')),
    ),
    _missingClientHeader => const MissingClientHeader(),
    _payloadTooLarge => PayloadTooLarge(reader.integerAtLeast('limitBytes', 0)),
    _internalError => const InternalError(),
    _ => JsonReader.failAt(reader.childPath('code'), 'api error code'),
  };
});

const String _malformedRequest = 'malformedRequest';
const String _validationFailed = 'validationFailed';
const String _raceNotFound = 'raceNotFound';
const String _importRejected = 'importRejected';
const String _missingClientHeader = 'missingClientHeader';
const String _payloadTooLarge = 'payloadTooLarge';
const String _internalError = 'internalError';
