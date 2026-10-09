import 'package:equatable/equatable.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/auth/random_bytes.dart';
import 'package:web_server/src/auth/token_digest.dart';
import 'package:web_server/src/auth_db/enrollment_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';

/// A regisztrációs token élettartama (ADR 0051 D3).
const Duration ownerEnrollmentValidity = Duration(minutes: 15);

/// Egy kiadott regisztráció: a QR szövege és a lejárata.
final class IssuedOwnerEnrollment extends Equatable {
  /// Kiadott regisztráció.
  const IssuedOwnerEnrollment({
    required this.qrText,
    required this.expiresAt,
    required this.ownerName,
    required this.isFirstOwner,
  });

  /// A `foretack-enroll:v1:` QR-tartalom.
  final String qrText;

  /// A lejárat (UTC).
  final DateTime expiresAt;

  /// Az `owner` neve (az új vagy a meglévő).
  final String ownerName;

  /// Az első `owner` jön-e létre, vagy a meglévő kap új eszközt.
  final bool isFirstOwner;

  @override
  List<Object?> get props => [qrText, expiresAt, ownerName, isFirstOwner];

  // A QR-szöveg a tokent hordozza; ne kerüljön naplóba.
  @override
  String toString() =>
      'IssuedOwnerEnrollment($ownerName, $expiresAt, '
      'isFirstOwner: $isFirstOwner)';
}

/// Miért nem adható ki a regisztráció.
sealed class OwnerEnrollmentError extends Equatable {
  const OwnerEnrollmentError();

  @override
  List<Object?> get props => const [];
}

/// Az origó nem kanonikus (`canonicalWebOrigin`).
final class InvalidEnrollmentOrigin extends OwnerEnrollmentError {
  /// Hibás origó.
  const InvalidEnrollmentOrigin();
}

/// A név üres, túl hosszú vagy vezérlőkaraktert tartalmaz.
final class InvalidOwnerName extends OwnerEnrollmentError {
  /// Hibás név.
  const InvalidOwnerName();
}

/// Még nincs `owner`, ezért a név kötelező.
final class OwnerNameRequired extends OwnerEnrollmentError {
  /// Hiányzó név.
  const OwnerNameRequired();
}

/// Már van `owner`; a név nem adható meg (a meglévő kap új eszközt).
final class OwnerAlreadyExists extends OwnerEnrollmentError {
  /// Meglévő `owner` [ownerName] névvel.
  const OwnerAlreadyExists(this.ownerName);

  /// A meglévő `owner` neve.
  final String ownerName;

  @override
  List<Object?> get props => [ownerName];
}

/// Az `owner` telefonjának regisztrációs tokenje (ADR 0051 D3).
///
/// Ha még nincs `owner`, a [name]-mel jön létre a telefon beváltásakor; ha
/// már van, a token az ő új eszközét regisztrálja, és név nem adható meg
/// (Addendum 2 J8). A tokennek csak a hash-e kerül a DB-be.
Future<Result<IssuedOwnerEnrollment, OwnerEnrollmentError>>
issueOwnerEnrollment({
  required UserRepository users,
  required EnrollmentRepository enrollments,
  required String origin,
  required String? name,
  required DateTime now,
  required RandomBytes randomBytes,
}) async {
  final canonicalOrigin = canonicalWebOrigin(origin);
  if (canonicalOrigin == null) return const Err(InvalidEnrollmentOrigin());
  final owner = await users.owner();
  final String ownerName;
  if (owner != null) {
    if (name != null) return Err(OwnerAlreadyExists(owner.name));
    ownerName = owner.name;
  } else {
    if (name == null) return const Err(OwnerNameRequired());
    final normalized = normalizeDisplayName(name);
    if (normalized == null) return const Err(InvalidOwnerName());
    ownerName = normalized;
  }

  final token = encodeBase64UrlUnpadded(randomBytes(secretTokenLength));
  final expiresAt = now.add(ownerEnrollmentValidity);
  await enrollments.insert(
    tokenDigest: digestToken(token),
    origin: canonicalOrigin,
    ownerName: owner == null ? ownerName : null,
    now: now,
    expiresAt: expiresAt,
  );
  return Ok(
    IssuedOwnerEnrollment(
      qrText: encodeQrPayload(
        EnrollQrPayload(origin: canonicalOrigin, token: token),
      ),
      expiresAt: expiresAt,
      ownerName: ownerName,
      isFirstOwner: owner == null,
    ),
  );
}
