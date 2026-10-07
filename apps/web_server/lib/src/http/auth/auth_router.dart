import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:web_server/src/http/auth/access_management_handlers.dart';
import 'package:web_server/src/http/auth/account_handler.dart';
import 'package:web_server/src/http/auth/account_protection_handlers.dart';
import 'package:web_server/src/http/auth/device_token_handler.dart';
import 'package:web_server/src/http/auth/enrollment_handler.dart';
import 'package:web_server/src/http/auth/login_request_handler.dart';

/// A `/api/auth/*` végpontok routere (ADR 0051 Addendum 3 K6).
///
/// Ezek a session-őr előtt futnak; mindegyik maga hitelesít (kötő-cookie,
/// eszköz-token, aláírás, regisztrációs vagy lekérdező token). Az A2b-1
/// végpontjai (Addendum 5) a [AccessManagementHandlers]-ből, az A2b-2-éi
/// (Addendum 6) az [AccountProtectionHandlers]-ből jönnek.
Handler buildAuthRouter({
  required LoginRequestHandler loginRequests,
  required EnrollmentHandler enrollments,
  required DeviceTokenHandler deviceTokens,
  required AccountHandler account,
  required AccessManagementHandlers management,
  required AccountProtectionHandlers protection,
}) {
  final router = Router()
    ..post(loginRequestsPath, loginRequests.create)
    ..post('$loginRequestsPath/<requestId>/poll', loginRequests.poll)
    ..post('$loginRequestsPath/<requestId>/open', loginRequests.open)
    ..post('$loginRequestsPath/<requestId>/approval', loginRequests.approve)
    ..post(enrollmentsPath, enrollments.call)
    ..post(deviceChallengesPath, deviceTokens.challenge)
    ..post(deviceTokensPath, deviceTokens.token)
    ..get(mePath, account.me)
    ..post(logoutPath, account.logout)
    ..post(actionChallengesPath, management.actionChallenges.call)
    ..post(joinRequestsPath, management.joinRequests.submit)
    ..post('$joinRequestsPath/<id>/status', management.joinRequests.status)
    ..get(joinRequestsPath, management.joinDecisions.list)
    ..post('$joinRequestsPath/<id>/approval', management.joinDecisions.approve)
    ..post('$joinRequestsPath/<id>/rejection', management.joinDecisions.reject)
    ..get(membersPath, management.members.list)
    ..post('$membersPath/<id>/removal', management.members.removeMember)
    ..post('$devicesPath/<id>/revocation', management.members.revokeDevice)
    ..get(sessionsPath, management.sessions.list)
    ..delete('$sessionsPath/<id>', management.sessions.terminate)
    ..post(accountNamePath, management.accountName.call)
    ..post(fallbackLoginPath, protection.fallbackLogin.call)
    ..get(accountSecurityPath, protection.accountSecurity.security)
    ..post(accountPasswordPath, protection.accountSecurity.setPassword)
    ..post(
      accountRecoveryCodesPath,
      protection.accountSecurity.regenerateRecoveryCodes,
    )
    ..get(bannerPath, protection.banner.banner)
    ..post(
      '$loginEventsPath/<id>/acknowledgement',
      protection.banner.acknowledge,
    );
  return router.call;
}
