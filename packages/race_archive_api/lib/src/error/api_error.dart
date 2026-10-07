import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/import/import_rejection.dart';
import 'package:race_archive_api/src/json/decode_error.dart';
import 'package:race_archive_api/src/json/json_reader.dart';
import 'package:race_archive_api/src/validation/input_violation.dart';
import 'package:race_archive_api/src/validation/input_violation_codec.dart';
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

/// A bemenet validációja elbukott (ADR 0048 Addendum 2 H5).
final class ValidationFailed extends ApiError {
  /// Az összes szabálysértés.
  const ValidationFailed(this.violations);

  /// A szabálysértések, mezőnként.
  final List<InputViolation> violations;

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

/// A szervernek nincs érvényes polárja vagy STW-korrekciója, ezért a
/// polár-statisztika nem elérhető (ADR 0049 D5, Addendum 4 U1). A többi
/// végpont ettől működik.
final class PolarUnavailable extends ApiError {
  /// Nem elérhető polár.
  const PolarUnavailable();

  @override
  int get httpStatus => 503;
}

/// Egy export már fut; egyszerre csak egy készülhet (ADR 0050 Addendum 3
/// G4), hogy a lemezen ne legyen két másolat a DB-kből.
final class ExportInProgress extends ApiError {
  /// Foglalt export.
  const ExportInProgress();

  @override
  int get httpStatus => 409;
}

/// A kéréshez belépés kell, és nincs érvényes session (ADR 0051 D9).
final class NotAuthenticated extends ApiError {
  /// Hiányzó vagy lejárt session.
  const NotAuthenticated();

  @override
  int get httpStatus => 401;
}

/// A belépett felhasználó szerepe ezt nem engedi (ADR 0051 D2): például a
/// `crew` módosító végpontot vagy az exportot hívja.
final class NotAllowed extends ApiError {
  /// Tiltott művelet.
  const NotAllowed();

  @override
  int get httpStatus => 403;
}

/// Túl sok próbálkozás; [retryAfterSeconds] múlva lehet újra (ADR 0051
/// D8). A szerver ugyanezt a `Retry-After` fejlécben is küldi.
final class TooManyAttempts extends ApiError {
  /// Korlátozott kérés; újra [retryAfterSeconds] másodperc múlva.
  const TooManyAttempts(this.retryAfterSeconds);

  /// A várakozás egész másodpercben, legalább 1.
  final int retryAfterSeconds;

  @override
  int get httpStatus => 429;

  @override
  List<Object?> get props => [retryAfterSeconds];
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
        for (final violation in violations) encodeInputViolation(violation),
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
    PolarUnavailable() => <String, Object?>{'code': _polarUnavailable},
    ExportInProgress() => <String, Object?>{'code': _exportInProgress},
    NotAuthenticated() => <String, Object?>{'code': _notAuthenticated},
    NotAllowed() => <String, Object?>{'code': _notAllowed},
    TooManyAttempts(:final retryAfterSeconds) => <String, Object?>{
      'code': _tooManyAttempts,
      'retryAfterSeconds': retryAfterSeconds,
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
      reader.list('violations', readInputViolation),
    ),
    _raceNotFound => RaceNotFound(reader.string('raceId')),
    _importRejected => ImportRejected(
      readImportRejection(reader.object('rejection')),
    ),
    _missingClientHeader => const MissingClientHeader(),
    _payloadTooLarge => PayloadTooLarge(reader.integerAtLeast('limitBytes', 0)),
    _polarUnavailable => const PolarUnavailable(),
    _exportInProgress => const ExportInProgress(),
    _notAuthenticated => const NotAuthenticated(),
    _notAllowed => const NotAllowed(),
    _tooManyAttempts => TooManyAttempts(
      reader.integerAtLeast('retryAfterSeconds', 1),
    ),
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
const String _polarUnavailable = 'polarUnavailable';
const String _exportInProgress = 'exportInProgress';
const String _internalError = 'internalError';
const String _notAuthenticated = 'notAuthenticated';
const String _notAllowed = 'notAllowed';
const String _tooManyAttempts = 'tooManyAttempts';
