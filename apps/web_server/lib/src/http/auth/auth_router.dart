import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:web_server/src/http/auth/account_handler.dart';
import 'package:web_server/src/http/auth/device_token_handler.dart';
import 'package:web_server/src/http/auth/enrollment_handler.dart';
import 'package:web_server/src/http/auth/login_request_handler.dart';

/// A `/api/auth/*` végpontok routere (ADR 0051 Addendum 3 K6).
///
/// Ezek a session-őr előtt futnak; mindegyik maga hitelesít (kötő-cookie,
/// eszköz-token, aláírás vagy regisztrációs token).
Handler buildAuthRouter({
  required LoginRequestHandler loginRequests,
  required EnrollmentHandler enrollments,
  required DeviceTokenHandler deviceTokens,
  required AccountHandler account,
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
    ..post(logoutPath, account.logout);
  return router.call;
}
