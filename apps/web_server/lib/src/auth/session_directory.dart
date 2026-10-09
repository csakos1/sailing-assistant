import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/auth/auth_lifetimes.dart';
import 'package:web_server/src/auth/device_token_service.dart';
import 'package:web_server/src/auth/utc_now.dart';
import 'package:web_server/src/auth_db/login_event_repository.dart';
import 'package:web_server/src/auth_db/session_repository.dart';

/// A webes munkamenetek listája és kiléptetése a telefonról (ADR 0051 D7,
/// Addendum 5 M8).
///
/// Az `owner` mindenkiét látja és zárhatja, a `crew` csak a sajátjait.
class SessionDirectory {
  /// Szolgáltatás a [sessions] és az [events] fölött.
  SessionDirectory({
    required SessionRepository sessions,
    required LoginEventRepository events,
    DateTime Function() now = utcNow,
  }) : _sessions = sessions,
       _events = events,
       _now = now;

  final SessionRepository _sessions;
  final LoginEventRepository _events;
  final DateTime Function() _now;

  /// A [caller] által látható élő munkamenetek, a legutóbb aktív elöl.
  Future<List<WebSession>> list(DeviceCaller caller) {
    final now = _now();
    return _sessions.listLive(
      idleCutoff: now.subtract(sessionIdleTimeout),
      createdCutoff: now.subtract(sessionMaximumLifetime),
      userId: caller.user.role == UserRole.owner ? null : caller.user.id,
    );
  }

  /// A [sessionId] munkamenet kiléptetése; `null`, ha sikerült, vagy már
  /// nincs ilyen (két telefon egyszerre kiléptet).
  ///
  /// A munkamenet gyanús eseménye is nyugtázódik: a szalag „Kiléptetés"
  /// gombja így egy hívás (Addendum 6 N6).
  Future<ApiError?> terminate(DeviceCaller caller, String sessionId) async {
    final session = await _sessions.findById(sessionId);
    if (session == null) return null;
    final isOwn = session.userId == caller.user.id;
    if (!isOwn && caller.user.role != UserRole.owner) {
      return const NotAllowed();
    }
    await _events.acknowledgeForSession(session.id, now: _now());
    await _sessions.deleteById(session.id);
    return null;
  }
}
