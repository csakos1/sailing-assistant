import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/device_token_service.dart';
import 'package:web_server/src/auth/enrollment_service.dart';
import 'package:web_server/src/auth/login_request_service.dart';
import 'package:web_server/src/auth/random_bytes.dart';
import 'package:web_server/src/auth/session_service.dart';
import 'package:web_server/src/auth/utc_now.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/challenge_repository.dart';
import 'package:web_server/src/auth_db/device_repository.dart';
import 'package:web_server/src/auth_db/device_token_repository.dart';
import 'package:web_server/src/auth_db/enrollment_repository.dart';
import 'package:web_server/src/auth_db/login_request_repository.dart';
import 'package:web_server/src/auth_db/recovery_code_repository.dart';
import 'package:web_server/src/auth_db/session_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';
import 'package:web_server/src/http/auth/account_handler.dart';
import 'package:web_server/src/http/auth/archive_access_guard.dart';
import 'package:web_server/src/http/auth/auth_rate_limits.dart';
import 'package:web_server/src/http/auth/auth_router.dart';
import 'package:web_server/src/http/auth/device_authentication.dart';
import 'package:web_server/src/http/auth/device_token_handler.dart';
import 'package:web_server/src/http/auth/enrollment_handler.dart';
import 'package:web_server/src/http/auth/login_request_handler.dart';

/// A hitelesítés összerakva az `auth.sqlite` fölött (ADR 0051
/// Addendum 3 K7): a `/api/auth/*` router, az archívum őre és a lejárt
/// sorok takarítása.
///
/// A szerver és a HTTP-tesztek ugyanezt használják, így a tesztek a valódi
/// összekötést próbálják, nem egy másolatát.
final class AuthApi {
  const AuthApi._({
    required this.router,
    required this.requireAccess,
    required Future<void> Function() deleteExpired,
  }) : _deleteExpired = deleteExpired;

  /// A szolgáltatások és a handlerek a [database] fölött, a szerver
  /// [origin]-jére.
  factory AuthApi.over({
    required AuthDatabase database,
    required String origin,
    required RecoveryCodeDigest digestRecoveryCode,
    required AuthRateLimits rateLimits,
    RandomBytes randomBytes = secureRandomBytes,
    DateTime Function() now = utcNow,
  }) {
    final users = UserRepository(database);
    final devices = DeviceRepository(database);
    final sessions = SessionService(
      sessions: SessionRepository(database),
      users: users,
      randomBytes: randomBytes,
      now: now,
    );
    final deviceTokens = DeviceTokenService(
      origin: origin,
      users: users,
      devices: devices,
      challenges: ChallengeRepository(database),
      tokens: DeviceTokenRepository(database),
      randomBytes: randomBytes,
      now: now,
    );
    final loginRequests = LoginRequestService(
      origin: origin,
      requests: LoginRequestRepository(database),
      users: users,
      devices: devices,
      sessions: sessions,
      randomBytes: randomBytes,
      now: now,
    );
    final enrollments = EnrollmentService(
      origin: origin,
      users: users,
      devices: devices,
      enrollments: EnrollmentRepository(database),
      recoveryCodes: RecoveryCodeRepository(database),
      runInTransaction: database.transaction,
      digestRecoveryCode: digestRecoveryCode,
      randomBytes: randomBytes,
      now: now,
    );
    final authenticateDevice = deviceAuthenticatorOver(deviceTokens);
    return AuthApi._(
      router: buildAuthRouter(
        loginRequests: LoginRequestHandler(
          service: loginRequests,
          sessions: sessions,
          authenticateDevice: authenticateDevice,
          createLimiter: rateLimits.loginRequests,
          openLimiter: rateLimits.openings,
          approvalLimiter: rateLimits.approvals,
        ),
        enrollments: EnrollmentHandler(
          service: enrollments,
          limiter: rateLimits.enrollments,
        ),
        deviceTokens: DeviceTokenHandler(
          service: deviceTokens,
          challengeLimiter: rateLimits.deviceChallenges,
        ),
        account: AccountHandler(
          sessions: sessions,
          authenticateDevice: authenticateDevice,
        ),
      ),
      requireAccess: requireArchiveAccess(sessions),
      deleteExpired: () async {
        await loginRequests.deleteExpired();
        await deviceTokens.deleteExpired();
        await sessions.deleteExpired();
      },
    );
  }

  /// A `/api/auth/*` kérések handlere.
  final Handler router;

  /// Az archívum őre (session és szerep).
  final Middleware requireAccess;

  final Future<void> Function() _deleteExpired;

  /// A lejárt kérések, kihívások, tokenek és sessionök törlése; a szerver
  /// időnként hívja.
  Future<void> deleteExpired() => _deleteExpired();
}
