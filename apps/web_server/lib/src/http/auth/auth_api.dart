import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/account_name_service.dart';
import 'package:web_server/src/auth/device_action_service.dart';
import 'package:web_server/src/auth/device_token_service.dart';
import 'package:web_server/src/auth/enrollment_service.dart';
import 'package:web_server/src/auth/join_decision_service.dart';
import 'package:web_server/src/auth/join_request_service.dart';
import 'package:web_server/src/auth/login_request_service.dart';
import 'package:web_server/src/auth/member_service.dart';
import 'package:web_server/src/auth/random_bytes.dart';
import 'package:web_server/src/auth/session_directory.dart';
import 'package:web_server/src/auth/session_service.dart';
import 'package:web_server/src/auth/utc_now.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/challenge_repository.dart';
import 'package:web_server/src/auth_db/device_repository.dart';
import 'package:web_server/src/auth_db/device_revocation.dart';
import 'package:web_server/src/auth_db/device_token_repository.dart';
import 'package:web_server/src/auth_db/enrollment_repository.dart';
import 'package:web_server/src/auth_db/join_request_repository.dart';
import 'package:web_server/src/auth_db/login_request_repository.dart';
import 'package:web_server/src/auth_db/recovery_code_repository.dart';
import 'package:web_server/src/auth_db/session_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';
import 'package:web_server/src/http/auth/access_management_handlers.dart';
import 'package:web_server/src/http/auth/account_handler.dart';
import 'package:web_server/src/http/auth/account_name_handler.dart';
import 'package:web_server/src/http/auth/action_challenge_handler.dart';
import 'package:web_server/src/http/auth/archive_access_guard.dart';
import 'package:web_server/src/http/auth/auth_rate_limits.dart';
import 'package:web_server/src/http/auth/auth_router.dart';
import 'package:web_server/src/http/auth/device_authentication.dart';
import 'package:web_server/src/http/auth/device_token_handler.dart';
import 'package:web_server/src/http/auth/enrollment_handler.dart';
import 'package:web_server/src/http/auth/join_decision_handler.dart';
import 'package:web_server/src/http/auth/join_request_handler.dart';
import 'package:web_server/src/http/auth/login_request_handler.dart';
import 'package:web_server/src/http/auth/member_handler.dart';
import 'package:web_server/src/http/auth/session_list_handler.dart';

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
    final sessionRows = SessionRepository(database);
    final sessions = SessionService(
      sessions: sessionRows,
      users: users,
      randomBytes: randomBytes,
      now: now,
    );
    final challenges = ChallengeRepository(database);
    final tokenRows = DeviceTokenRepository(database);
    final deviceTokens = DeviceTokenService(
      origin: origin,
      users: users,
      devices: devices,
      challenges: challenges,
      tokens: tokenRows,
      randomBytes: randomBytes,
      now: now,
    );
    final loginRequestRows = LoginRequestRepository(database);
    final loginRequests = LoginRequestService(
      origin: origin,
      requests: loginRequestRows,
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
    final joinRequestRows = JoinRequestRepository(database);
    final joinRequests = JoinRequestService(
      origin: origin,
      joinRequests: joinRequestRows,
      loginRequests: loginRequestRows,
      users: users,
      devices: devices,
      runInTransaction: database.transaction,
      randomBytes: randomBytes,
      now: now,
    );
    final actions = DeviceActionService(
      origin: origin,
      challenges: challenges,
      randomBytes: randomBytes,
      now: now,
    );
    final authenticateDevice = deviceAuthenticatorOver(deviceTokens);
    final management = AccessManagementHandlers(
      actionChallenges: ActionChallengeHandler(
        service: actions,
        authenticateDevice: authenticateDevice,
        limiter: rateLimits.actionChallenges,
      ),
      joinRequests: JoinRequestHandler(
        service: joinRequests,
        limiter: rateLimits.joinRequests,
      ),
      joinDecisions: JoinDecisionHandler(
        service: JoinDecisionService(
          joinRequests: joinRequestRows,
          loginRequests: loginRequestRows,
          users: users,
          devices: devices,
          actions: actions,
          runInTransaction: database.transaction,
          now: now,
        ),
        authenticateDevice: authenticateDevice,
      ),
      members: MemberHandler(
        service: MemberService(
          users: users,
          devices: devices,
          revokeDevice: deviceRevokerOver(database),
          actions: actions,
          now: now,
        ),
        authenticateDevice: authenticateDevice,
      ),
      sessions: SessionListHandler(
        directory: SessionDirectory(sessions: sessionRows, now: now),
        authenticateDevice: authenticateDevice,
      ),
      accountName: AccountNameHandler(
        service: AccountNameService(users: users),
        authenticateDevice: authenticateDevice,
      ),
    );
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
        management: management,
      ),
      requireAccess: requireArchiveAccess(sessions),
      deleteExpired: () async {
        await loginRequests.deleteExpired();
        await joinRequestRows.deleteExpired(now());
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

  /// A lejárt kérések, kérelmek, kihívások, tokenek és sessionök törlése;
  /// a szerver időnként hívja.
  Future<void> deleteExpired() => _deleteExpired();
}
