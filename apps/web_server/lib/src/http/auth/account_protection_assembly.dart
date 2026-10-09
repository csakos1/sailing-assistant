import 'package:web_server/src/auth/account_security_service.dart';
import 'package:web_server/src/auth/device_action_service.dart';
import 'package:web_server/src/auth/enrollment_service.dart';
import 'package:web_server/src/auth/fallback_backoff.dart';
import 'package:web_server/src/auth/fallback_login_service.dart';
import 'package:web_server/src/auth/login_banner_service.dart';
import 'package:web_server/src/auth/password_hasher.dart';
import 'package:web_server/src/auth/random_bytes.dart';
import 'package:web_server/src/auth/rate_limiter.dart';
import 'package:web_server/src/auth/session_service.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/join_request_repository.dart';
import 'package:web_server/src/auth_db/login_event_repository.dart';
import 'package:web_server/src/auth_db/recovery_code_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';
import 'package:web_server/src/http/auth/account_protection_handlers.dart';
import 'package:web_server/src/http/auth/account_security_handler.dart';
import 'package:web_server/src/http/auth/device_authentication.dart';
import 'package:web_server/src/http/auth/fallback_login_handler.dart';
import 'package:web_server/src/http/auth/login_banner_handler.dart';

/// Az A2b-2 összerakva: a handlerek és a régi események takarítása.
typedef AccountProtection = ({
  AccountProtectionHandlers handlers,
  Future<void> Function() deleteExpired,
});

/// A tartalék belépés, a beállításai és a szalag összekötése (ADR 0051
/// Addendum 6) a már felépített közös részekből; az `AuthApi` hívja, hogy
/// a gyára ne nőjön tovább.
AccountProtection assembleAccountProtection({
  required AuthDatabase database,
  required UserRepository users,
  required SessionService sessions,
  required DeviceActionService actions,
  required DeviceAuthenticator authenticateDevice,
  required JoinRequestRepository joinRequests,
  required LoginEventRepository events,
  required RecoveryCodeDigest digestRecoveryCode,
  required PasswordHasher hasher,
  required RateLimiter fallbackLimiter,
  required RandomBytes randomBytes,
  required DateTime Function() now,
}) {
  final recoveryCodes = RecoveryCodeRepository(database);
  final banner = LoginBannerService(
    events: events,
    joinRequests: joinRequests,
    now: now,
  );
  return (
    handlers: AccountProtectionHandlers(
      fallbackLogin: FallbackLoginHandler(
        service: FallbackLoginService(
          users: users,
          recoveryCodes: recoveryCodes,
          digestRecoveryCode: digestRecoveryCode,
          hasher: hasher,
          sessions: sessions,
          backoff: FallbackBackoff(now: now),
          now: now,
        ),
        sessions: sessions,
        limiter: fallbackLimiter,
      ),
      accountSecurity: AccountSecurityHandler(
        service: AccountSecurityService(
          users: users,
          recoveryCodes: recoveryCodes,
          digestRecoveryCode: digestRecoveryCode,
          hasher: hasher,
          actions: actions,
          runInTransaction: database.transaction,
          randomBytes: randomBytes,
          now: now,
        ),
        authenticateDevice: authenticateDevice,
      ),
      banner: LoginBannerHandler(
        service: banner,
        authenticateDevice: authenticateDevice,
      ),
    ),
    deleteExpired: banner.deleteExpired,
  );
}
