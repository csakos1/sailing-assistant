import 'package:web_server/src/auth/utc_now.dart';
import 'package:web_server/src/auth_db/auth_database.dart';
import 'package:web_server/src/auth_db/login_event_repository.dart';
import 'package:web_server/src/auth_db/session_repository.dart';
import 'package:web_server/src/auth_db/user_repository.dart';

/// Webes munkamenetek lezárása a VPS-ről, az `end_sessions` CLI-vel
/// (ADR 0052 D10).
///
/// A lezárás az app kiléptetésével azonos: a munkamenet gyanús belépési
/// eseménye is nyugtázódik (ADR 0051 Addendum 6 N6). Egy hívás egy
/// tranzakció, így a futó szerver mellett is biztonságos.
class SessionCloser {
  /// Lezáró a [_database] fölött.
  SessionCloser(this._database, {DateTime Function() now = utcNow})
    : _now = now;

  final AuthDatabase _database;
  final DateTime Function() _now;

  /// A [sessionId] munkamenet lezárása; `false`, ha nincs ilyen.
  Future<bool> closeSession(String sessionId) =>
      _database.transaction(() async {
        final sessions = SessionRepository(_database);
        final session = await sessions.findById(sessionId);
        if (session == null) return false;
        await _close(sessions, session.id);
        return true;
      });

  /// A [userId] fiók összes munkamenetének lezárása; a lezártak száma,
  /// vagy `null`, ha nincs ilyen fiók.
  Future<int?> closeUserSessions(String userId) =>
      _database.transaction(() async {
        final user = await UserRepository(_database).get(userId);
        if (user == null) return null;
        final sessions = SessionRepository(_database);
        final ids = await sessions.idsOfUser(user.id);
        for (final id in ids) {
          await _close(sessions, id);
        }
        return ids.length;
      });

  Future<void> _close(SessionRepository sessions, String sessionId) async {
    await LoginEventRepository(
      _database,
    ).acknowledgeForSession(sessionId, now: _now());
    await sessions.deleteById(sessionId);
  }
}
