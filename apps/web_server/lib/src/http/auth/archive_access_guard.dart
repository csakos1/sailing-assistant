import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/session_service.dart';
import 'package:web_server/src/http/auth/auth_cookies.dart';
import 'package:web_server/src/http/json_response.dart';

// A `crew` csak olvas: ezek a metódusok mellékhatás nélküliek.
const _readMethods = {'GET', 'HEAD'};

/// Az archívum őre: session és szerep (ADR 0051 D2, D9, Addendum 3 K7).
///
/// Session nélkül `401`. A `crew` csak `GET`-et kap, az exportot nem
/// (`403`); az `owner` mindent.
Middleware requireArchiveAccess(SessionService sessions) =>
    (inner) => (request) async {
      final token = readCookie(request, sessionCookieName);
      final user = token == null ? null : await sessions.userOf(token);
      if (user == null) return apiErrorResponse(const NotAuthenticated());
      final isAllowed = switch (user.role) {
        UserRole.owner => true,
        UserRole.crew =>
          _readMethods.contains(request.method) &&
              request.requestedUri.path != exportPath,
      };
      if (!isAllowed) return apiErrorResponse(const NotAllowed());
      return inner(request);
    };
